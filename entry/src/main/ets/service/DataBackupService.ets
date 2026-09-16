import { buffer } from '@kit.ArkTS';
import { common } from '@kit.AbilityKit';
import { fileIo, picker } from '@kit.CoreFileKit';
import { relationalStore } from '@kit.ArkData';
import { AppDatabase } from '../database/AppDatabase';

interface BackupRecord {
  id: number;
  type: number;
  amount: number;
  category_id: number;
  account_id: number;
  transfer_account_id: number | null;
  record_time: number;
  ledger_name: string;
  remark: string;
  create_time: number;
  update_time: number;
}

interface BackupCategory {
  id: number;
  name: string;
  type: number;
  icon: string;
  color: string;
  sort_order: number;
  is_default: number;
  create_time: number;
}

interface BackupAccount {
  id: number;
  name: string;
  type: number;
  balance: number;
  initial_balance: number;
  icon: string;
  color: string;
  is_liability: number;
  sort_order: number;
  create_time: number;
}

interface BackupBudget {
  id: number;
  category_id: number;
  amount: number;
  month: string;
  create_time: number;
  update_time: number;
}

interface BackupTemplate {
  id: number;
  name: string;
  type: number;
  amount: number;
  category_id: number;
  account_id: number;
  remark: string;
  use_count: number;
  create_time: number;
  update_time: number;
}

interface BackupRecurringBill {
  id: number;
  name: string;
  type: number;
  amount: number;
  category_id: number;
  account_id: number;
  frequency: number;
  day_of_month: number;
  day_of_week: number;
  remark: string;
  enabled: number;
  last_generated_key: string;
  create_time: number;
  update_time: number;
}

interface BackupSnapshot {
  format: string;
  version: number;
  exported_at: number;
  records: BackupRecord[];
  categories: BackupCategory[];
  accounts: BackupAccount[];
  budgets: BackupBudget[];
  templates: BackupTemplate[];
  recurringBills?: BackupRecurringBill[];
}

export class DataBackupResult {
  recordCount: number = 0;
  categoryCount: number = 0;
  accountCount: number = 0;
  budgetCount: number = 0;
  templateCount: number = 0;
  recurringBillCount: number = 0;
}

export class DataBackupService {
  private static readonly FORMAT: string = 'money-tracker-harmony-backup';
  private static readonly VERSION: number = 1;
  private static readonly MAX_FILE_SIZE: number = 16 * 1024 * 1024;

  static async saveToFile(context: common.UIAbilityContext): Promise<DataBackupResult> {
    const snapshot = await DataBackupService.createSnapshot();
    const options = new picker.DocumentSaveOptions();
    options.newFileNames = [`一页账备份-${DataBackupService.dateSuffix()}.json`];
    options.fileSuffixChoices = ['JSON 备份文件|.json'];
    const uris = await new picker.DocumentViewPicker(context).save(options);
    if (uris.length === 0) {
      throw new Error('未选择保存位置');
    }

    const file = fileIo.openSync(uris[0], fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC);
    try {
      fileIo.writeSync(file.fd, JSON.stringify(snapshot));
    } finally {
      fileIo.closeSync(file);
    }
    return DataBackupService.resultOf(snapshot);
  }

  static async restoreFromFile(context: common.UIAbilityContext): Promise<DataBackupResult> {
    const options = new picker.DocumentSelectOptions();
    options.maxSelectNumber = 1;
    options.fileSuffixFilters = ['JSON 备份文件|.json'];
    const uris = await new picker.DocumentViewPicker(context).select(options);
    if (uris.length === 0) {
      throw new Error('未选择备份文件');
    }
    const snapshot = DataBackupService.parseSnapshot(DataBackupService.readUtf8File(uris[0]));
    await DataBackupService.restoreSnapshot(snapshot);
    return DataBackupService.resultOf(snapshot);
  }

  private static async createSnapshot(): Promise<BackupSnapshot> {
    const store = AppDatabase.getInstance().getStore();
    return {
      format: DataBackupService.FORMAT,
      version: DataBackupService.VERSION,
      exported_at: Date.now(),
      records: await DataBackupService.readRecords(store),
      categories: await DataBackupService.readCategories(store),
      accounts: await DataBackupService.readAccounts(store),
      budgets: await DataBackupService.readBudgets(store),
      templates: await DataBackupService.readTemplates(store),
      recurringBills: await DataBackupService.readRecurringBills(store)
    };
  }

