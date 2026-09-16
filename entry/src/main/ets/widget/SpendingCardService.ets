import preferences from '@ohos.data.preferences';
import { formBindingData, formProvider } from '@kit.FormKit';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppDatabase } from '../database/AppDatabase';
import { RecordRepository } from '../repository/RecordRepository';
import { SettingsRepository } from '../repository/SettingsRepository';
import { DateUtil } from '../utils/DateUtil';
import { NumberUtil } from '../utils/NumberUtil';

const FORM_PREF_NAME = 'money_tracker_spending_card';
const FORM_IDS_KEY = 'formIds';
const CARD_APP_TITLE_KEY = 'cardAppTitle';
const CARD_TODAY_EXPENSE_KEY = 'cardTodayExpense';
const CARD_MONTH_EXPENSE_KEY = 'cardMonthExpense';
const CARD_MONTH_INCOME_KEY = 'cardMonthIncome';
const CARD_BALANCE_KEY = 'cardBalance';
const CARD_UPDATED_AT_KEY = 'cardUpdatedAt';
const CARD_STATUS_KEY = 'cardStatus';
const FORM_ABILITY_NAME = 'SpendingFormAbility';
const FORM_NAME = 'SpendingCard';
const DOMAIN = 0x0001;

export class SpendingCardData {
  appTitle: string = '一页账';
  todayExpenseText: string = '¥0';
  monthExpenseText: string = '¥0';
  monthIncomeText: string = '¥0';
  balanceText: string = '¥0';
  updatedAtText: string = '刚刚更新';
  statusText: string = '记录之后自动汇总';
}

export class SpendingCardService {
  private static refreshQueue: Promise<void> = Promise.resolve();

  static placeholderData(): SpendingCardData {
    const data = new SpendingCardData();
    data.updatedAtText = '正在同步';
    return data;
  }

  static bindingData(data: SpendingCardData): formBindingData.FormBindingData {
    return formBindingData.createFormBindingData({
      appTitle: data.appTitle,
      todayExpenseText: data.todayExpenseText,
      monthExpenseText: data.monthExpenseText,
      monthIncomeText: data.monthIncomeText,
      balanceText: data.balanceText,
      updatedAtText: data.updatedAtText,
      statusText: data.statusText
    });
  }

  // onAddForm is synchronous, so return the last successful snapshot instead of a blank card.
  static initialData(context: common.Context): SpendingCardData {
    const data = SpendingCardService.placeholderData();
    try {
      const store = preferences.getPreferencesSync(
        SpendingCardService.applicationContext(context),
        { name: FORM_PREF_NAME }
      );
      data.appTitle = store.getSync(CARD_APP_TITLE_KEY, data.appTitle) as string;
      data.todayExpenseText = store.getSync(CARD_TODAY_EXPENSE_KEY, data.todayExpenseText) as string;
      data.monthExpenseText = store.getSync(CARD_MONTH_EXPENSE_KEY, data.monthExpenseText) as string;
      data.monthIncomeText = store.getSync(CARD_MONTH_INCOME_KEY, data.monthIncomeText) as string;
      data.balanceText = store.getSync(CARD_BALANCE_KEY, data.balanceText) as string;
      data.updatedAtText = store.getSync(CARD_UPDATED_AT_KEY, data.updatedAtText) as string;
      data.statusText = store.getSync(CARD_STATUS_KEY, data.statusText) as string;
    } catch (error) {
      hilog.warn(DOMAIN, 'SpendingCardService', `load initial card data failed: ${JSON.stringify(error)}`);
    }
    return data;
  }

  static async addFormId(context: common.Context, formId: string): Promise<void> {
    if (!formId) {
      hilog.warn(DOMAIN, 'SpendingCardService', 'skip empty form id from onAddForm');
      return;
    }
    const appContext = SpendingCardService.applicationContext(context);
    const ids = await SpendingCardService.loadFormIds(appContext);
    if (ids.indexOf(formId) < 0) {
      ids.push(formId);
      await SpendingCardService.saveFormIds(appContext, ids);
    }
    hilog.info(DOMAIN, 'SpendingCardService', `registered form ${formId}`);
  }

  static async removeFormId(context: common.Context, formId: string): Promise<void> {
    const appContext = SpendingCardService.applicationContext(context);
    const ids = await SpendingCardService.loadFormIds(appContext);
    const nextIds = ids.filter((item: string) => item !== formId);
    await SpendingCardService.saveFormIds(appContext, nextIds);
  }

  static async refreshKnownForms(context: common.Context): Promise<void> {
    const appContext = SpendingCardService.applicationContext(context);
    const data = await SpendingCardService.buildData(appContext);
    const ids = await SpendingCardService.resolveFormIds(appContext);
    hilog.info(DOMAIN, 'SpendingCardService', `refreshing ${ids.length} running form(s)`);
    for (const formId of ids) {
      try {
        await formProvider.updateForm(formId, SpendingCardService.bindingData(data));
        hilog.info(DOMAIN, 'SpendingCardService', `form ${formId} updated`);
      } catch (error) {
        hilog.warn(DOMAIN, 'SpendingCardService', `refresh form ${formId} failed: ${JSON.stringify(error)}`);
      }
    }
  }

