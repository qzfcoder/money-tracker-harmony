import { CategoryModel } from '../model/Category';
import { AccountModel } from '../model/Account';
import { RecordModel, RecordType } from '../model/Record';
import { CategoryRepository } from '../repository/CategoryRepository';
import { AccountRepository } from '../repository/AccountRepository';
import { RecordRepository } from '../repository/RecordRepository';
import { common } from '@kit.AbilityKit';
import { AppDatabase } from '../database/AppDatabase';

@Observed
export class RecordViewModel {
  private categoryRepository: CategoryRepository = new CategoryRepository();
  private accountRepository: AccountRepository = new AccountRepository();
  private recordRepository: RecordRepository = new RecordRepository();

  type: RecordType.EXPENSE | RecordType.INCOME = RecordType.EXPENSE;
  amountText: string = '';
  remark: string = '';
  categories: CategoryModel[] = [];
  accounts: AccountModel[] = [];
  selectedCategory: CategoryModel | null = null;
  selectedAccount: AccountModel | null = null;
  recordId: number = 0;
  recordTime: number = 0;
  createTime: number = 0;

  async init(context: common.Context, recordId: number = 0): Promise<void> {
    await AppDatabase.getInstance().init(context);
    this.recordId = recordId;
    await Promise.all([
      this.loadCategories(),
      this.loadAccounts()
    ]);
    if (recordId > 0) {
      await this.loadRecord(recordId);
    }
  }

  async switchType(type: RecordType.EXPENSE | RecordType.INCOME): Promise<void> {
    this.type = type;
    await this.loadCategories();
  }

  async save(): Promise<RecordModel> {
    const amount = Number(this.amountText);
    if (!this.selectedCategory || !this.selectedAccount || !amount || amount <= 0) {
      throw new Error('请填写金额、分类和账户');
    }
    const now = Date.now();
    const record: RecordModel = {
      id: this.recordId > 0 ? this.recordId : undefined,
      type: this.type,
      amount: Math.round(amount * 100) / 100,
      categoryId: this.selectedCategory.id || 0,
      accountId: this.selectedAccount.id || 0,
      recordTime: this.recordTime > 0 ? this.recordTime : Date.now(),
      remark: this.remark,
      createTime: this.createTime > 0 ? this.createTime : now,
      updateTime: now
    };
    if (this.recordId > 0) {
      await this.recordRepository.update(record);
    } else {
      record.id = await this.recordRepository.insert(record);
      this.recordId = record.id;
    }
    return record;
  }

  private async loadCategories(): Promise<void> {
    this.categories = await this.categoryRepository.listByType(this.type);
    this.selectedCategory = this.categories.length > 0 ? this.categories[0] : null;
  }

  private async loadAccounts(): Promise<void> {
    this.accounts = await this.accountRepository.list();
    this.selectedAccount = this.accounts.length > 0 ? this.accounts[0] : null;
  }

  private async loadRecord(recordId: number): Promise<void> {
    const record = await this.recordRepository.findById(recordId);
    if (!record) {
      throw new Error('记录不存在');
    }
    if (record.type === RecordType.TRANSFER) {
      throw new Error('转账记录暂不支持编辑');
    }
    this.type = record.type;
    await this.loadCategories();
    this.amountText = `${record.amount}`;
    this.recordTime = record.recordTime;
    this.createTime = record.createTime;
    this.remark = record.remark;
    this.selectedCategory = this.categories.find((item: CategoryModel) => item.id === record.categoryId) || this.selectedCategory;
    this.selectedAccount = this.accounts.find((item: AccountModel) => item.id === record.accountId) || this.selectedAccount;
  }
}
