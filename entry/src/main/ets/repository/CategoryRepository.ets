import { relationalStore } from '@kit.ArkData';
import { AppDatabase } from '../database/AppDatabase';
import { CategoryModel } from '../model/Category';
import { RecordType } from '../model/Record';

export class CategoryRepository {
  private store(): relationalStore.RdbStore {
    return AppDatabase.getInstance().getStore();
  }

  async listByType(type: RecordType.EXPENSE | RecordType.INCOME): Promise<CategoryModel[]> {
    return this.listBySql('SELECT * FROM t_category WHERE type = ? ORDER BY sort_order ASC, id ASC', [type]);
  }

  async listAll(): Promise<CategoryModel[]> {
    return this.listBySql('SELECT * FROM t_category ORDER BY type ASC, sort_order ASC, id ASC');
  }

  async findById(id: number): Promise<CategoryModel | null> {
    const result = await this.store().querySql('SELECT * FROM t_category WHERE id = ?', [id]);
    let item: CategoryModel | null = null;
    if (result.goToFirstRow()) {
      item = this.fromResult(result);
    }
    result.close();
    return item;
  }

  async save(category: CategoryModel): Promise<number> {
    const now = Date.now();
    const bucket = this.toBucket(category, now);
    if (category.id && category.id > 0) {
      await this.store().executeSql(
        `UPDATE t_category
         SET name = ?, type = ?, icon = ?, color = ?, sort_order = ?, is_default = ?, create_time = ?
         WHERE id = ?`,
        [category.name, category.type, category.icon, category.color, category.sortOrder, category.isDefault ? 1 : 0, category.createTime || now, category.id]
      );
      return category.id;
    }
    return await this.store().insert('t_category', bucket) as number;
  }

  async deleteById(id: number): Promise<void> {
    const item = await this.findById(id);
    if (!item || item.isDefault) {
      return;
    }
    const fallback = await this.findFallbackId(item.type, id);
    if (fallback > 0) {
      await this.store().executeSql('UPDATE t_record SET category_id = ? WHERE category_id = ?', [fallback, id]);
    }
    const predicates = new relationalStore.RdbPredicates('t_category');
    predicates.equalTo('id', id);
    await this.store().delete(predicates);
  }

  async updateSortOrder(id: number, sortOrder: number): Promise<void> {
    await this.store().executeSql('UPDATE t_category SET sort_order = ? WHERE id = ?', [sortOrder, id]);
  }

  private async findFallbackId(type: RecordType.EXPENSE | RecordType.INCOME, excludeId: number): Promise<number> {
    const result = await this.store().querySql(
      'SELECT id FROM t_category WHERE type = ? AND id <> ? ORDER BY is_default DESC, sort_order ASC, id ASC LIMIT 1',
      [type, excludeId]
    );
    let id = 0;
    if (result.goToFirstRow()) {
      id = result.getLong(result.getColumnIndex('id'));
    }
    result.close();
    return id;
  }

  private async listBySql(sql: string, params: (number | string)[] = []): Promise<CategoryModel[]> {
    const result = await this.store().querySql(sql, params);
    const list: CategoryModel[] = [];
    while (result.goToNextRow()) {
      list.push(this.fromResult(result));
    }
    result.close();
    return list;
  }

  private fromResult(result: relationalStore.ResultSet): CategoryModel {
    return {
      id: result.getLong(result.getColumnIndex('id')),
      name: result.getString(result.getColumnIndex('name')),
      type: result.getLong(result.getColumnIndex('type')) as RecordType.EXPENSE | RecordType.INCOME,
      icon: result.getString(result.getColumnIndex('icon')),
      color: result.getString(result.getColumnIndex('color')),
      sortOrder: result.getLong(result.getColumnIndex('sort_order')),
      isDefault: result.getLong(result.getColumnIndex('is_default')) === 1,
      createTime: result.getLong(result.getColumnIndex('create_time'))
    };
  }

  private toBucket(category: CategoryModel, now: number): relationalStore.ValuesBucket {
    const bucket: relationalStore.ValuesBucket = {};
    bucket['name'] = category.name;
    bucket['type'] = category.type;
    bucket['icon'] = category.icon;
    bucket['color'] = category.color;
    bucket['sort_order'] = category.sortOrder;
    bucket['is_default'] = category.isDefault ? 1 : 0;
    bucket['create_time'] = category.createTime > 0 ? category.createTime : now;
    return bucket;
  }
}