  private static async restoreSnapshot(snapshot: BackupSnapshot): Promise<void> {
    const store = AppDatabase.getInstance().getStore();
    await store.executeSql('DELETE FROM t_record');
    await store.executeSql('DELETE FROM t_budget');
    await store.executeSql('DELETE FROM t_record_template');
    await store.executeSql('DELETE FROM t_recurring_bill');
    await store.executeSql('DELETE FROM t_category');
    await store.executeSql('DELETE FROM t_account');

    for (const item of snapshot.categories) {
      await store.insert('t_category', DataBackupService.categoryBucket(item));
    }
    for (const item of snapshot.accounts) {
      await store.insert('t_account', DataBackupService.accountBucket(item));
    }
    for (const item of snapshot.records) {
      await store.insert('t_record', DataBackupService.recordBucket(item));
    }
    for (const item of snapshot.budgets) {
      await store.insert('t_budget', DataBackupService.budgetBucket(item));
    }
    for (const item of snapshot.templates) {
      await store.insert('t_record_template', DataBackupService.templateBucket(item));
    }
    for (const item of snapshot.recurringBills || []) {
      await store.insert('t_recurring_bill', DataBackupService.recurringBillBucket(item));
    }
  }

  private static async readRecords(store: relationalStore.RdbStore): Promise<BackupRecord[]> {
    const result = await store.querySql('SELECT * FROM t_record ORDER BY id ASC');
    const list: BackupRecord[] = [];
    while (result.goToNextRow()) {
      const transferIndex = result.getColumnIndex('transfer_account_id');
      list.push({
        id: result.getLong(result.getColumnIndex('id')),
        type: result.getLong(result.getColumnIndex('type')),
        amount: result.getDouble(result.getColumnIndex('amount')),
        category_id: result.getLong(result.getColumnIndex('category_id')),
        account_id: result.getLong(result.getColumnIndex('account_id')),
        transfer_account_id: result.isColumnNull(transferIndex) ? null : result.getLong(transferIndex),
        record_time: result.getLong(result.getColumnIndex('record_time')),
        ledger_name: result.getString(result.getColumnIndex('ledger_name')) || '日常账本',
        remark: result.getString(result.getColumnIndex('remark')),
        create_time: result.getLong(result.getColumnIndex('create_time')),
        update_time: result.getLong(result.getColumnIndex('update_time'))
      });
    }
    result.close();
    return list;
  }

  private static async readCategories(store: relationalStore.RdbStore): Promise<BackupCategory[]> {
    const result = await store.querySql('SELECT * FROM t_category ORDER BY id ASC');
    const list: BackupCategory[] = [];
    while (result.goToNextRow()) {
      list.push({
        id: result.getLong(result.getColumnIndex('id')),
        name: result.getString(result.getColumnIndex('name')),
        type: result.getLong(result.getColumnIndex('type')),
        icon: result.getString(result.getColumnIndex('icon')),
        color: result.getString(result.getColumnIndex('color')),
        sort_order: result.getLong(result.getColumnIndex('sort_order')),
        is_default: result.getLong(result.getColumnIndex('is_default')),
        create_time: result.getLong(result.getColumnIndex('create_time'))
      });
    }
    result.close();
    return list;
  }

  private static async readAccounts(store: relationalStore.RdbStore): Promise<BackupAccount[]> {
    const result = await store.querySql('SELECT * FROM t_account ORDER BY id ASC');
    const list: BackupAccount[] = [];
    while (result.goToNextRow()) {
      list.push({
        id: result.getLong(result.getColumnIndex('id')),
        name: result.getString(result.getColumnIndex('name')),
        type: result.getLong(result.getColumnIndex('type')),
        balance: result.getDouble(result.getColumnIndex('balance')),
        initial_balance: result.getDouble(result.getColumnIndex('initial_balance')),
        icon: result.getString(result.getColumnIndex('icon')),
        color: result.getString(result.getColumnIndex('color')),
        is_liability: result.getLong(result.getColumnIndex('is_liability')),
        sort_order: result.getLong(result.getColumnIndex('sort_order')),
        create_time: result.getLong(result.getColumnIndex('create_time'))
      });
    }
    result.close();
    return list;
  }

