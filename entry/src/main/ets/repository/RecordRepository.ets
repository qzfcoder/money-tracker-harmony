import { relationalStore } from '@kit.ArkData';
import { AppDatabase } from '../database/AppDatabase';
import { RecordListItem, RecordModel, RecordType } from '../model/Record';
import { AccountRepository } from './AccountRepository';

export class MonthSummary {
  income: number = 0;
  expense: number = 0;
  balance: number = 0;

  constructor(income: number, expense: number, balance: number) {
    this.income = income;
    this.expense = expense;
    this.balance = balance;
  }
}

export class CategoryExpenseRank {
  categoryId: number = 0;
  categoryName: string = '';
  categoryColor: string = '#657A55';
  amount: number = 0;
  recordCount: number = 0;
  percent: number = 0;

  constructor(categoryId: number, categoryName: string, categoryColor: string, amount: number, recordCount: number, percent: number) {
    this.categoryId = categoryId;
    this.categoryName = categoryName;
    this.categoryColor = categoryColor;
    this.amount = amount;
    this.recordCount = recordCount;
    this.percent = percent;
  }
}

export class TrendPoint {
  label: string = '';
  income: number = 0;
  expense: number = 0;

  constructor(label: string, income: number, expense: number) {
    this.label = label;
    this.income = income;
    this.expense = expense;
  }
}

export class DailyCashflow {
  dayKey: string = '';
  income: number = 0;
  expense: number = 0;

  constructor(dayKey: string, income: number, expense: number) {
    this.dayKey = dayKey;
    this.income = income;
    this.expense = expense;
  }
}

export interface RecordSearchOptions {
  keyword?: string;
  type?: RecordType.EXPENSE | RecordType.INCOME | RecordType.TRANSFER | 0;
  categoryId?: number;
  accountId?: number;
  startTime?: number;
  endTime?: number;
  ledgerName?: string;
  limit?: number;
  offset?: number;
}

export class RecordRepository {
  private accountRepository: AccountRepository = new AccountRepository();

  private static readonly MILLIS_THRESHOLD: number = 1000000000000;

  private store(): relationalStore.RdbStore {
    return AppDatabase.getInstance().getStore();
  }

  async insert(record: RecordModel): Promise<number> {
    const now = Date.now();
    const data: RecordModel = {
      id: record.id,
      type: record.type,
      amount: record.amount,
      categoryId: record.categoryId,
      accountId: record.accountId,
      transferAccountId: record.transferAccountId,
      recordTime: record.recordTime,
      ledgerName: record.ledgerName.trim() || '日常账本',
      remark: record.remark,
      createTime: record.createTime > 0 ? record.createTime : now,
      updateTime: now
    };
    const id = await this.store().insert('t_record', this.toBucket(data));
    await this.applyAccountChange(data);
    return id;
  }

  async update(record: RecordModel): Promise<void> {
    if (!record.id) {
      throw new Error('记录不存在');
    }
    const previous = await this.findById(record.id);
    if (!previous) {
      throw new Error('记录不存在');
    }

    const updated: RecordModel = {
      id: record.id,
      type: record.type,
      amount: record.amount,
      categoryId: record.categoryId,
      accountId: record.accountId,
      transferAccountId: record.transferAccountId,
      recordTime: record.recordTime,
      ledgerName: record.ledgerName.trim() || previous.ledgerName || '日常账本',
      remark: record.remark,
      createTime: previous.createTime,
      updateTime: Date.now()
    };
    const predicates = new relationalStore.RdbPredicates('t_record');
    predicates.equalTo('id', record.id);
    await this.store().update(this.toBucket(updated), predicates);

    // Rebuild account balances so amount, type, and account edits stay in sync.
    await this.rollbackAccountChange(previous);
    await this.applyAccountChange(updated);
  }

  async deleteById(id: number): Promise<void> {
    const record = await this.findById(id);
    if (!record) {
      return;
    }
    const predicates = new relationalStore.RdbPredicates('t_record');
    predicates.equalTo('id', id);
    await this.store().delete(predicates);
    await this.rollbackAccountChange(record);
  }

