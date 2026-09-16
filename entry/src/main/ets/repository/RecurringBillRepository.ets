import { relationalStore } from '@kit.ArkData';
import { AppDatabase } from '../database/AppDatabase';
import { RecurringBillModel, RecurringFrequency } from '../model/RecurringBill';
import { RecordModel, RecordType } from '../model/Record';
import { DateUtil } from '../utils/DateUtil';
import { RecordRepository } from './RecordRepository';

export class RecurringGenerateResult {
  generatedCount: number = 0;
  skippedCount: number = 0;
}

export class RecurringBillRepository {
  private recordRepository: RecordRepository = new RecordRepository();

  private store(): relationalStore.RdbStore {
    return AppDatabase.getInstance().getStore();
  }

  async list(): Promise<RecurringBillModel[]> {
    const result = await this.store().querySql('SELECT * FROM t_recurring_bill ORDER BY enabled DESC, update_time DESC, id DESC');
    const list: RecurringBillModel[] = [];
    while (result.goToNextRow()) {
      list.push(this.fromResult(result));
    }
    result.close();
    return list;
  }

  async save(item: RecurringBillModel): Promise<number> {
    const now = Date.now();
    const normalized = this.normalize(item, now);
    if (normalized.id && normalized.id > 0) {
      const predicates = new relationalStore.RdbPredicates('t_recurring_bill');
      predicates.equalTo('id', normalized.id);
      await this.store().update(this.toBucket(normalized), predicates);
      return normalized.id;
    }
    return await this.store().insert('t_recurring_bill', this.toBucket(normalized)) as number;
  }

  async deleteById(id: number): Promise<void> {
    const predicates = new relationalStore.RdbPredicates('t_recurring_bill');
    predicates.equalTo('id', id);
    await this.store().delete(predicates);
  }

  async generateDue(referenceTime: number = Date.now()): Promise<RecurringGenerateResult> {
    const result = new RecurringGenerateResult();
    const items = await this.list();
    for (const item of items) {
      await this.tryGenerate(item, referenceTime, result);
    }
    return result;
  }

  async generateOne(id: number, referenceTime: number = Date.now()): Promise<RecurringGenerateResult> {
    const result = new RecurringGenerateResult();
    const items = await this.list();
    const target = items.find((item: RecurringBillModel) => item.id === id);
    if (!target) {
      result.skippedCount = 1;
      return result;
    }
    await this.tryGenerate(target, referenceTime, result);
    return result;
  }

  isDue(item: RecurringBillModel, referenceTime: number = Date.now()): boolean {
    if (!item.enabled) {
      return false;
    }
    const key = this.generationKey(item, referenceTime);
    if (item.lastGeneratedKey === key) {
      return false;
    }
    return this.recordTimeFor(item, referenceTime) <= referenceTime;
  }

  generatedInCurrentPeriod(item: RecurringBillModel, referenceTime: number = Date.now()): boolean {
    return item.lastGeneratedKey === this.generationKey(item, referenceTime);
  }

  nextRecordTime(item: RecurringBillModel, referenceTime: number = Date.now()): number {
    return this.recordTimeFor(item, referenceTime);
  }

  private async tryGenerate(item: RecurringBillModel, referenceTime: number, result: RecurringGenerateResult): Promise<void> {
    if (!item.enabled) {
      result.skippedCount++;
      return;
    }
    const key = this.generationKey(item, referenceTime);
    if (item.lastGeneratedKey === key) {
      result.skippedCount++;
      return;
    }
    const recordTime = this.recordTimeFor(item, referenceTime);
    if (recordTime > referenceTime) {
      result.skippedCount++;
      return;
    }
    const record: RecordModel = {
      type: item.type,
      amount: item.amount,
      categoryId: item.categoryId,
      accountId: item.accountId,
      recordTime,
      ledgerName: '日常账本',
      remark: item.remark || item.name,
      createTime: Date.now(),
      updateTime: Date.now()
    };
    await this.recordRepository.insert(record);
    item.lastGeneratedKey = key;
    item.updateTime = Date.now();
    await this.save(item);
    result.generatedCount++;
  }

