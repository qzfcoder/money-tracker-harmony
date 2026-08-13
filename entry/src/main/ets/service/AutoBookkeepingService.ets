import { common } from '@kit.AbilityKit';
import { AccountModel, AccountType } from '../model/Account';
import { AutoBillModel, AutoBillStatus, AutoCaptureSource, AutoNotificationPayload, AutoParseResult, AutoRuleModel, AutoRuleType } from '../model/AutoBookkeeping';
import { CategoryModel } from '../model/Category';
import { RecordType } from '../model/Record';
import { AccountRepository } from '../repository/AccountRepository';
import { AutoBookkeepingRepository } from '../repository/AutoBookkeepingRepository';
import { CategoryRepository } from '../repository/CategoryRepository';
import { SettingsRepository } from '../repository/SettingsRepository';
import { AutoBookkeepingSettings } from '../repository/SettingsRepository';

interface AutoCategoryMatch {
  categoryId: number;
  categoryName: string;
  categoryColor: string;
  matchedRule: string;
}

interface KeywordCategoryGroup {
  keywords: string[];
  name: string;
}

interface AmountCandidate {
  amount: number;
  score: number;
  index: number;
}

export class AutoBookkeepingService {
  private autoRepository: AutoBookkeepingRepository = new AutoBookkeepingRepository();
  private categoryRepository: CategoryRepository = new CategoryRepository();
  private accountRepository: AccountRepository = new AccountRepository();
  private settingsRepository: SettingsRepository = new SettingsRepository();
  private context: common.Context;

  constructor(context: common.Context) {
    this.context = context;
  }

  static create(context: common.Context): AutoBookkeepingService {
    return new AutoBookkeepingService(context);
  }

  async handleNotification(payload: AutoNotificationPayload): Promise<AutoParseResult> {
    const settings = await this.loadSettings();
    if (!settings.autoBookkeepingEnabled) {
      return { matched: false, reason: 'auto-disabled' };
    }
    if (payload.source === AutoCaptureSource.NOTIFICATION && !settings.autoNotificationEnabled) {
      return { matched: false, reason: 'notification-disabled' };
    }
    if (payload.source === AutoCaptureSource.SMS && !settings.autoSmsEnabled) {
      return { matched: false, reason: 'sms-disabled' };
    }
    return await this.capturePayload(payload, settings);
  }

  async preview(rawText: string): Promise<AutoParseResult> {
    const settings = await this.loadSettings();
    return await this.capturePayload({
      source: AutoCaptureSource.MANUAL,
      bundleName: '',
      appName: '手动测试',
      title: '',
      content: rawText,
      rawText,
      eventTime: Date.now()
    }, settings, false);
  }

  async captureManualText(rawText: string): Promise<AutoParseResult> {
    const settings = await this.loadSettings();
    return await this.capturePayload({
      source: AutoCaptureSource.MANUAL,
      bundleName: '',
      appName: '手动测试',
      title: '手动测试',
      content: rawText,
      rawText,
      eventTime: Date.now()
    }, settings, true);
  }

  async captureOcrText(rawText: string, eventTime: number = Date.now()): Promise<AutoParseResult> {
    const settings = await this.loadSettings();
    return await this.capturePayload({
      source: AutoCaptureSource.MANUAL,
      bundleName: '',
      appName: '屏幕OCR识别',
      title: '截图识别账单',
      content: rawText,
      rawText,
      eventTime
    }, settings, true);
  }

  async captureImportedText(rawText: string, eventTime: number, title: string): Promise<AutoParseResult> {
    const settings = await this.loadSettings();
    return await this.capturePayload({
      source: AutoCaptureSource.MANUAL,
      bundleName: 'com.eg.android.AlipayGphone',
      appName: '支付宝账单',
      title: title || '支付宝账单导入',
      content: rawText,
      rawText,
      eventTime: eventTime > 0 ? eventTime : Date.now()
    }, settings, true);
  }

  async listPending(limit: number = 50, offset: number = 0): Promise<AutoBillModel[]> {
    return await this.autoRepository.listPending(limit, offset);
  }

  async countPending(): Promise<number> {
    return await this.autoRepository.countPending();
  }

  async listRules(): Promise<AutoRuleModel[]> {
    return await this.autoRepository.listRules();
  }

  async saveRule(rule: AutoRuleModel): Promise<number> {
    return await this.autoRepository.saveRule(rule);
  }

  async deleteRule(id: number): Promise<void> {
    await this.autoRepository.deleteRuleById(id);
  }

  async confirmPending(id: number): Promise<void> {
    await this.autoRepository.confirmPending(id);
  }

