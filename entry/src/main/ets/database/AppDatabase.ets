import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { CREATE_INDEX_SQL, CREATE_TABLE_SQL, DbHelper } from './DbHelper';
import { AccountModel } from '../model/Account';
import { CategoryModel } from '../model/Category';
import { DEFAULT_AUTO_BLACKLIST_KEYWORDS, DEFAULT_AUTO_RULES } from '../constants/AutoBookkeepingConstants';
import { AutoRuleType } from '../model/AutoBookkeeping';
import { RecordType } from '../model/Record';
import { ToastUtil } from '../utils/ToastUtil';

const STORE_CONFIG: relationalStore.StoreConfig = {
  name: 'money_tracker.db',
  securityLevel: relationalStore.SecurityLevel.S1
};

interface AutoRuleInitData {
  ruleType: AutoRuleType;
  keyword: string;
  recordType: RecordType.EXPENSE | RecordType.INCOME;
  categoryId: number;
  enabled: boolean;
  sortOrder: number;
  createTime: number;
  updateTime: number;
}

export class AppDatabase {
  private static instance: AppDatabase | null = null;
  private dbStore: relationalStore.RdbStore | null = null;
  private initPromise: Promise<void> | null = null;

  private constructor() {}

  static getInstance(): AppDatabase {
    if (!AppDatabase.instance) {
      AppDatabase.instance = new AppDatabase();
    }
    return AppDatabase.instance;
  }

  async init(context: common.Context): Promise<void> {
    if (this.dbStore) {
      return;
    }
    if (this.initPromise) {
      await this.initPromise;
      return;
    }
    this.initPromise = this.initialize(context);
    try {
      await this.initPromise;
    } finally {
      this.initPromise = null;
    }
  }

  getStore(): relationalStore.RdbStore {
    if (!this.dbStore) {
      throw new Error('Database not initialized');
    }
    return this.dbStore;
  }

  private async initialize(context: common.Context): Promise<void> {
    try {
      this.dbStore = await relationalStore.getRdbStore(context, STORE_CONFIG);
      await this.createSchema();
      await this.seedDefaults();
    } catch (error) {
      this.dbStore = null;
      throw new Error(ToastUtil.error(error, '数据库初始化失败'));
    }
  }

  private async createSchema(): Promise<void> {
    const store = this.getStore();
    for (const sql of CREATE_TABLE_SQL) {
      await store.executeSql(sql);
    }
    await this.migrateSchema();
    for (const sql of CREATE_INDEX_SQL) {
      await store.executeSql(sql);
    }
  }

  private async migrateSchema(): Promise<void> {
    const store = this.getStore();
    if (!await this.hasColumn('t_record', 'ledger_name')) {
      await store.executeSql("ALTER TABLE t_record ADD COLUMN ledger_name TEXT NOT NULL DEFAULT '日常账本'");
    }
    await store.executeSql(
      `UPDATE t_record
       SET ledger_name = substr(
         remark,
         instr(remark, '[账本:') + 4,
         instr(substr(remark, instr(remark, '[账本:') + 4), ']') - 1
       )
       WHERE remark LIKE '%[账本:%]%'
         AND (ledger_name IS NULL OR ledger_name = '' OR ledger_name = '日常账本')`
    );
    await store.executeSql("UPDATE t_record SET ledger_name = '日常账本' WHERE ledger_name IS NULL OR trim(ledger_name) = ''");
  }

  private async hasColumn(tableName: string, columnName: string): Promise<boolean> {
    const result = await this.getStore().querySql(`PRAGMA table_info(${tableName})`);
    let found = false;
    while (result.goToNextRow()) {
      if (result.getString(result.getColumnIndex('name')) === columnName) {
        found = true;
        break;
      }
    }
    result.close();
    return found;
  }

  private async seedDefaults(): Promise<void> {
    const now = Date.now();
    const store = this.getStore();

    const categoryResult = await store.querySql('SELECT COUNT(1) AS count FROM t_category');
    let categoryCount = 0;
    if (categoryResult.goToFirstRow()) {
      categoryCount = categoryResult.getLong(categoryResult.getColumnIndex('count'));
    }
    categoryResult.close();

    if (categoryCount === 0) {
      const categories = DbHelper.getDefaultCategories(now);
      for (const item of categories) {
        await store.insert('t_category', this.categoryToBucket(item));
      }
    }

    const accountResult = await store.querySql('SELECT COUNT(1) AS count FROM t_account');
    let accountCount = 0;
    if (accountResult.goToFirstRow()) {
      accountCount = accountResult.getLong(accountResult.getColumnIndex('count'));
    }
    accountResult.close();

    if (accountCount === 0) {
      const accounts = DbHelper.getDefaultAccounts(now);
      for (const item of accounts) {
        await store.insert('t_account', this.accountToBucket(item));
      }
    }

    const templateResult = await store.querySql('SELECT COUNT(1) AS count FROM t_record_template');
    let templateCount = 0;
    if (templateResult.goToFirstRow()) {
      templateCount = templateResult.getLong(templateResult.getColumnIndex('count'));
    }
    templateResult.close();
    if (templateCount === 0) {
      await this.seedRecordTemplates(now);
    }

    const ruleResult = await store.querySql('SELECT COUNT(1) AS count FROM t_auto_rule');
    let ruleCount = 0;
    if (ruleResult.goToFirstRow()) {
      ruleCount = ruleResult.getLong(ruleResult.getColumnIndex('count'));
    }
    ruleResult.close();

    if (ruleCount === 0) {
      await this.seedAutoRules(now);
    }
  }