  async deleteMany(ids: number[]): Promise<number> {
    let deleted = 0;
    for (const id of ids) {
      if (id > 0) {
        await this.deleteById(id);
        deleted++;
      }
    }
    return deleted;
  }

  async listRecent(limit: number = 20, offset: number = 0): Promise<RecordListItem[]> {
    return this.queryRecords('1 = 1', [], limit, offset);
  }

  async listRecentByLedger(ledgerName: string, limit: number = 20, offset: number = 0): Promise<RecordListItem[]> {
    return this.queryRecords('r.ledger_name = ?', [ledgerName.trim() || '日常账本'], limit, offset);
  }

  async listByRange(startTime: number, endTime: number, limit: number = 200, offset: number = 0): Promise<RecordListItem[]> {
    const startSecond = Math.floor(startTime / 1000);
    const endSecond = Math.floor(endTime / 1000);
    return this.queryRecords(
      '(r.record_time >= ? AND r.record_time < ?) OR (r.record_time >= ? AND r.record_time < ?)',
      [startTime, endTime, startSecond, endSecond],
      limit,
      offset
    );
  }

  async listByRangeAndLedger(startTime: number, endTime: number, ledgerName: string,
    limit: number = 200, offset: number = 0): Promise<RecordListItem[]> {
    const startSecond = Math.floor(startTime / 1000);
    const endSecond = Math.floor(endTime / 1000);
    return this.queryRecords(
      'r.ledger_name = ? AND ((r.record_time >= ? AND r.record_time < ?) OR (r.record_time >= ? AND r.record_time < ?))',
      [ledgerName.trim() || '日常账本', startTime, endTime, startSecond, endSecond],
      limit,
      offset
    );
  }

  async searchRecords(options: RecordSearchOptions): Promise<RecordListItem[]> {
    const clauses: string[] = [];
    const params: (number | string)[] = [];
    const keyword = (options.keyword || '').trim();
    if (keyword.length > 0) {
      clauses.push('(r.remark LIKE ? OR c.name LIKE ? OR a.name LIKE ? OR CAST(r.amount AS TEXT) LIKE ?)');
      const like = `%${keyword}%`;
      params.push(like, like, like, like);
    }
    if (typeof options.type === 'number' && options.type > 0) {
      clauses.push('r.type = ?');
      params.push(options.type);
    }
    if (options.categoryId && options.categoryId > 0) {
      clauses.push('r.category_id = ?');
      params.push(options.categoryId);
    }
    if (options.accountId && options.accountId > 0) {
      clauses.push('(r.account_id = ? OR r.transfer_account_id = ?)');
      params.push(options.accountId, options.accountId);
    }
    const ledgerName = (options.ledgerName || '').trim();
    if (ledgerName.length > 0) {
      clauses.push('r.ledger_name = ?');
      params.push(ledgerName);
    }
    const normalizedRecordTime = "CASE WHEN r.record_time < 1000000000000 THEN r.record_time * 1000 ELSE r.record_time END";
    if (typeof options.startTime === 'number') {
      if (typeof options.endTime === 'number') {
        clauses.push(`(${normalizedRecordTime} >= ? AND ${normalizedRecordTime} < ?)`);
        params.push(options.startTime, options.endTime);
      } else {
        clauses.push(`${normalizedRecordTime} >= ?`);
        params.push(options.startTime);
      }
    }
    if (typeof options.endTime === 'number') {
      if (typeof options.startTime !== 'number') {
        clauses.push(`${normalizedRecordTime} < ?`);
        params.push(options.endTime);
      }
    }
    return this.queryRecords(clauses.length > 0 ? clauses.join(' AND ') : '1 = 1', params, options.limit || 200, options.offset || 0);
  }