  async updatePending(bill: AutoBillModel): Promise<void> {
    await this.autoRepository.updatePending(bill);
  }

  async discardPending(id: number): Promise<void> {
    await this.autoRepository.discardPending(id);
  }

  async clearCache(): Promise<void> {
    await this.autoRepository.clearPendingCache();
  }

  async seedPreview(payload: AutoNotificationPayload): Promise<AutoParseResult> {
    const settings = await this.loadSettings();
    return await this.capturePayload(payload, settings, false);
  }

  private async capturePayload(payload: AutoNotificationPayload, settings: AutoBookkeepingSettings, persist: boolean = true): Promise<AutoParseResult> {
    const rules = await this.listRules();
    const categories = await this.categoryRepository.listAll();
    const accounts = await this.accountRepository.list();
    const bill = this.parsePayload(payload, rules, categories, accounts, settings);
    if (!bill) {
      return { matched: false, reason: 'parse-failed' };
    }
    if (persist) {
      const id = await this.autoRepository.savePending(bill);
      bill.id = id;
    }
    return { matched: true, reason: bill.matchedRule || 'parsed', bill };
  }

  private parsePayload(
    payload: AutoNotificationPayload,
    rules: AutoRuleModel[],
    categories: CategoryModel[],
    accounts: AccountModel[],
    settings: AutoBookkeepingSettings
  ): AutoBillModel | null {
    const normalizedText = this.normalizeText([payload.title, payload.content, payload.rawText, payload.appName, payload.bundleName].join(' '));
    if (!normalizedText) {
      return null;
    }
    if (this.isBlacklisted(normalizedText, rules)) {
      return null;
    }

    const amount = this.extractAmount(normalizedText);
    if (amount <= 0) {
      return null;
    }

    const type = this.resolveType(normalizedText, payload);
    const categoryMatch = this.resolveCategory(normalizedText, type, rules, categories);
    const account = this.resolveAccount(payload, normalizedText, accounts, settings.autoDefaultAccountId);
    const accountMatched = typeof account.id === 'number' && account.id > 0;
    const confidence = this.buildConfidence(normalizedText, categoryMatch.matchedRule, accountMatched);
    const now = payload.eventTime > 0 ? payload.eventTime : Date.now();

    return {
      source: payload.source,
      bundleName: payload.bundleName,
      appName: payload.appName,
      title: payload.title,
      content: payload.content,
      rawText: payload.rawText,
      amount,
      type,
      categoryId: categoryMatch.categoryId,
      accountId: account.id || 0,
      recordTime: now,
      remark: this.buildRemark(payload, normalizedText, categoryMatch.categoryName),
      confidence,
      matchedRule: categoryMatch.matchedRule,
      status: AutoBillStatus.PENDING,
      createTime: now,
      updateTime: now,
      categoryName: categoryMatch.categoryName,
      accountName: account.name,
      categoryColor: categoryMatch.categoryColor
    };
  }

  private buildRemark(payload: AutoNotificationPayload, text: string, categoryName: string): string {
    const merchant = this.extractMerchant(text);
    if (merchant.length > 0) {
      return merchant.substring(0, 50);
    }
    const headline = payload.title.trim();
    if (headline.length > 0) {
      return headline.substring(0, 50);
    }
    if (categoryName.length > 0) {
      return `${categoryName}自动识别`;
    }
    return '自动识别账单';
  }

  private buildConfidence(text: string, matchedRule: string, accountMatched: boolean): number {
    let score = 0.55;
    if (matchedRule.length > 0) {
      score += 0.18;
    }
    if (this.extractAmount(text) > 0) {
      score += 0.1;
    }
    if (accountMatched) {
      score += 0.08;
    }
    return Math.min(0.99, Math.round(score * 100) / 100);
  }

  private resolveType(text: string, payload: AutoNotificationPayload): RecordType.EXPENSE | RecordType.INCOME {
    const incomeKeywords: string[] = ['收入', '入账', '到账', '收款到账', '收款', '转入', '工资', '奖金', '退款', '退回', '报销', '返现'];
    const expenseKeywords: string[] = ['支出', '消费', '付款成功', '支付成功', '付款', '支付', '扣款', '扣费', '转出', '花费', '买单', '已扣'];
    const incomeIndex = this.firstKeywordIndex(text, incomeKeywords);
    const expenseIndex = this.firstKeywordIndex(text, expenseKeywords);
    if (incomeIndex >= 0 && (expenseIndex < 0 || incomeIndex < expenseIndex)) {
      return RecordType.INCOME;
    }
    if (expenseIndex >= 0) {
      return RecordType.EXPENSE;
    }
    if (this.includesAny(this.normalizeText(`${payload.appName} ${payload.bundleName}`), ['微信', '支付宝'])) {
      return text.includes('收款') || text.includes('到账') ? RecordType.INCOME : RecordType.EXPENSE;
    }
    return text.includes('收款') || text.includes('到账') ? RecordType.INCOME : RecordType.EXPENSE;
  }

