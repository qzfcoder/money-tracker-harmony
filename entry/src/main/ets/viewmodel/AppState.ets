import { AccountModel } from '../model/Account';
import { BudgetModel } from '../model/Budget';
import { RecordListItem } from '../model/Record';
import { AccountRepository } from '../repository/AccountRepository';
import { AutoBookkeepingRepository } from '../repository/AutoBookkeepingRepository';
import { BudgetRepository } from '../repository/BudgetRepository';
import { RecordRepository } from '../repository/RecordRepository';
import { FeatureFlags } from '../constants/FeatureFlags';
import { DateUtil } from '../utils/DateUtil';

@Observed
export class AppState {
  private static instance: AppState | null = null;
  private recordRepository: RecordRepository = new RecordRepository();
  private accountRepository: AccountRepository = new AccountRepository();
  private budgetRepository: BudgetRepository = new BudgetRepository();

  monthIncome: number = 0;
  monthExpense: number = 0;
  monthBalance: number = 0;
  todayIncome: number = 0;
  todayExpense: number = 0;
  todayBalance: number = 0;
  todayRecordCount: number = 0;
  monthBudget: number = 0;
  monthBudgetRemaining: number = 0;
  monthBudgetProgress: number = 0;
  totalAssets: number = 0;
  pendingAutoBillCount: number = 0;
  ledgerFilter: string = '';
  recordList: RecordListItem[] = [];
  accountList: AccountModel[] = [];
  lastUpdatedRecord: RecordListItem | null = null;

  static getInstance(): AppState {
    if (!AppState.instance) {
      AppState.instance = new AppState();
    }
    return AppState.instance;
  }

  async refreshAll(): Promise<void> {
    await Promise.all([
      this.refreshTodaySummary(),
      this.refreshMonthSummary(),
      this.refreshRecords(),
      this.refreshAccountList(),
      this.refreshPendingAutoBills(),
      this.refreshBudgetSummary()
    ]);
  }

  async refreshAfterRecordChange(): Promise<void> {
    await Promise.all([
      this.refreshTodaySummary(),
      this.refreshMonthSummary(),
      this.refreshRecords(),
      this.refreshAccountList(),
      this.refreshBudgetSummary()
    ]);
  }

  setLedgerFilter(ledgerName: string): void {
    this.ledgerFilter = ledgerName.trim();
  }

  applyRecordUpdate(record: RecordListItem): void {
    this.lastUpdatedRecord = record;
    const index = this.recordList.findIndex((item: RecordListItem) => item.id === record.id);
    if (this.ledgerFilter.length > 0 && record.ledgerName !== this.ledgerFilter) {
      if (index >= 0) {
        const nextList = this.recordList.slice();
        nextList.splice(index, 1);
        this.recordList = nextList;
      }
      return;
    }
    if (index < 0) {
      return;
    }
    const nextList = this.recordList.slice();
    nextList[index] = record;
    this.recordList = nextList;
  }

  async refreshTodaySummary(): Promise<void> {
    const start = DateUtil.startOfDay();
    const end = DateUtil.addDays(start, 1);
    const summary = await this.recordRepository.monthSummary(start, end, this.ledgerFilter);
    this.todayIncome = summary.income;
    this.todayExpense = summary.expense;
    this.todayBalance = summary.balance;
    this.todayRecordCount = await this.recordRepository.recordCount(start, end, this.ledgerFilter);
  }

  async refreshMonthSummary(): Promise<void> {
    const summary = await this.recordRepository.monthSummary(
      DateUtil.startOfMonth(), DateUtil.startOfNextMonth(), this.ledgerFilter
    );
    this.monthIncome = summary.income;
    this.monthExpense = summary.expense;
    this.monthBalance = summary.balance;
  }

  async refreshBudgetSummary(): Promise<void> {
    const budgets = await this.budgetRepository.listByMonth(DateUtil.monthKey());
    const totalBudget = budgets.find((item: BudgetModel) => item.categoryId === 0);
    const categoryBudgetTotal = budgets.reduce((sum: number, item: BudgetModel) => {
      return item.categoryId > 0 ? sum + item.amount : sum;
    }, 0);
    const summary = await this.recordRepository.monthSummary(DateUtil.startOfMonth(), DateUtil.startOfNextMonth());
    const currentExpense = summary.expense;
    this.monthBudget = totalBudget && totalBudget.amount > 0 ? totalBudget.amount : categoryBudgetTotal;
    this.monthBudgetRemaining = Math.max(0, this.monthBudget - currentExpense);
    this.monthBudgetProgress = this.monthBudget > 0 ? Math.min(100, Math.round(currentExpense / this.monthBudget * 100)) : 0;
  }

  async refreshRecords(): Promise<void> {
    this.recordList = this.ledgerFilter.length > 0
      ? await this.recordRepository.listRecentByLedger(this.ledgerFilter, 30, 0)
      : await this.recordRepository.listRecent(30, 0);
  }

  async refreshAccountList(): Promise<void> {
    this.accountList = await this.accountRepository.list();
    this.totalAssets = this.accountList.reduce((sum: number, account: AccountModel) => {
      return sum + (account.isLiability ? -account.balance : account.balance);
    }, 0);
  }

  async refreshPendingAutoBills(): Promise<void> {
    if (!FeatureFlags.AUTO_BOOKKEEPING_VISIBLE) {
      this.pendingAutoBillCount = 0;
      return;
    }
    this.pendingAutoBillCount = await new AutoBookkeepingRepository().countPending();
  }
}
