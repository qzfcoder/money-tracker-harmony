import { relationalStore } from '@kit.ArkData';
import { AppDatabase } from '../database/AppDatabase';
import { BudgetModel } from '../model/Budget';

export class BudgetRepository {
  private store(): relationalStore.RdbStore {
    return AppDatabase.getInstance().getStore();
  }

  async upsertMonthlyBudget(categoryId: number, amount: number, month: string): Promise<void> {
    const now = Date.now();
    const result = await this.store().querySql(
      'SELECT id FROM t_budget WHERE category_id = ? AND month = ?',
      [categoryId, month]
    );
    let existingId = 0;
    if (result.goToFirstRow()) {
      existingId = result.getLong(result.getColumnIndex('id'));
    }
    result.close();

    if (existingId > 0) {
      await this.store().executeSql(
        'UPDATE t_budget SET amount = ?, update_time = ? WHERE id = ?',
        [amount, now, existingId]
      );
      return;
    }

    const bucket: relationalStore.ValuesBucket = {};
    bucket['category_id'] = categoryId;
    bucket['amount'] = amount;
    bucket['month'] = month;
    bucket['create_time'] = now;
    bucket['update_time'] = now;
    await this.store().insert('t_budget', bucket);
  }

  async listByMonth(month: string): Promise<BudgetModel[]> {
    const result = await this.store().querySql('SELECT * FROM t_budget WHERE month = ?', [month]);
    const list: BudgetModel[] = [];
    while (result.goToNextRow()) {
      list.push({
        id: result.getLong(result.getColumnIndex('id')),
        categoryId: result.getLong(result.getColumnIndex('category_id')),
        amount: result.getDouble(result.getColumnIndex('amount')),
        month: result.getString(result.getColumnIndex('month')),
        createTime: result.getLong(result.getColumnIndex('create_time')),
        updateTime: result.getLong(result.getColumnIndex('update_time'))
      });
    }
    result.close();
    return list;
  }
}