  private async seedAutoRules(now: number): Promise<void> {
    const store = this.getStore();
    const categoryMap = await this.loadCategoryMap();
    let sortOrder = 1;
    for (const keyword of DEFAULT_AUTO_BLACKLIST_KEYWORDS) {
      await store.insert('t_auto_rule', this.autoRuleToBucket({
        ruleType: AutoRuleType.BLACKLIST,
        keyword,
        recordType: RecordType.EXPENSE,
        categoryId: 0,
        enabled: true,
        sortOrder,
        createTime: now,
        updateTime: now
      }));
      sortOrder++;
    }

    for (const seed of DEFAULT_AUTO_RULES) {
      await store.insert('t_auto_rule', this.autoRuleToBucket({
        ruleType: seed.ruleType,
        keyword: seed.keyword,
        recordType: seed.recordType,
        categoryId: categoryMap.get(seed.categoryName) || 0,
        enabled: true,
        sortOrder,
        createTime: now,
        updateTime: now
      }));
      sortOrder++;
    }
  }

  private async seedRecordTemplates(now: number): Promise<void> {
    const store = this.getStore();
    const preferredAccountId = await this.loadAccountId('微信');
    const accountId = preferredAccountId > 0 ? preferredAccountId : await this.loadFirstAccountId();
    const names: string[] = ['早餐', '地铁', '日用品', '工资'];
    const categoryNames: string[] = ['餐饮', '交通', '日用', '工资'];
    const types: RecordType[] = [RecordType.EXPENSE, RecordType.EXPENSE, RecordType.EXPENSE, RecordType.INCOME];
    const amounts: number[] = [12, 3, 30, 5000];
    for (let index = 0; index < names.length; index++) {
      const categoryId = await this.loadCategoryId(categoryNames[index], types[index]);
      if (categoryId <= 0 || accountId <= 0) {
        continue;
      }
      const bucket: relationalStore.ValuesBucket = {};
      bucket['name'] = names[index];
      bucket['type'] = types[index];
      bucket['amount'] = amounts[index];
      bucket['category_id'] = categoryId;
      bucket['account_id'] = accountId;
      bucket['remark'] = names[index];
      bucket['use_count'] = 0;
      bucket['create_time'] = now + index;
      bucket['update_time'] = now + index;
      await store.insert('t_record_template', bucket);
    }
  }

  private async loadCategoryId(name: string, type: RecordType): Promise<number> {
    const result = await this.getStore().querySql(
      'SELECT id FROM t_category WHERE name = ? AND type = ? ORDER BY id ASC LIMIT 1',
      [name, type]
    );
    let id = 0;
    if (result.goToFirstRow()) {
      id = result.getLong(result.getColumnIndex('id'));
    }
    result.close();
    return id;
  }

  private async loadAccountId(name: string): Promise<number> {
    const result = await this.getStore().querySql(
      'SELECT id FROM t_account WHERE name = ? ORDER BY id ASC LIMIT 1',
      [name]
    );
    let id = 0;
    if (result.goToFirstRow()) {
      id = result.getLong(result.getColumnIndex('id'));
    }
    result.close();
    return id;
  }

  private async loadFirstAccountId(): Promise<number> {
    const result = await this.getStore().querySql('SELECT id FROM t_account ORDER BY sort_order ASC, id ASC LIMIT 1');
    let id = 0;
    if (result.goToFirstRow()) {
      id = result.getLong(result.getColumnIndex('id'));
    }
    result.close();
    return id;
  }

  private categoryToBucket(item: CategoryModel): relationalStore.ValuesBucket {
    const bucket: relationalStore.ValuesBucket = {};
    bucket['name'] = item.name;
    bucket['type'] = item.type;
    bucket['icon'] = item.icon;
    bucket['color'] = item.color;
    bucket['sort_order'] = item.sortOrder;
    bucket['is_default'] = item.isDefault ? 1 : 0;
    bucket['create_time'] = item.createTime;
    return bucket;
  }

  private accountToBucket(item: AccountModel): relationalStore.ValuesBucket {
    const bucket: relationalStore.ValuesBucket = {};
    bucket['name'] = item.name;
    bucket['type'] = item.type;
    bucket['balance'] = item.balance;
    bucket['initial_balance'] = item.initialBalance;
    bucket['icon'] = item.icon;
    bucket['color'] = item.color;
    bucket['is_liability'] = item.isLiability ? 1 : 0;
    bucket['sort_order'] = item.sortOrder;
    bucket['create_time'] = item.createTime;
    return bucket;
  }

  private autoRuleToBucket(item: AutoRuleInitData): relationalStore.ValuesBucket {
    const bucket: relationalStore.ValuesBucket = {};
    bucket['rule_type'] = item.ruleType;
    bucket['keyword'] = item.keyword;
    bucket['record_type'] = item.recordType;
    bucket['category_id'] = item.categoryId;
    bucket['enabled'] = item.enabled ? 1 : 0;
    bucket['sort_order'] = item.sortOrder;
    bucket['create_time'] = item.createTime;
    bucket['update_time'] = item.updateTime;
    return bucket;
  }

  private async loadCategoryMap(): Promise<Map<string, number>> {
    const result = await this.getStore().querySql('SELECT id, name FROM t_category');
    const map: Map<string, number> = new Map<string, number>();
    while (result.goToNextRow()) {
      map.set(
        result.getString(result.getColumnIndex('name')),
        result.getLong(result.getColumnIndex('id'))
      );
    }
    result.close();
    return map;
  }
}