  private resolveCategory(
    text: string,
    type: RecordType.EXPENSE | RecordType.INCOME,
    rules: AutoRuleModel[],
    categories: CategoryModel[]
  ): AutoCategoryMatch {
    const orderedRules = rules.filter((rule: AutoRuleModel) => rule.enabled && rule.ruleType === AutoRuleType.CATEGORY && rule.recordType === type);
    for (const rule of orderedRules) {
      if (this.ruleMatches(rule.keyword, text)) {
        const category = categories.find((item: CategoryModel) => item.id === rule.categoryId);
        if (category) {
          return {
            categoryId: category.id || 0,
            categoryName: category.name,
            categoryColor: category.color,
            matchedRule: rule.keyword
          };
        }
      }
    }

    const fallback = this.resolveFallbackCategory(text, type, categories);
    return fallback;
  }

  private resolveFallbackCategory(
    text: string,
    type: RecordType.EXPENSE | RecordType.INCOME,
    categories: CategoryModel[]
  ): AutoCategoryMatch {
    const expenseKeywords: KeywordCategoryGroup[] = [
      { keywords: ['餐饮', '奶茶', '茶饮', '外卖', '咖啡', '饭店', '餐厅', '食堂', '小吃', '美团', '饿了么', '肯德基', '麦当劳', '瑞幸', '星巴克'], name: '餐饮' },
      { keywords: ['地铁', '打车', '公交', '停车', '加油', '火车', '高铁', '车票', '滴滴', '高德打车', '出租车'], name: '交通' },
      { keywords: ['购物', '淘宝', '天猫', '京东', '拼多多', '抖音商城', '超市', '商场', '网购', '便利店'], name: '购物' },
      { keywords: ['房租', '物业', '水电', '住房', '宽带'], name: '住房' },
      { keywords: ['电话', '话费', '流量', '通讯'], name: '通讯' },
      { keywords: ['医院', '药店', '医疗', '挂号'], name: '医疗' },
      { keywords: ['电影', '娱乐', 'KTV', '游戏', '演出'], name: '娱乐' },
      { keywords: ['学习', '书籍', '课程', '培训'], name: '学习' },
      { keywords: ['运动', '健身', '游泳'], name: '运动' },
      { keywords: ['礼物', '人情', '红包'], name: '人情' },
      { keywords: ['旅行', '酒店', '机票'], name: '旅行' },
      { keywords: ['宠物'], name: '宠物' },
      { keywords: ['手机', '电脑', '数码'], name: '数码' }
    ];
    const incomeKeywords: KeywordCategoryGroup[] = [
      { keywords: ['工资', '薪资', '发薪'], name: '工资' },
      { keywords: ['奖金', '绩效', '补贴'], name: '奖金' },
      { keywords: ['报销', '退款'], name: '报销' },
      { keywords: ['兼职', '稿费', '返现', '分红'], name: '兼职' }
    ];
    const pool = type === RecordType.EXPENSE ? expenseKeywords : incomeKeywords;
    for (const item of pool) {
      if (this.includesAny(text, item.keywords)) {
        const category = categories.find((entry: CategoryModel) => entry.name === item.name && entry.type === type);
        if (category) {
          return {
            categoryId: category.id || 0,
            categoryName: category.name,
            categoryColor: category.color,
            matchedRule: item.keywords[0]
          };
        }
      }
    }
    const fallback = categories.find((entry: CategoryModel) => entry.type === type) || categories[0];
    if (fallback) {
      return {
        categoryId: fallback.id || 0,
        categoryName: fallback.name,
        categoryColor: fallback.color,
        matchedRule: fallback.name
      };
    }
    return {
      categoryId: 0,
      categoryName: '',
      categoryColor: '#4E7FF2',
      matchedRule: ''
    };
  }

