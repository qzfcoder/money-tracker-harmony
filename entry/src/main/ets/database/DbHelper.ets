import { AccountModel } from '../model/Account';
import { CategoryModel } from '../model/Category';
import { DEFAULT_ACCOUNTS } from '../constants/AccountConstants';
import { DEFAULT_CATEGORIES } from '../constants/CategoryConstants';

export const CREATE_TABLE_SQL: string[] = [
  `CREATE TABLE IF NOT EXISTS t_record (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    type INTEGER NOT NULL,
    amount REAL NOT NULL,
    category_id INTEGER NOT NULL,
    account_id INTEGER NOT NULL,
    transfer_account_id INTEGER DEFAULT NULL,
    record_time INTEGER NOT NULL,
    ledger_name TEXT NOT NULL DEFAULT '日常账本',
    remark TEXT DEFAULT '',
    create_time INTEGER NOT NULL,
    update_time INTEGER NOT NULL
  )`,
  `CREATE TABLE IF NOT EXISTS t_category (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    type INTEGER NOT NULL,
    icon TEXT NOT NULL,
    color TEXT NOT NULL,
    sort_order INTEGER DEFAULT 0,
    is_default INTEGER DEFAULT 0,
    create_time INTEGER NOT NULL
  )`,
  `CREATE TABLE IF NOT EXISTS t_account (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    type INTEGER NOT NULL,
    balance REAL DEFAULT 0,
    initial_balance REAL DEFAULT 0,
    icon TEXT NOT NULL,
    color TEXT NOT NULL,
    is_liability INTEGER DEFAULT 0,
    sort_order INTEGER DEFAULT 0,
    create_time INTEGER NOT NULL
  )`,
  `CREATE TABLE IF NOT EXISTS t_budget (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    category_id INTEGER DEFAULT 0,
    amount REAL NOT NULL,
    month TEXT NOT NULL,
    create_time INTEGER NOT NULL,
    update_time INTEGER NOT NULL
  )`,
  `CREATE TABLE IF NOT EXISTS t_auto_rule (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    rule_type INTEGER NOT NULL,
    keyword TEXT NOT NULL,
    record_type INTEGER NOT NULL,
    category_id INTEGER DEFAULT 0,
    enabled INTEGER DEFAULT 1,
    sort_order INTEGER DEFAULT 0,
    create_time INTEGER NOT NULL,
    update_time INTEGER NOT NULL
  )`,
  `CREATE TABLE IF NOT EXISTS t_auto_bill (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    source TEXT NOT NULL,
    bundle_name TEXT DEFAULT '',
    app_name TEXT DEFAULT '',
    title TEXT DEFAULT '',
    content TEXT DEFAULT '',
    raw_text TEXT DEFAULT '',
    amount REAL DEFAULT 0,
    type INTEGER DEFAULT 1,
    category_id INTEGER DEFAULT 0,
    account_id INTEGER DEFAULT 0,
    record_time INTEGER NOT NULL,
    remark TEXT DEFAULT '',
    confidence REAL DEFAULT 0,
    matched_rule TEXT DEFAULT '',
    status INTEGER DEFAULT 0,
    create_time INTEGER NOT NULL,
    update_time INTEGER NOT NULL
  )`,
  `CREATE TABLE IF NOT EXISTS t_record_template (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    type INTEGER NOT NULL,
    amount REAL NOT NULL,
    category_id INTEGER NOT NULL,
    account_id INTEGER NOT NULL,
    remark TEXT DEFAULT '',
    use_count INTEGER DEFAULT 0,
    create_time INTEGER NOT NULL,
    update_time INTEGER NOT NULL
  )`,
  `CREATE TABLE IF NOT EXISTS t_recurring_bill (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    type INTEGER NOT NULL,
    amount REAL NOT NULL,
    category_id INTEGER NOT NULL,
    account_id INTEGER NOT NULL,
    frequency INTEGER NOT NULL,
    day_of_month INTEGER DEFAULT 1,
    day_of_week INTEGER DEFAULT 1,
    remark TEXT DEFAULT '',
    enabled INTEGER DEFAULT 1,
    last_generated_key TEXT DEFAULT '',
    create_time INTEGER NOT NULL,
    update_time INTEGER NOT NULL
  )`
];

export const CREATE_INDEX_SQL: string[] = [
  'CREATE INDEX IF NOT EXISTS idx_record_time ON t_record(record_time)',
  'CREATE INDEX IF NOT EXISTS idx_record_ledger ON t_record(ledger_name)',
  'CREATE INDEX IF NOT EXISTS idx_category ON t_record(category_id)',
  'CREATE INDEX IF NOT EXISTS idx_account ON t_record(account_id)',
  'CREATE INDEX IF NOT EXISTS idx_budget_month ON t_budget(month)',
  'CREATE INDEX IF NOT EXISTS idx_auto_rule_type ON t_auto_rule(rule_type)',
  'CREATE INDEX IF NOT EXISTS idx_auto_bill_status ON t_auto_bill(status)',
  'CREATE INDEX IF NOT EXISTS idx_auto_bill_time ON t_auto_bill(record_time)',
  'CREATE INDEX IF NOT EXISTS idx_record_template_type ON t_record_template(type)',
  'CREATE INDEX IF NOT EXISTS idx_record_template_used ON t_record_template(use_count, update_time)',
  'CREATE INDEX IF NOT EXISTS idx_recurring_bill_enabled ON t_recurring_bill(enabled)',
  'CREATE INDEX IF NOT EXISTS idx_recurring_bill_key ON t_recurring_bill(last_generated_key)'
];

export class DbHelper {
  static getDefaultCategories(now: number): CategoryModel[] {
    return DEFAULT_CATEGORIES.map((category: CategoryModel) => {
      return DbHelper.cloneCategory(category, now);
    });
  }

  static getDefaultAccounts(now: number): AccountModel[] {
    return DEFAULT_ACCOUNTS.map((account: AccountModel) => {
      return DbHelper.cloneAccount(account, now);
    });
  }

  private static cloneCategory(category: CategoryModel, createTime: number): CategoryModel {
    const clone: CategoryModel = {
      id: category.id,
      name: category.name,
      type: category.type,
      icon: category.icon,
      color: category.color,
      sortOrder: category.sortOrder,
      isDefault: category.isDefault,
      createTime
    };
    return clone;
  }

  private static cloneAccount(account: AccountModel, createTime: number): AccountModel {
    const clone: AccountModel = {
      id: account.id,
      name: account.name,
      type: account.type,
      balance: account.balance,
      initialBalance: account.initialBalance,
      icon: account.icon,
      color: account.color,
      isLiability: account.isLiability,
      sortOrder: account.sortOrder,
      createTime
    };
    return clone;
  }
}
