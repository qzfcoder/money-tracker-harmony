import { relationalStore } from '@kit.ArkData';
import { AppDatabase } from '../database/AppDatabase';
import { AccountModel, AccountType } from '../model/Account';

export class AccountRepository {
  private store(): relationalStore.RdbStore {
    return AppDatabase.getInstance().getStore();
  }

  async list(): Promise<AccountModel[]> {
    const result = await this.store().querySql('SELECT * FROM t_account ORDER BY sort_order ASC, id ASC');
    const list: AccountModel[] = [];
    while (result.goToNextRow()) {
      list.push(this.fromResult(result));
    }
    result.close();
    return list;
  }

  async findById(id: number): Promise<AccountModel | null> {
    const result = await this.store().querySql('SELECT * FROM t_account WHERE id = ?', [id]);
    let item: AccountModel | null = null;
    if (result.goToFirstRow()) {
      item = this.fromResult(result);
    }
    result.close();
    return item;
  }

  async save(account: AccountModel): Promise<number> {
    const now = Date.now();
    const balance = account.balance >= 0 ? account.balance : account.initialBalance;
    if (account.id && account.id > 0) {
      await this.store().executeSql(
        `UPDATE t_account
         SET name = ?, type = ?, balance = ?, initial_balance = ?, icon = ?, color = ?, is_liability = ?, sort_order = ?, create_time = ?
         WHERE id = ?`,
        [
          account.name,
          account.type,
          balance,
          account.initialBalance,
          account.icon,
          account.color,
          account.isLiability ? 1 : 0,
          account.sortOrder,
          account.createTime || now,
          account.id
        ]
      );
      return account.id;
    }
    const bucket: relationalStore.ValuesBucket = {};
    bucket['name'] = account.name;
    bucket['type'] = account.type;
    bucket['balance'] = balance;
    bucket['initial_balance'] = account.initialBalance;
    bucket['icon'] = account.icon;
    bucket['color'] = account.color;
    bucket['is_liability'] = account.isLiability ? 1 : 0;
    bucket['sort_order'] = account.sortOrder;
    bucket['create_time'] = account.createTime > 0 ? account.createTime : now;
    return await this.store().insert('t_account', bucket) as number;
  }

  async deleteById(id: number): Promise<void> {
    const item = await this.findById(id);
    if (!item) {
      return;
    }
    const fallback = await this.findFallbackId(id);
    if (fallback > 0) {
      await this.store().executeSql('UPDATE t_record SET account_id = ? WHERE account_id = ?', [fallback, id]);
      await this.store().executeSql('UPDATE t_record SET transfer_account_id = ? WHERE transfer_account_id = ?', [fallback, id]);
      await this.store().executeSql('UPDATE t_record_template SET account_id = ? WHERE account_id = ?', [fallback, id]);
      await this.store().executeSql('UPDATE t_recurring_bill SET account_id = ? WHERE account_id = ?', [fallback, id]);
    }
    const predicates = new relationalStore.RdbPredicates('t_account');
    predicates.equalTo('id', id);
    await this.store().delete(predicates);
  }

  async updateSortOrder(id: number, sortOrder: number): Promise<void> {
    await this.store().executeSql('UPDATE t_account SET sort_order = ? WHERE id = ?', [sortOrder, id]);
  }

  async applyBalanceDelta(accountId: number, delta: number): Promise<void> {
    await this.store().executeSql('UPDATE t_account SET balance = balance + ? WHERE id = ?', [delta, accountId]);
  }

  private async findFallbackId(excludeId: number): Promise<number> {
    const result = await this.store().querySql(
      'SELECT id FROM t_account WHERE id <> ? ORDER BY sort_order ASC, id ASC LIMIT 1',
      [excludeId]
    );
    let id = 0;
    if (result.goToFirstRow()) {
      id = result.getLong(result.getColumnIndex('id'));
    }
    result.close();
    return id;
  }

  private fromResult(result: relationalStore.ResultSet): AccountModel {
    return {
      id: result.getLong(result.getColumnIndex('id')),
      name: result.getString(result.getColumnIndex('name')),
      type: result.getLong(result.getColumnIndex('type')) as AccountType,
      balance: result.getDouble(result.getColumnIndex('balance')),
      initialBalance: result.getDouble(result.getColumnIndex('initial_balance')),
      icon: result.getString(result.getColumnIndex('icon')),
      color: result.getString(result.getColumnIndex('color')),
      isLiability: result.getLong(result.getColumnIndex('is_liability')) === 1,
      sortOrder: result.getLong(result.getColumnIndex('sort_order')),
      createTime: result.getLong(result.getColumnIndex('create_time'))
    };
  }
}
