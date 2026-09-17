import { relationalStore } from '@kit.ArkData';
import { AppDatabase } from '../database/AppDatabase';
import { InvestmentPosition, InvestmentType } from '../model/Investment';

export class InvestmentRepository {
  private store(): relationalStore.RdbStore {
    return AppDatabase.getInstance().getStore();
  }

  async list(type?: InvestmentType): Promise<InvestmentPosition[]> {
    const result = typeof type === 'number' ?
      await this.store().querySql('SELECT * FROM t_investment_position WHERE type = ? ORDER BY sort_order ASC, id ASC', [type]) :
      await this.store().querySql('SELECT * FROM t_investment_position ORDER BY type ASC, sort_order ASC, id ASC');
    const list: InvestmentPosition[] = [];
    while (result.goToNextRow()) {
      list.push(this.fromResult(result));
    }
    result.close();
    return list;
  }

  async save(item: InvestmentPosition): Promise<number> {
    const now = Date.now();
    if (item.id && item.id > 0) {
      await this.store().executeSql(
        `UPDATE t_investment_position SET name = ?, type = ?, security_code = ?, holding_quantity = ?,
         cost_price = ?, current_price = ?, color = ?, sort_order = ?, quote_time = ?, create_time = ? WHERE id = ?`,
        [item.name, item.type, item.securityCode, item.holdingQuantity, item.costPrice, item.currentPrice,
          item.color, item.sortOrder, item.quoteTime, item.createTime || now, item.id]
      );
      return item.id;
    }
    const bucket: relationalStore.ValuesBucket = {};
    bucket['name'] = item.name;
    bucket['type'] = item.type;
    bucket['security_code'] = item.securityCode;
    bucket['holding_quantity'] = item.holdingQuantity;
    bucket['cost_price'] = item.costPrice;
    bucket['current_price'] = item.currentPrice;
    bucket['color'] = item.color;
    bucket['sort_order'] = item.sortOrder;
    bucket['quote_time'] = item.quoteTime;
    bucket['create_time'] = item.createTime || now;
    return await this.store().insert('t_investment_position', bucket) as number;
  }

  async updateQuote(id: number, price: number, quoteTime: number): Promise<void> {
    await this.store().executeSql(
      'UPDATE t_investment_position SET current_price = ?, quote_time = ? WHERE id = ?',
      [price, quoteTime, id]
    );
  }

  async deleteById(id: number): Promise<void> {
    const predicates = new relationalStore.RdbPredicates('t_investment_position');
    predicates.equalTo('id', id);
    await this.store().delete(predicates);
  }

  private fromResult(result: relationalStore.ResultSet): InvestmentPosition {
    return {
      id: result.getLong(result.getColumnIndex('id')),
      name: result.getString(result.getColumnIndex('name')),
      type: result.getLong(result.getColumnIndex('type')) as InvestmentType,
      securityCode: result.getString(result.getColumnIndex('security_code')),
      holdingQuantity: result.getDouble(result.getColumnIndex('holding_quantity')),
      costPrice: result.getDouble(result.getColumnIndex('cost_price')),
      currentPrice: result.getDouble(result.getColumnIndex('current_price')),
      color: result.getString(result.getColumnIndex('color')),
      sortOrder: result.getLong(result.getColumnIndex('sort_order')),
      quoteTime: result.getLong(result.getColumnIndex('quote_time')),
      createTime: result.getLong(result.getColumnIndex('create_time'))
    };
  }
}
