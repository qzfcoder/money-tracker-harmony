import { relationalStore } from '@kit.ArkData';
import { AppDatabase } from '../database/AppDatabase';
import { RecordTemplateModel } from '../model/RecordTemplate';
import { RecordType } from '../model/Record';

export class RecordTemplateRepository {
  private store(): relationalStore.RdbStore {
    return AppDatabase.getInstance().getStore();
  }

  async listByType(type: RecordType.EXPENSE | RecordType.INCOME, limit: number = 8): Promise<RecordTemplateModel[]> {
    const result = await this.store().querySql(
      `SELECT t.*, c.name AS category_name, c.color AS category_color, a.name AS account_name
      FROM t_record_template t
      JOIN t_category c ON t.category_id = c.id
      JOIN t_account a ON t.account_id = a.id
      WHERE t.type = ?
      ORDER BY t.use_count DESC, t.update_time DESC, t.id DESC
      LIMIT ?`,
      [type, limit]
    );
    const list: RecordTemplateModel[] = [];
    while (result.goToNextRow()) {
      list.push(this.fromResult(result));
    }
    result.close();
    return list;
  }

  async save(template: RecordTemplateModel): Promise<number> {
    const now = Date.now();
    const existing = await this.findSimilar(template);
    if (existing && existing.id) {
      const predicates = new relationalStore.RdbPredicates('t_record_template');
      predicates.equalTo('id', existing.id);
      const next: RecordTemplateModel = {
        id: existing.id,
        name: template.name,
        type: template.type,
        amount: template.amount,
        categoryId: template.categoryId,
        accountId: template.accountId,
        remark: template.remark,
        useCount: existing.useCount,
        createTime: existing.createTime,
        updateTime: now
      };
      await this.store().update(this.toBucket(next), predicates);
      return existing.id;
    }
    const item: RecordTemplateModel = {
      name: template.name,
      type: template.type,
      amount: template.amount,
      categoryId: template.categoryId,
      accountId: template.accountId,
      remark: template.remark,
      useCount: template.useCount || 0,
      createTime: template.createTime > 0 ? template.createTime : now,
      updateTime: now
    };
    return await this.store().insert('t_record_template', this.toBucket(item)) as number;
  }

  async markUsed(id: number): Promise<void> {
    await this.store().executeSql(
      'UPDATE t_record_template SET use_count = use_count + 1, update_time = ? WHERE id = ?',
      [Date.now(), id]
    );
  }

  async deleteById(id: number): Promise<void> {
    const predicates = new relationalStore.RdbPredicates('t_record_template');
    predicates.equalTo('id', id);
    await this.store().delete(predicates);
  }

  private async findSimilar(template: RecordTemplateModel): Promise<RecordTemplateModel | null> {
    const result = await this.store().querySql(
      `SELECT t.*, c.name AS category_name, c.color AS category_color, a.name AS account_name
      FROM t_record_template t
      JOIN t_category c ON t.category_id = c.id
      JOIN t_account a ON t.account_id = a.id
      WHERE t.type = ? AND t.category_id = ? AND t.account_id = ? AND t.amount = ? AND t.remark = ?
      LIMIT 1`,
      [template.type, template.categoryId, template.accountId, template.amount, template.remark]
    );
    let item: RecordTemplateModel | null = null;
    if (result.goToFirstRow()) {
      item = this.fromResult(result);
    }
    result.close();
    return item;
  }

  private toBucket(template: RecordTemplateModel): relationalStore.ValuesBucket {
    const bucket: relationalStore.ValuesBucket = {};
    bucket['name'] = template.name;
    bucket['type'] = template.type;
    bucket['amount'] = template.amount;
    bucket['category_id'] = template.categoryId;
    bucket['account_id'] = template.accountId;
    bucket['remark'] = template.remark;
    bucket['use_count'] = template.useCount;
    bucket['create_time'] = template.createTime;
    bucket['update_time'] = template.updateTime;
    return bucket;
  }

  private fromResult(result: relationalStore.ResultSet): RecordTemplateModel {
    return {
      id: result.getLong(result.getColumnIndex('id')),
      name: result.getString(result.getColumnIndex('name')),
      type: result.getLong(result.getColumnIndex('type')) as RecordType.EXPENSE | RecordType.INCOME,
      amount: result.getDouble(result.getColumnIndex('amount')),
      categoryId: result.getLong(result.getColumnIndex('category_id')),
      accountId: result.getLong(result.getColumnIndex('account_id')),
      remark: result.getString(result.getColumnIndex('remark')),
      useCount: result.getLong(result.getColumnIndex('use_count')),
      createTime: result.getLong(result.getColumnIndex('create_time')),
      updateTime: result.getLong(result.getColumnIndex('update_time')),
      categoryName: result.getString(result.getColumnIndex('category_name')),
      categoryColor: result.getString(result.getColumnIndex('category_color')),
      accountName: result.getString(result.getColumnIndex('account_name'))
    };
  }
}