  async monthSummary(startTime: number, endTime: number, ledgerName: string = ''): Promise<MonthSummary> {
    const normalizedLedger = ledgerName.trim();
    const ledgerClause = normalizedLedger.length > 0 ? ' AND ledger_name = ?' : '';
    const params: (number | string)[] = [
      RecordType.EXPENSE, RecordType.INCOME, startTime, endTime
    ];
    if (normalizedLedger.length > 0) {
      params.push(normalizedLedger);
    }
    const result = await this.store().querySql(
      `SELECT type, SUM(amount) AS total_amount
      FROM t_record
      WHERE type IN (?, ?) AND (
        CASE WHEN record_time < ${RecordRepository.MILLIS_THRESHOLD}
          THEN record_time * 1000 ELSE record_time END >= ?
        AND CASE WHEN record_time < ${RecordRepository.MILLIS_THRESHOLD}
          THEN record_time * 1000 ELSE record_time END < ?
      )${ledgerClause}
      GROUP BY type`,
      params
    );
    let income = 0;
    let expense = 0;
    while (result.goToNextRow()) {
      const type = result.getLong(result.getColumnIndex('type'));
      const total = result.getDouble(result.getColumnIndex('total_amount'));
      if (type === RecordType.INCOME) {
        income = total;
      }
      if (type === RecordType.EXPENSE) {
        expense = total;
      }
    }
    result.close();
    return new MonthSummary(income, expense, income - expense);
  }

  async recordCount(startTime: number, endTime: number, ledgerName: string = ''): Promise<number> {
    const startSecond = Math.floor(startTime / 1000);
    const endSecond = Math.floor(endTime / 1000);
    const normalizedLedger = ledgerName.trim();
    const ledgerClause = normalizedLedger.length > 0 ? ' AND ledger_name = ?' : '';
    const params: (number | string)[] = [
      RecordType.EXPENSE, RecordType.INCOME, startTime, endTime, startSecond, endSecond
    ];
    if (normalizedLedger.length > 0) {
      params.push(normalizedLedger);
    }
    const result = await this.store().querySql(
      `SELECT COUNT(1) AS record_count
      FROM t_record
      WHERE type IN (?, ?) AND (
        (record_time >= ? AND record_time < ?)
        OR (record_time >= ? AND record_time < ?)
      )${ledgerClause}`,
      params
    );
    let count = 0;
    if (result.goToFirstRow()) {
      count = result.getLong(result.getColumnIndex('record_count'));
    }
    result.close();
    return count;
  }

  async categoryExpenseRanks(startTime: number, endTime: number, ledgerName: string = ''): Promise<CategoryExpenseRank[]> {
    const startSecond = Math.floor(startTime / 1000);
    const endSecond = Math.floor(endTime / 1000);
    const normalizedLedger = ledgerName.trim();
    const ledgerClause = normalizedLedger.length > 0 ? ' AND r.ledger_name = ?' : '';
    const params: (number | string)[] = [RecordType.EXPENSE, startTime, endTime, startSecond, endSecond];
    if (normalizedLedger.length > 0) {
      params.push(normalizedLedger);
    }
    const result = await this.store().querySql(
      `SELECT c.id AS category_id, c.name AS category_name, c.color AS category_color,
        SUM(r.amount) AS total_amount, COUNT(1) AS record_count
      FROM t_record r
      JOIN t_category c ON r.category_id = c.id
      WHERE r.type = ? AND ((r.record_time >= ? AND r.record_time < ?) OR (r.record_time >= ? AND r.record_time < ?))${ledgerClause}
      GROUP BY c.id, c.name, c.color
      ORDER BY total_amount DESC`,
      params
    );
    const list: CategoryExpenseRank[] = [];
    let total = 0;
    while (result.goToNextRow()) {
      const amount = result.getDouble(result.getColumnIndex('total_amount'));
      total += amount;
      list.push(new CategoryExpenseRank(
        result.getLong(result.getColumnIndex('category_id')),
        result.getString(result.getColumnIndex('category_name')),
        result.getString(result.getColumnIndex('category_color')),
        amount,
        result.getLong(result.getColumnIndex('record_count')),
        0
      ));
    }
    result.close();
    return list.map((item: CategoryExpenseRank) => {
      return new CategoryExpenseRank(
        item.categoryId,
        item.categoryName,
        item.categoryColor,
        item.amount,
        item.recordCount,
        total > 0 ? Math.round(item.amount / total * 1000) / 10 : 0
      );
    });
  }