  private resolveAccount(payload: AutoNotificationPayload, text: string, accounts: AccountModel[], defaultAccountId: number): AccountModel {
    const sourceText = this.normalizeText(`${payload.appName} ${payload.bundleName} ${text}`);
    const directKeywords: string[] = ['微信支付', '微信', 'weixin', 'wechat', '支付宝', 'alipay', '银行卡', 'bank', '银行'];
    for (const keyword of directKeywords) {
      const normalizedKeyword = this.normalizeText(keyword);
      const account = accounts.find((item: AccountModel) => {
        const accountName = this.normalizeText(item.name);
        return sourceText.includes(accountName) || accountName.includes(normalizedKeyword) || normalizedKeyword.includes(accountName);
      });
      if (account) {
        return account;
      }
    }
    if (defaultAccountId > 0) {
      const selected = accounts.find((item: AccountModel) => item.id === defaultAccountId);
      if (selected) {
        return selected;
      }
    }
    if (accounts.length > 0) {
      return accounts[0];
    }
    return {
      name: '默认账户',
      type: AccountType.CASH,
      balance: 0,
      initialBalance: 0,
      icon: 'cash',
      color: '#4E7FF2',
      isLiability: false,
      sortOrder: 1,
      createTime: Date.now()
    };
  }

  private isBlacklisted(text: string, rules: AutoRuleModel[]): boolean {
    for (const rule of rules) {
      if (rule.enabled && rule.ruleType === AutoRuleType.BLACKLIST && this.ruleMatches(rule.keyword, text)) {
        return true;
      }
    }
    return false;
  }

  private ruleMatches(keyword: string, text: string): boolean {
    const parts = this.splitKeywords(keyword);
    for (const part of parts) {
      if (part.length > 0 && text.includes(this.normalizeText(part))) {
        return true;
      }
    }
    return false;
  }

  private splitKeywords(keyword: string): string[] {
    return keyword.split('|').map((item: string) => item.trim()).filter((item: string) => item.length > 0);
  }

  private extractAmount(text: string): number {
    const candidates: AmountCandidate[] = [];
    this.collectAmountCandidates(text, /(?:订单金额|支付金额|交易金额|收款金额|实付|实收|金额)(?:¥|￥|人民币)?([0-9]+(?:\.[0-9]{1,2})?)/g, 9, candidates);
    this.collectAmountCandidates(text, /(?:消费|支出|付款|支付|扣款|扣费|转出|花费|买单|收入|入账|到账|收款|转入|退款|退回|报销).{0,12}?(?:¥|￥|人民币)?([0-9]+(?:\.[0-9]{1,2})?)/g, 8, candidates);
    this.collectAmountCandidates(text, /(?:¥|￥|人民币)([0-9]+(?:\.[0-9]{1,2})?)/g, 6, candidates);
    this.collectAmountCandidates(text, /([0-9]+(?:\.[0-9]{1,2})?)(?:元|块|人民币)/g, 5, candidates);
    const valid = candidates.filter((item: AmountCandidate) => item.amount > 0 && item.amount < 1000000);
    if (valid.length === 0) {
      return 0;
    }
    valid.sort((left: AmountCandidate, right: AmountCandidate) => {
      if (right.score !== left.score) {
        return right.score - left.score;
      }
      return left.index - right.index;
    });
    return Math.round(valid[0].amount * 100) / 100;
  }

  private collectAmountCandidates(text: string, pattern: RegExp, score: number, candidates: AmountCandidate[]): void {
    let match: RegExpExecArray | null = pattern.exec(text);
    while (match) {
      const amount = Number(match[1]);
      if (amount > 0) {
        candidates.push({ amount, score, index: match.index });
      }
      match = pattern.exec(text);
    }
  }

  private extractMerchant(text: string): string {
    const patterns: RegExp[] = [
      /(?:商户|商家|交易对象|收款方|付款给|向)([^，。；;,.]{2,20})/,
      /(?:商品说明|商品|备注)([^，。；;,.]{2,24})/
    ];
    for (const pattern of patterns) {
      const match = pattern.exec(text);
      if (match && match[1]) {
        return match[1].replace(/成功|付款|支付|消费|收款/g, '').trim();
      }
    }
    return '';
  }

  private firstKeywordIndex(text: string, keywords: string[]): number {
    let result = -1;
    for (const keyword of keywords) {
      const index = text.indexOf(this.normalizeText(keyword));
      if (index >= 0 && (result < 0 || index < result)) {
        result = index;
      }
    }
    return result;
  }

  private includesAny(text: string, keywords: string[]): boolean {
    for (const keyword of keywords) {
      if (text.includes(this.normalizeText(keyword))) {
        return true;
      }
    }
    return false;
  }

  private normalizeText(text: string): string {
    let value = `${text || ''}`.toLowerCase().replace(/\s+/g, '').replace(/[：:]/g, '');
    value = value.replace(/([0-9])[，,。．·•](?=[0-9]{1,2}(?:元|块|人民币|¥|￥|，|；|;|$))/g, '$1.');
    return value.replace(/[，。！？、,;；]/g, '，');
  }

  private async loadSettings(): Promise<AutoBookkeepingSettings> {
    const settings = await this.settingsRepository.load(this.context);
    return settings;
  }
}
