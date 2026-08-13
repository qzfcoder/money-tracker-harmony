import { relationalStore } from '@kit.ArkData';
import { AppDatabase } from '../database/AppDatabase';
import { AutoBillModel, AutoBillStatus, AutoCaptureSource, AutoNotificationPayload, AutoRuleModel, AutoRuleType } from '../model/AutoBookkeeping';
import { RecordModel, RecordType } from '../model/Record';
import { RecordRepository } from './RecordRepository';

export class AutoBookkeepingRepository {
  private recordRepository: RecordRepository = new RecordRepository();

  private store(): relationalStore.RdbStore {
    return AppDatabase.getInstance().getStore();
  }

  async listRules(): Promise<AutoRuleModel[]> {
    const result = await this.store().querySql(
      `SELECT r.*, c.name AS category_name, c.color AS category_color
      FROM t_auto_rule r
      LEFT JOIN t_category c ON r.category_id = c.id
      ORDER BY r.rule_type ASC, r.sort_order ASC, r.id ASC`
    );
    const list: AutoRuleModel[] = [];
    while (result.goToNextRow()) {
      list.push(this.fromRuleResult(result));
    }
    result.close();
    return list;
  }

  async saveRule(rule: AutoRuleModel): Promise<number> {
    const now = Date.now();
    const bucket: relationalStore.ValuesBucket = {};
    bucket['rule_type'] = rule.ruleType;
    bucket['keyword'] = rule.keyword.trim();
    bucket['record_type'] = rule.recordType;
    bucket['category_id'] = rule.categoryId;
    bucket['enabled'] = rule.enabled ? 1 : 0;
    bucket['sort_order'] = rule.sortOrder;
    bucket['create_time'] = rule.createTime > 0 ? rule.createTime : now;
    bucket['update_time'] = now;
    if (rule.id && rule.id > 0) {
      await this.store().executeSql(
        `UPDATE t_auto_rule
         SET rule_type = ?, keyword = ?, record_type = ?, category_id = ?, enabled = ?, sort_order = ?, create_time = ?, update_time = ?
         WHERE id = ?`,
        [
          rule.ruleType,
          rule.keyword.trim(),
          rule.recordType,
          rule.categoryId,
          rule.enabled ? 1 : 0,
          rule.sortOrder,
          rule.createTime > 0 ? rule.createTime : now,
          now,
          rule.id
        ]
      );
      return rule.id;
    }
    return await this.store().insert('t_auto_rule', bucket) as number;
  }

  async deleteRuleById(id: number): Promise<void> {
    const predicates = new relationalStore.RdbPredicates('t_auto_rule');
    predicates.equalTo('id', id);
    await this.store().delete(predicates);
  }

  async countPending(): Promise<number> {
    const result = await this.store().querySql('SELECT COUNT(1) AS count FROM t_auto_bill WHERE status = ?', [AutoBillStatus.PENDING]);
    let count = 0;
    if (result.goToFirstRow()) {
      count = result.getLong(result.getColumnIndex('count'));
    }
    result.close();
    return count;
  }

  async listPending(limit: number = 50, offset: number = 0): Promise<AutoBillModel[]> {
    const result = await this.store().querySql(
      `SELECT b.*, c.name AS category_name, c.color AS category_color, a.name AS account_name
      FROM t_auto_bill b
      LEFT JOIN t_category c ON b.category_id = c.id
      LEFT JOIN t_account a ON b.account_id = a.id
      WHERE b.status = ?
      ORDER BY b.record_time DESC, b.id DESC
      LIMIT ? OFFSET ?`,
      [AutoBillStatus.PENDING, limit, offset]
    );
    const list: AutoBillModel[] = [];
    while (result.goToNextRow()) {
      list.push(this.fromBillResult(result));
    }
    result.close();
    return list;
  }

  async clearPendingCache(): Promise<void> {
    const predicates = new relationalStore.RdbPredicates('t_auto_bill');
    predicates.equalTo('status', AutoBillStatus.PENDING);
    await this.store().delete(predicates);
  }

  async discardPending(id: number): Promise<void> {
    const predicates = new relationalStore.RdbPredicates('t_auto_bill');
    predicates.equalTo('id', id);
    await this.store().delete(predicates);
  }

  async savePending(bill: AutoBillModel): Promise<number> {
    const now = Date.now();
    const bucket: relationalStore.ValuesBucket = {};
    bucket['source'] = bill.source;
    bucket['bundle_name'] = bill.bundleName;
    bucket['app_name'] = bill.appName;
    bucket['title'] = bill.title;
    bucket['content'] = bill.content;
    bucket['raw_text'] = bill.rawText;
    bucket['amount'] = bill.amount;
    bucket['type'] = bill.type;
    bucket['category_id'] = bill.categoryId;
    bucket['account_id'] = bill.accountId;
    bucket['record_time'] = bill.recordTime;
    bucket['remark'] = bill.remark;
    bucket['confidence'] = bill.confidence;
    bucket['matched_rule'] = bill.matchedRule;
    bucket['status'] = bill.status;
    bucket['create_time'] = bill.createTime > 0 ? bill.createTime : now;
    bucket['update_time'] = now;
    return await this.store().insert('t_auto_bill', bucket) as number;
  }