  async expenseTotal(startTime: number, endTime: number): Promise<number> {
    const startSecond = Math.floor(startTime / 1000);
    const endSecond = Math.floor(endTime / 1000);
    const result = await this.store().querySql(
      `SELECT COALESCE(SUM(amount), 0) AS total_amount
      FROM t_record
      WHERE type = ? AND ((record_time >= ? AND record_time < ?) OR (record_time >= ? AND record_time < ?))`,
      [RecordType.EXPENSE, startTime, endTime, startSecond, endSecond]
    );
    let total = 0;
    if (result.goToFirstRow()) {
      total = result.getDouble(result.getColumnIndex('total_amount'));
    }
    result.close();
    return total;
  }

  async expenseByCategory(startTime: number, endTime: number): Promise<Map<number, number>> {
    const startSecond = Math.floor(startTime / 1000);
    const endSecond = Math.floor(endTime / 1000);
    const result = await this.store().querySql(
      `SELECT category_id, COALESCE(SUM(amount), 0) AS total_amount
      FROM t_record
      WHERE type = ? AND ((record_time >= ? AND record_time < ?) OR (record_time >= ? AND record_time < ?))
      GROUP BY category_id`,
      [RecordType.EXPENSE, startTime, endTime, startSecond, endSecond]
    );
    const map = new Map<number, number>();
    while (result.goToNextRow()) {
      map.set(
        result.getLong(result.getColumnIndex('category_id')),
        result.getDouble(result.getColumnIndex('total_amount'))
      );
    }
    result.close();
    return map;
  }

  async expenseTotalByMonth(month: string): Promise<number> {
    const result = await this.store().querySql(
      `SELECT COALESCE(SUM(ABS(amount)), 0) AS total_amount
      FROM t_record
      WHERE type = ? AND (
        strftime('%Y-%m', record_time / 1000, 'unixepoch', 'localtime') = ?
        OR strftime('%Y-%m', record_time, 'unixepoch', 'localtime') = ?
      )`,
      [RecordType.EXPENSE, month, month]
    );
    let total = 0;
    if (result.goToFirstRow()) {
      total = result.getDouble(result.getColumnIndex('total_amount'));
    }
    result.close();
    return total;
  }

  async expenseByCategoryByMonth(month: string): Promise<Map<number, number>> {
    const result = await this.store().querySql(
      `SELECT category_id, COALESCE(SUM(ABS(amount)), 0) AS total_amount
      FROM t_record
      WHERE type = ? AND (
        strftime('%Y-%m', record_time / 1000, 'unixepoch', 'localtime') = ?
        OR strftime('%Y-%m', record_time, 'unixepoch', 'localtime') = ?
      )
      GROUP BY category_id`,
      [RecordType.EXPENSE, month, month]
    );
    const map = new Map<number, number>();
    while (result.goToNextRow()) {
      map.set(
        result.getLong(result.getColumnIndex('category_id')),
        result.getDouble(result.getColumnIndex('total_amount'))
      );
    }
    result.close();
    return map;
  }

  async trendByDay(startTime: number, endTime: number, ledgerName: string = ''): Promise<TrendPoint[]> {
    return this.trendByFormat(startTime, endTime, '%Y-%m-%d', ledgerName);
  }

  async trendByMonth(startTime: number, endTime: number, ledgerName: string = ''): Promise<TrendPoint[]> {
    return this.trendByFormat(startTime, endTime, '%Y-%m', ledgerName);
  }

