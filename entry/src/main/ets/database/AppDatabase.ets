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
    for (const sql of CREATE_INDEX_SQL) {
      await store.executeSql(sql);
    }
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