  private static async readBudgets(store: relationalStore.RdbStore): Promise<BackupBudget[]> {
    const result = await store.querySql('SELECT * FROM t_budget ORDER BY id ASC');
    const list: BackupBudget[] = [];
    while (result.goToNextRow()) {
      list.push({
        id: result.getLong(result.getColumnIndex('id')),
        category_id: result.getLong(result.getColumnIndex('category_id')),
        amount: result.getDouble(result.getColumnIndex('amount')),
        month: result.getString(result.getColumnIndex('month')),
        create_time: result.getLong(result.getColumnIndex('create_time')),
        update_time: result.getLong(result.getColumnIndex('update_time'))
      });
    }
    result.close();
    return list;
  }

  private static async readTemplates(store: relationalStore.RdbStore): Promise<BackupTemplate[]> {
    const result = await store.querySql('SELECT * FROM t_record_template ORDER BY id ASC');
    const list: BackupTemplate[] = [];
    while (result.goToNextRow()) {
      list.push({
        id: result.getLong(result.getColumnIndex('id')),
        name: result.getString(result.getColumnIndex('name')),
        type: result.getLong(result.getColumnIndex('type')),
        amount: result.getDouble(result.getColumnIndex('amount')),
        category_id: result.getLong(result.getColumnIndex('category_id')),
        account_id: result.getLong(result.getColumnIndex('account_id')),
        remark: result.getString(result.getColumnIndex('remark')),
        use_count: result.getLong(result.getColumnIndex('use_count')),
        create_time: result.getLong(result.getColumnIndex('create_time')),
        update_time: result.getLong(result.getColumnIndex('update_time'))
      });
    }
    result.close();
    return list;
  }

  private static async readRecurringBills(store: relationalStore.RdbStore): Promise<BackupRecurringBill[]> {
    const result = await store.querySql('SELECT * FROM t_recurring_bill ORDER BY id ASC');
    const list: BackupRecurringBill[] = [];
    while (result.goToNextRow()) {
      list.push({
        id: result.getLong(result.getColumnIndex('id')),
        name: result.getString(result.getColumnIndex('name')),
        type: result.getLong(result.getColumnIndex('type')),
        amount: result.getDouble(result.getColumnIndex('amount')),
        category_id: result.getLong(result.getColumnIndex('category_id')),
        account_id: result.getLong(result.getColumnIndex('account_id')),
        frequency: result.getLong(result.getColumnIndex('frequency')),
        day_of_month: result.getLong(result.getColumnIndex('day_of_month')),
        day_of_week: result.getLong(result.getColumnIndex('day_of_week')),
        remark: result.getString(result.getColumnIndex('remark')),
        enabled: result.getLong(result.getColumnIndex('enabled')),
        last_generated_key: result.getString(result.getColumnIndex('last_generated_key')),
        create_time: result.getLong(result.getColumnIndex('create_time')),
        update_time: result.getLong(result.getColumnIndex('update_time'))
      });
    }
    result.close();
    return list;
  }

  private static parseSnapshot(text: string): BackupSnapshot {
    let snapshot: BackupSnapshot;
    try {
      snapshot = JSON.parse(text) as BackupSnapshot;
    } catch (error) {
      throw new Error('备份文件不是有效的 JSON');
    }
    if (!snapshot || snapshot.format !== DataBackupService.FORMAT ||
      snapshot.version !== DataBackupService.VERSION ||
      !Array.isArray(snapshot.records) ||
      !Array.isArray(snapshot.categories) ||
      !Array.isArray(snapshot.accounts) ||
      !Array.isArray(snapshot.budgets) ||
      !Array.isArray(snapshot.templates)) {
      throw new Error('备份文件格式不受支持');
    }
    return snapshot;
  }

  private static readUtf8File(uri: string): string {
    const file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
    try {
      const size = fileIo.statSync(file.fd).size;
      if (size <= 0) {
        throw new Error('备份文件为空');
      }
      if (size > DataBackupService.MAX_FILE_SIZE) {
        throw new Error('备份文件超过 16MB');
      }
      const bytes = new ArrayBuffer(size);
      const readLength = fileIo.readSync(file.fd, bytes);
      return buffer.from(bytes).toString('utf8', 0, readLength).replace(/^\uFEFF/, '');
    } finally {
      fileIo.closeSync(file);
    }
  }