  async dailyCashflow(startTime: number, endTime: number): Promise<DailyCashflow[]> {
    const startSecond = Math.floor(startTime / 1000);
    const endSecond = Math.floor(endTime / 1000);
    const result = await this.store().querySql(
      `SELECT strftime('%Y-%m-%d', CASE
          WHEN record_time >= ? THEN record_time / 1000
          ELSE record_time
        END, 'unixepoch', 'localtime') AS day_key,
        SUM(CASE WHEN type = ? THEN amount ELSE 0 END) AS income_amount,
        SUM(CASE WHEN type = ? THEN amount ELSE 0 END) AS expense_amount
      FROM t_record
      WHERE type IN (?, ?) AND (
        (record_time >= ? AND record_time < ?)
        OR (record_time >= ? AND record_time < ?)
      )
      GROUP BY day_key
      ORDER BY day_key ASC`,
      [RecordRepository.MILLIS_THRESHOLD, RecordType.INCOME, RecordType.EXPENSE, RecordType.INCOME, RecordType.EXPENSE, startTime, endTime, startSecond, endSecond]
    );
    const list: DailyCashflow[] = [];
    while (result.goToNextRow()) {
      list.push(new DailyCashflow(
        result.getString(result.getColumnIndex('day_key')),
        result.getDouble(result.getColumnIndex('income_amount')),
        result.getDouble(result.getColumnIndex('expense_amount'))
      ));
    }
    result.close();
    return list;
  }

  async findById(id: number): Promise<RecordModel | null> {
    const result = await this.store().querySql('SELECT * FROM t_record WHERE id = ?', [id]);
    let record: RecordModel | null = null;
    if (result.goToFirstRow()) {
      record = this.fromRecordResult(result);
    }
    result.close();
    return record;
  }

  private async queryRecords(whereClause: string, params: (number | string)[], limit: number, offset: number): Promise<RecordListItem[]> {
    const result = await this.store().querySql(
      `SELECT r.*, COALESCE(c.name, '转账') AS category_name,
        COALESCE(c.icon, '转') AS category_icon,
        COALESCE(c.color, '#2F7EF7') AS category_color,
        COALESCE(a.name, '账户已删除') AS account_name,
        CASE WHEN r.transfer_account_id IS NULL THEN NULL
          ELSE COALESCE(ta.name, '账户已删除') END AS transfer_account_name
      FROM t_record r
      LEFT JOIN t_category c ON r.category_id = c.id
      LEFT JOIN t_account a ON r.account_id = a.id
      LEFT JOIN t_account ta ON r.transfer_account_id = ta.id
      WHERE ${whereClause}
      ORDER BY r.record_time DESC, r.id DESC
      LIMIT ? OFFSET ?`,
      [...params, limit, offset]
    );
    const list: RecordListItem[] = [];
    while (result.goToNextRow()) {
      list.push(this.fromJoinedResult(result));
    }
    result.close();
    return list;
  }

  private async applyAccountChange(record: RecordModel): Promise<void> {
    if (record.type === RecordType.EXPENSE) {
      await this.accountRepository.applyBalanceDelta(record.accountId, -record.amount);
      return;
    }
    if (record.type === RecordType.INCOME) {
      await this.accountRepository.applyBalanceDelta(record.accountId, record.amount);
      return;
    }
    if (record.type === RecordType.TRANSFER && record.transferAccountId) {
      await this.accountRepository.applyBalanceDelta(record.accountId, -record.amount);
      await this.accountRepository.applyBalanceDelta(record.transferAccountId, record.amount);
    }
  }

  private async rollbackAccountChange(record: RecordModel): Promise<void> {
    if (record.type === RecordType.EXPENSE) {
      await this.accountRepository.applyBalanceDelta(record.accountId, record.amount);
      return;
    }
    if (record.type === RecordType.INCOME) {
      await this.accountRepository.applyBalanceDelta(record.accountId, -record.amount);
      return;
    }
    if (record.type === RecordType.TRANSFER && record.transferAccountId) {
      await this.accountRepository.applyBalanceDelta(record.accountId, record.amount);
      await this.accountRepository.applyBalanceDelta(record.transferAccountId, -record.amount);
    }
  }

