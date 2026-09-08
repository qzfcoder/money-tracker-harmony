import { CategoryModel } from '../model/Category';
import { AccountModel } from '../model/Account';
import { RecordModel, RecordType } from '../model/Record';
import { CategoryRepository } from '../repository/CategoryRepository';
import { AccountRepository } from '../repository/AccountRepository';
import { RecordRepository } from '../repository/RecordRepository';
import { common } from '@kit.AbilityKit';
import { AppDatabase } from '../database/AppDatabase';
import { NumberUtil } from '../utils/NumberUtil';
import { LedgerEnhancementRepository } from '../repository/LedgerEnhancementRepository';

@Observed
export class RecordViewModel {
  private categoryRepository: CategoryRepository = new CategoryRepository();
  private accountRepository: AccountRepository = new AccountRepository();
  private recordRepository: RecordRepository = new RecordRepository();
  private enhancementRepository: LedgerEnhancementRepository = new LedgerEnhancementRepository();

  type: RecordType.EXPENSE | RecordType.INCOME | RecordType.TRANSFER = RecordType.EXPENSE;
  amountText: string = '';
  remark: string = '';
  categories: CategoryModel[] = [];
  accounts: AccountModel[] = [];
  selectedCategory: CategoryModel | null = null;
  selectedAccount: AccountModel | null = null;
  selectedTransferAccount: AccountModel | null = null;
  recordId: number = 0;
  recordTime: number = 0;
  ledgerName: string = '日常账本';
  createTime: number = 0;

  async init(context: common.Context, recordId: number = 0): Promise<void> {
    await AppDatabase.getInstance().init(context);
    this.recordId = recordId;
    await Promise.all([
      this.loadCategories(),
      this.loadAccounts()
    ]);
    this.ledgerName = await this.enhancementRepository.getActiveLedger(context);
    if (recordId > 0) {
      await this.loadRecord(recordId);
    }
  }

  async switchType(type: RecordType.EXPENSE | RecordType.INCOME | RecordType.TRANSFER): Promise<void> {
    this.type = type;
    if (type === RecordType.TRANSFER) {
      this.categories = [];
      this.selectedCategory = null;
      if (this.selectedTransferAccount?.id === this.selectedAccount?.id) {
        this.selectedTransferAccount = null;
      }
      return;
    }
    await this.loadCategories();
  }

  async save(): Promise<RecordModel> {
    const amount = NumberUtil.toCentSafe(this.amountText);
    if (!this.selectedAccount || !amount || amount <= 0) {
      throw new Error('请填写金额、分类和账户');
    }
    if (this.type !== RecordType.TRANSFER && !this.selectedCategory) {
      throw new Error('请填写金额、分类和账户');
    }
    if (this.type === RecordType.TRANSFER &&
      (!this.selectedTransferAccount || this.selectedTransferAccount.id === this.selectedAccount.id)) {
      throw new Error('请选择不同的转出和转入账户');
    }
    const now = Date.now();
    const record: RecordModel = {
      id: this.recordId > 0 ? this.recordId : undefined,
      type: this.type,
      amount,
      categoryId: this.selectedCategory?.id || 0,
      accountId: this.selectedAccount.id || 0,
      transferAccountId: this.type === RecordType.TRANSFER ? this.selectedTransferAccount?.id : undefined,
      recordTime: this.recordTime > 0 ? this.recordTime : Date.now(),
      ledgerName: this.ledgerName,
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
    if (this.type === RecordType.TRANSFER) {
      this.categories = [];
      this.selectedCategory = null;
      return;
    }
    const categoryType: RecordType.EXPENSE | RecordType.INCOME =
      this.type === RecordType.INCOME ? RecordType.INCOME : RecordType.EXPENSE;
    this.categories = await this.categoryRepository.listByType(categoryType);
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
    this.type = record.type;
    if (record.type === RecordType.TRANSFER) {
      this.categories = [];
      this.selectedCategory = null;
    } else {
      await this.loadCategories();
    }
    this.amountText = `${record.amount}`;
    this.recordTime = record.recordTime;
    this.ledgerName = record.ledgerName;
    this.createTime = record.createTime;
    this.remark = record.remark;
    this.selectedCategory = this.categories.find((item: CategoryModel) => item.id === record.categoryId) || this.selectedCategory;
    this.selectedAccount = this.accounts.find((item: AccountModel) => item.id === record.accountId) || this.selectedAccount;
    this.selectedTransferAccount = record.transferAccountId
      ? this.accounts.find((item: AccountModel) => item.id === record.transferAccountId) || null
      : null;
  }
}