  static refreshAllForms(context: common.Context): Promise<void> {
    const task = SpendingCardService.refreshQueue.then(() => {
      return SpendingCardService.refreshAllFormsOnce(context);
    });
    SpendingCardService.refreshQueue = task.catch((error: Error) => {
      hilog.warn(DOMAIN, 'SpendingCardService', `queued refresh failed: ${JSON.stringify(error)}`);
    });
    return task;
  }

  private static async refreshAllFormsOnce(context: common.Context): Promise<void> {
    await SpendingCardService.refreshKnownForms(context);
  }

  private static async buildData(context: common.Context): Promise<SpendingCardData> {
    const appContext = SpendingCardService.applicationContext(context);
    await AppDatabase.getInstance().init(appContext);
    const repository = new RecordRepository();
    const settingsRepository = new SettingsRepository();
    const now = Date.now();
    const todaySummary = await repository.monthSummary(DateUtil.startOfDay(now), DateUtil.addDays(DateUtil.startOfDay(now), 1));
    const monthSummary = await repository.monthSummary(DateUtil.startOfMonth(now), DateUtil.startOfNextMonth(now));
    const monthRecordCount = await repository.recordCount(DateUtil.startOfMonth(now), DateUtil.startOfNextMonth(now));
    const currency = (await settingsRepository.load(appContext)).currencySymbol;

    hilog.info(DOMAIN, 'SpendingCardService',
      `card data records=${monthRecordCount}, todayExpense=${todaySummary.expense}, ` +
      `monthIncome=${monthSummary.income}, monthExpense=${monthSummary.expense}, ` +
      `balance=${monthSummary.balance}`);

    const data = new SpendingCardData();
    data.todayExpenseText = NumberUtil.compactMoney(todaySummary.expense, currency);
    data.monthExpenseText = NumberUtil.compactMoney(monthSummary.expense, currency);
    data.monthIncomeText = NumberUtil.compactMoney(monthSummary.income, currency);
    data.balanceText = NumberUtil.compactMoney(monthSummary.balance, currency);
    data.updatedAtText = `${DateUtil.timeLabel(now)} 更新`;
    data.statusText = monthSummary.expense > 0 || monthSummary.income > 0 ? '本月数据已同步' : '还没有本月收支';
    await SpendingCardService.saveCachedData(appContext, data);
    return data;
  }

  private static async saveCachedData(context: common.Context, data: SpendingCardData): Promise<void> {
    const store = await preferences.getPreferences(SpendingCardService.applicationContext(context), FORM_PREF_NAME);
    store.putSync(CARD_APP_TITLE_KEY, data.appTitle);
    store.putSync(CARD_TODAY_EXPENSE_KEY, data.todayExpenseText);
    store.putSync(CARD_MONTH_EXPENSE_KEY, data.monthExpenseText);
    store.putSync(CARD_MONTH_INCOME_KEY, data.monthIncomeText);
    store.putSync(CARD_BALANCE_KEY, data.balanceText);
    store.putSync(CARD_UPDATED_AT_KEY, data.updatedAtText);
    store.putSync(CARD_STATUS_KEY, data.statusText);
    await store.flush();
  }

  private static applicationContext(context: common.Context): common.Context {
    return context.getApplicationContext();
  }

  private static async loadFormIds(context: common.Context): Promise<string[]> {
    const store = await preferences.getPreferences(context, FORM_PREF_NAME);
    const value = store.getSync(FORM_IDS_KEY, '') as string;
    if (!value) {
      return [];
    }
    return value.split(',').filter((item: string) => item.length > 0);
  }

  /**
   * The form callback is not guaranteed to be the only source of the instance ID.
   * Reconcile the local cache with the system's running form list before updating.
   */
  private static async resolveFormIds(context: common.Context): Promise<string[]> {
    const cachedIds = await SpendingCardService.loadFormIds(context);
    try {
      const runningForms = await formProvider.getPublishedRunningFormInfos();
      const runningIds = runningForms
        .filter((item) => item.abilityName === FORM_ABILITY_NAME && item.formName === FORM_NAME)
        .map((item) => item.formId)
        .filter((item: string, index: number, list: string[]) => item.length > 0 && list.indexOf(item) === index);
      await SpendingCardService.saveFormIds(context, runningIds);
      hilog.info(DOMAIN, 'SpendingCardService', `system reports ${runningIds.length} running card(s)`);
      return runningIds;
    } catch (error) {
      // Keep the cache as a fallback if the form service is temporarily unavailable.
      hilog.warn(DOMAIN, 'SpendingCardService', `query running forms failed, use cache: ${JSON.stringify(error)}`);
      return cachedIds;
    }
  }

  private static async saveFormIds(context: common.Context, ids: string[]): Promise<void> {
    const store = await preferences.getPreferences(context, FORM_PREF_NAME);
    store.putSync(FORM_IDS_KEY, ids.join(','));
    await store.flush();
  }
}