  private static recordBucket(item: BackupRecord): relationalStore.ValuesBucket {
    const bucket: relationalStore.ValuesBucket = {};
    bucket['id'] = item.id;
    bucket['type'] = item.type;
    bucket['amount'] = item.amount;
    bucket['category_id'] = item.category_id;
    bucket['account_id'] = item.account_id;
    if (item.transfer_account_id !== null) {
      bucket['transfer_account_id'] = item.transfer_account_id;
    }
    bucket['record_time'] = item.record_time;
    bucket['ledger_name'] = item.ledger_name || '日常账本';
    bucket['remark'] = item.remark;
    bucket['create_time'] = item.create_time;
    bucket['update_time'] = item.update_time;
    return bucket;
  }

  private static categoryBucket(item: BackupCategory): relationalStore.ValuesBucket {
    const bucket: relationalStore.ValuesBucket = {};
    bucket['id'] = item.id;
    bucket['name'] = item.name;
    bucket['type'] = item.type;
    bucket['icon'] = item.icon;
    bucket['color'] = item.color;
    bucket['sort_order'] = item.sort_order;
    bucket['is_default'] = item.is_default;
    bucket['create_time'] = item.create_time;
    return bucket;
  }

  private static accountBucket(item: BackupAccount): relationalStore.ValuesBucket {
    const bucket: relationalStore.ValuesBucket = {};
    bucket['id'] = item.id;
    bucket['name'] = item.name;
    bucket['type'] = item.type;
    bucket['balance'] = item.balance;
    bucket['initial_balance'] = item.initial_balance;
    bucket['icon'] = item.icon;
    bucket['color'] = item.color;
    bucket['is_liability'] = item.is_liability;
    bucket['sort_order'] = item.sort_order;
    bucket['create_time'] = item.create_time;
    return bucket;
  }

  private static budgetBucket(item: BackupBudget): relationalStore.ValuesBucket {
    const bucket: relationalStore.ValuesBucket = {};
    bucket['id'] = item.id;
    bucket['category_id'] = item.category_id;
    bucket['amount'] = item.amount;
    bucket['month'] = item.month;
    bucket['create_time'] = item.create_time;
    bucket['update_time'] = item.update_time;
    return bucket;
  }

  private static templateBucket(item: BackupTemplate): relationalStore.ValuesBucket {
    const bucket: relationalStore.ValuesBucket = {};
    bucket['id'] = item.id;
    bucket['name'] = item.name;
    bucket['type'] = item.type;
    bucket['amount'] = item.amount;
    bucket['category_id'] = item.category_id;
    bucket['account_id'] = item.account_id;
    bucket['remark'] = item.remark;
    bucket['use_count'] = item.use_count;
    bucket['create_time'] = item.create_time;
    bucket['update_time'] = item.update_time;
    return bucket;
  }

  private static recurringBillBucket(item: BackupRecurringBill): relationalStore.ValuesBucket {
    const bucket: relationalStore.ValuesBucket = {};
    bucket['id'] = item.id;
    bucket['name'] = item.name;
    bucket['type'] = item.type;
    bucket['amount'] = item.amount;
    bucket['category_id'] = item.category_id;
    bucket['account_id'] = item.account_id;
    bucket['frequency'] = item.frequency;
    bucket['day_of_month'] = item.day_of_month;
    bucket['day_of_week'] = item.day_of_week;
    bucket['remark'] = item.remark;
    bucket['enabled'] = item.enabled;
    bucket['last_generated_key'] = item.last_generated_key;
    bucket['create_time'] = item.create_time;
    bucket['update_time'] = item.update_time;
    return bucket;
  }

  private static resultOf(snapshot: BackupSnapshot): DataBackupResult {
    const result = new DataBackupResult();
    result.recordCount = snapshot.records.length;
    result.categoryCount = snapshot.categories.length;
    result.accountCount = snapshot.accounts.length;
    result.budgetCount = snapshot.budgets.length;
    result.templateCount = snapshot.templates.length;
    result.recurringBillCount = snapshot.recurringBills ? snapshot.recurringBills.length : 0;
    return result;
  }

  private static dateSuffix(): string {
    const date = new Date();
    const year = date.getFullYear();
    const month = `${date.getMonth() + 1}`.padStart(2, '0');
    const day = `${date.getDate()}`.padStart(2, '0');
    return `${year}${month}${day}`;
  }
}