  async confirmPending(id: number): Promise<void> {
    const bill = await this.findPendingById(id);
    if (!bill) {
      return;
    }
    const record: RecordModel = {
      type: bill.type,
      amount: bill.amount,
      categoryId: bill.categoryId,
      accountId: bill.accountId,
      recordTime: bill.recordTime,
      remark: bill.remark,
      createTime: bill.createTime,
      updateTime: bill.updateTime
    };
    await this.recordRepository.insert(record);
    await this.discardPending(id);
  }

  async findPendingById(id: number): Promise<AutoBillModel | null> {
    const result = await this.store().querySql(
      `SELECT b.*, c.name AS category_name, c.color AS category_color, a.name AS account_name
      FROM t_auto_bill b
      LEFT JOIN t_category c ON b.category_id = c.id
      LEFT JOIN t_account a ON b.account_id = a.id
      WHERE b.id = ?`,
      [id]
    );
    let item: AutoBillModel | null = null;
    if (result.goToFirstRow()) {
      item = this.fromBillResult(result);
    }
    result.close();
    return item;
  }

  async removeAllBySource(source: string): Promise<void> {
    const predicates = new relationalStore.RdbPredicates('t_auto_bill');
    predicates.equalTo('source', source);
    await this.store().delete(predicates);
  }

  async captureFromNotification(payload: AutoNotificationPayload, parser: (payload: AutoNotificationPayload) => Promise<AutoBillModel | null>): Promise<AutoBillModel | null> {
    const bill = await parser(payload);
    if (!bill) {
      return null;
    }
    const id = await this.savePending(bill);
    bill.id = id;
    return bill;
  }

  private fromRuleResult(result: relationalStore.ResultSet): AutoRuleModel {
    return {
      id: result.getLong(result.getColumnIndex('id')),
      ruleType: result.getLong(result.getColumnIndex('rule_type')) as AutoRuleType,
      keyword: result.getString(result.getColumnIndex('keyword')),
      recordType: result.getLong(result.getColumnIndex('record_type')) as RecordType.EXPENSE | RecordType.INCOME,
      categoryId: result.getLong(result.getColumnIndex('category_id')),
      enabled: result.getLong(result.getColumnIndex('enabled')) === 1,
      sortOrder: result.getLong(result.getColumnIndex('sort_order')),
      createTime: result.getLong(result.getColumnIndex('create_time')),
      updateTime: result.getLong(result.getColumnIndex('update_time')),
      categoryName: this.readNullableString(result, 'category_name'),
      categoryColor: this.readNullableString(result, 'category_color')
    };
  }

  private fromBillResult(result: relationalStore.ResultSet): AutoBillModel {
    return {
      id: result.getLong(result.getColumnIndex('id')),
      source: result.getString(result.getColumnIndex('source')) as AutoCaptureSource,
      bundleName: result.getString(result.getColumnIndex('bundle_name')),
      appName: result.getString(result.getColumnIndex('app_name')),
      title: result.getString(result.getColumnIndex('title')),
      content: result.getString(result.getColumnIndex('content')),
      rawText: result.getString(result.getColumnIndex('raw_text')),
      amount: result.getDouble(result.getColumnIndex('amount')),
      type: result.getLong(result.getColumnIndex('type')) as RecordType.EXPENSE | RecordType.INCOME,
      categoryId: result.getLong(result.getColumnIndex('category_id')),
      accountId: result.getLong(result.getColumnIndex('account_id')),
      recordTime: result.getLong(result.getColumnIndex('record_time')),
      remark: result.getString(result.getColumnIndex('remark')),
      confidence: result.getDouble(result.getColumnIndex('confidence')),
      matchedRule: result.getString(result.getColumnIndex('matched_rule')),
      status: result.getLong(result.getColumnIndex('status')) as AutoBillStatus,
      createTime: result.getLong(result.getColumnIndex('create_time')),
      updateTime: result.getLong(result.getColumnIndex('update_time')),
      categoryName: this.readNullableString(result, 'category_name'),
      categoryColor: this.readNullableString(result, 'category_color'),
      accountName: this.readNullableString(result, 'account_name')
    };
  }

  private readNullableString(result: relationalStore.ResultSet, name: string): string | undefined {
    const index = result.getColumnIndex(name);
    if (index < 0 || result.isColumnNull(index)) {
      return undefined;
    }
    return result.getString(index);
  }
}