  private normalize(item: RecurringBillModel, now: number): RecurringBillModel {
    return {
      id: item.id,
      name: item.name.trim() || '周期账单',
      type: item.type === RecordType.INCOME ? RecordType.INCOME : RecordType.EXPENSE,
      amount: Math.max(0, Math.round(item.amount * 100) / 100),
      categoryId: Math.max(0, item.categoryId || 0),
      accountId: Math.max(0, item.accountId || 0),
      frequency: item.frequency === RecurringFrequency.WEEKLY ? RecurringFrequency.WEEKLY : RecurringFrequency.MONTHLY,
      dayOfMonth: Math.max(1, Math.min(28, Math.round(item.dayOfMonth || 1))),
      dayOfWeek: Math.max(1, Math.min(7, Math.round(item.dayOfWeek || 1))),
      remark: item.remark.trim(),
      enabled: item.enabled,
      lastGeneratedKey: item.lastGeneratedKey || '',
      createTime: item.createTime > 0 ? item.createTime : now,
      updateTime: now
    };
  }

  private generationKey(item: RecurringBillModel, referenceTime: number): string {
    if (item.frequency === RecurringFrequency.WEEKLY) {
      return `W-${DateUtil.dayKey(DateUtil.startOfWeek(referenceTime))}`;
    }
    return `M-${DateUtil.monthKey(referenceTime)}`;
  }

  private recordTimeFor(item: RecurringBillModel, referenceTime: number): number {
    const date = new Date(referenceTime);
    if (item.frequency === RecurringFrequency.WEEKLY) {
      const weekStart = DateUtil.startOfWeek(referenceTime);
      return DateUtil.addDays(weekStart, item.dayOfWeek - 1);
    }
    return new Date(date.getFullYear(), date.getMonth(), item.dayOfMonth, 9, 0, 0).getTime();
  }

  private toBucket(item: RecurringBillModel): relationalStore.ValuesBucket {
    const bucket: relationalStore.ValuesBucket = {};
    bucket['name'] = item.name;
    bucket['type'] = item.type;
    bucket['amount'] = item.amount;
    bucket['category_id'] = item.categoryId;
    bucket['account_id'] = item.accountId;
    bucket['frequency'] = item.frequency;
    bucket['day_of_month'] = item.dayOfMonth;
    bucket['day_of_week'] = item.dayOfWeek;
    bucket['remark'] = item.remark;
    bucket['enabled'] = item.enabled ? 1 : 0;
    bucket['last_generated_key'] = item.lastGeneratedKey;
    bucket['create_time'] = item.createTime;
    bucket['update_time'] = item.updateTime;
    return bucket;
  }

  private fromResult(result: relationalStore.ResultSet): RecurringBillModel {
    return {
      id: result.getLong(result.getColumnIndex('id')),
      name: result.getString(result.getColumnIndex('name')),
      type: result.getLong(result.getColumnIndex('type')) as RecordType.EXPENSE | RecordType.INCOME,
      amount: result.getDouble(result.getColumnIndex('amount')),
      categoryId: result.getLong(result.getColumnIndex('category_id')),
      accountId: result.getLong(result.getColumnIndex('account_id')),
      frequency: result.getLong(result.getColumnIndex('frequency')) as RecurringFrequency,
      dayOfMonth: result.getLong(result.getColumnIndex('day_of_month')),
      dayOfWeek: result.getLong(result.getColumnIndex('day_of_week')),
      remark: result.getString(result.getColumnIndex('remark')),
      enabled: result.getLong(result.getColumnIndex('enabled')) === 1,
      lastGeneratedKey: result.getString(result.getColumnIndex('last_generated_key')),
      createTime: result.getLong(result.getColumnIndex('create_time')),
      updateTime: result.getLong(result.getColumnIndex('update_time'))
    };
  }
}