  private async trendByFormat(startTime: number, endTime: number, format: string,
    ledgerName: string = ''): Promise<TrendPoint[]> {
    const startSecond = Math.floor(startTime / 1000);
    const endSecond = Math.floor(endTime / 1000);
    const normalizedLedger = ledgerName.trim();
    const ledgerClause = normalizedLedger.length > 0 ? ' AND ledger_name = ?' : '';
    const params: (number | string)[] = [
      format, RecordRepository.MILLIS_THRESHOLD, RecordType.INCOME, RecordType.EXPENSE,
      RecordType.INCOME, RecordType.EXPENSE, startTime, endTime, startSecond, endSecond
    ];
    if (normalizedLedger.length > 0) {
      params.push(normalizedLedger);
    }
    const result = await this.store().querySql(
      `SELECT strftime(?, CASE
          WHEN record_time >= ? THEN record_time / 1000
          ELSE record_time
        END, 'unixepoch', 'localtime') AS bucket,
        SUM(CASE WHEN type = ? THEN amount ELSE 0 END) AS income_amount,
        SUM(CASE WHEN type = ? THEN amount ELSE 0 END) AS expense_amount
      FROM t_record
      WHERE type IN (?, ?) AND (
        (record_time >= ? AND record_time < ?)
        OR (record_time >= ? AND record_time < ?)
      )${ledgerClause}
      GROUP BY bucket
      ORDER BY bucket ASC`,
      params
    );
    const list: TrendPoint[] = [];
    while (result.goToNextRow()) {
      list.push(new TrendPoint(
        result.getString(result.getColumnIndex('bucket')),
        result.getDouble(result.getColumnIndex('income_amount')),
        result.getDouble(result.getColumnIndex('expense_amount'))
      ));
    }
    result.close();
    return list;
  }

  private toBucket(record: RecordModel): relationalStore.ValuesBucket {
    const bucket: relationalStore.ValuesBucket = {};
    bucket['type'] = record.type;
    bucket['amount'] = record.amount;
    bucket['category_id'] = record.categoryId;
    bucket['account_id'] = record.accountId;
    if (record.transferAccountId) {
      bucket['transfer_account_id'] = record.transferAccountId;
    }
    bucket['record_time'] = record.recordTime;
    bucket['ledger_name'] = record.ledgerName.trim() || '日常账本';
    bucket['remark'] = record.remark;
    bucket['create_time'] = record.createTime;
    bucket['update_time'] = record.updateTime;
    return bucket;
  }

  private fromRecordResult(result: relationalStore.ResultSet): RecordModel {
    const transferIndex = result.getColumnIndex('transfer_account_id');
    return {
      id: result.getLong(result.getColumnIndex('id')),
      type: result.getLong(result.getColumnIndex('type')) as RecordType,
      amount: result.getDouble(result.getColumnIndex('amount')),
      categoryId: result.getLong(result.getColumnIndex('category_id')),
      accountId: result.getLong(result.getColumnIndex('account_id')),
      transferAccountId: result.isColumnNull(transferIndex) ? undefined : result.getLong(transferIndex),
      recordTime: result.getLong(result.getColumnIndex('record_time')),
      ledgerName: result.getString(result.getColumnIndex('ledger_name')) || '日常账本',
      remark: result.getString(result.getColumnIndex('remark')),
      createTime: result.getLong(result.getColumnIndex('create_time')),
      updateTime: result.getLong(result.getColumnIndex('update_time'))
    };
  }

  private fromJoinedResult(result: relationalStore.ResultSet): RecordListItem {
    const record = this.fromRecordResult(result);
    const item: RecordListItem = {
      id: record.id,
      type: record.type,
      amount: record.amount,
      categoryId: record.categoryId,
      accountId: record.accountId,
      transferAccountId: record.transferAccountId,
      recordTime: record.recordTime,
      ledgerName: record.ledgerName,
      remark: record.remark,
      createTime: record.createTime,
      updateTime: record.updateTime,
      categoryName: result.getString(result.getColumnIndex('category_name')),
      categoryIcon: result.getString(result.getColumnIndex('category_icon')),
      categoryColor: result.getString(result.getColumnIndex('category_color')),
      accountName: result.getString(result.getColumnIndex('account_name')),
      transferAccountName: result.isColumnNull(result.getColumnIndex('transfer_account_name'))
        ? undefined
        : result.getString(result.getColumnIndex('transfer_account_name'))
    };
    return item;
  }
}
