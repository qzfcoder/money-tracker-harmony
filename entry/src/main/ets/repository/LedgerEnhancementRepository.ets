import preferences from '@ohos.data.preferences';
import { common } from '@kit.AbilityKit';

export class LedgerEnhancementData {
  ledgers: string[] = ['日常账本', '家庭账本', '旅行账本', '装修账本'];
  activeLedger: string = '日常账本';
  homeLedgerFilter: string = '';
  tags: string[] = ['报销', '旅行', '装修', '家庭', '宝宝'];
  defaultTags: string[] = [];
  savingName: string = '存钱目标';
  savingTarget: number = 0;
  savingSaved: number = 0;
  reimburseKeyword: string = '报销';
  anomalyThreshold: number = 500;
  creditBillDay: number = 1;
  creditRepayDay: number = 20;
}

export class LedgerEnhancementRepository {
  private static readonly FILE_NAME: string = 'money_tracker_enhancements';

  async load(context: common.Context): Promise<LedgerEnhancementData> {
    const store = await preferences.getPreferences(context, LedgerEnhancementRepository.FILE_NAME);
    const data = new LedgerEnhancementData();
    data.ledgers = this.parseList(store.getSync('ledgers', data.ledgers.join(',')) as string, data.ledgers);
    data.activeLedger = store.getSync('activeLedger', data.activeLedger) as string;
    if (data.ledgers.indexOf(data.activeLedger) < 0) {
      data.activeLedger = data.ledgers[0] || '日常账本';
    }
    data.homeLedgerFilter = (store.getSync('homeLedgerFilter', '') as string).trim();
    if (data.homeLedgerFilter.length > 0 && data.ledgers.indexOf(data.homeLedgerFilter) < 0) {
      data.homeLedgerFilter = '';
    }
    data.tags = this.parseList(store.getSync('tags', data.tags.join(',')) as string, data.tags);
    data.defaultTags = this.parseList(store.getSync('defaultTags', '') as string, []);
    data.savingName = store.getSync('savingName', data.savingName) as string;
    data.savingTarget = this.toNumber(store.getSync('savingTarget', data.savingTarget) as number | string, 0);
    data.savingSaved = this.toNumber(store.getSync('savingSaved', data.savingSaved) as number | string, 0);
    data.reimburseKeyword = store.getSync('reimburseKeyword', data.reimburseKeyword) as string;
    data.anomalyThreshold = this.toNumber(store.getSync('anomalyThreshold', data.anomalyThreshold) as number | string, 500);
    data.creditBillDay = this.toDay(store.getSync('creditBillDay', data.creditBillDay) as number | string, 1);
    data.creditRepayDay = this.toDay(store.getSync('creditRepayDay', data.creditRepayDay) as number | string, 20);
    return data;
  }

  async save(context: common.Context, data: LedgerEnhancementData): Promise<void> {
    const store = await preferences.getPreferences(context, LedgerEnhancementRepository.FILE_NAME);
    store.putSync('ledgers', this.uniqueList(data.ledgers).join(','));
    store.putSync('activeLedger', data.activeLedger.trim() || '日常账本');
    store.putSync('homeLedgerFilter', data.homeLedgerFilter.trim());
    store.putSync('tags', this.uniqueList(data.tags).join(','));
    store.putSync('defaultTags', this.uniqueList(data.defaultTags).join(','));
    store.putSync('savingName', data.savingName.trim() || '存钱目标');
    store.putSync('savingTarget', data.savingTarget);
    store.putSync('savingSaved', data.savingSaved);
    store.putSync('reimburseKeyword', data.reimburseKeyword.trim() || '报销');
    store.putSync('anomalyThreshold', data.anomalyThreshold);
    store.putSync('creditBillDay', this.toDay(data.creditBillDay, 1));
    store.putSync('creditRepayDay', this.toDay(data.creditRepayDay, 20));
    await store.flush();
  }

  async decorateRemark(context: common.Context, remark: string): Promise<string> {
    const data = await this.load(context);
    let next = remark.trim();
    for (const tag of data.defaultTags) {
      const normalized = tag.replace(/#/g, '').trim();
      if (normalized.length > 0 && !next.includes(`#${normalized}`)) {
        next = `${next}${next.length > 0 ? ' ' : ''}#${normalized}`;
      }
    }
    return next;
  }

  async getActiveLedger(context: common.Context): Promise<string> {
    const data = await this.load(context);
    return data.activeLedger.trim() || '日常账本';
  }

  async setActiveLedger(context: common.Context, ledgerName: string): Promise<void> {
    const normalized = ledgerName.trim() || '日常账本';
    const data = await this.load(context);
    if (data.ledgers.indexOf(normalized) < 0) {
      data.ledgers.push(normalized);
    }
    data.activeLedger = normalized;
    await this.save(context, data);
  }

  async getHomeLedgerFilter(context: common.Context): Promise<string> {
    const data = await this.load(context);
    return data.homeLedgerFilter.trim();
  }

  async setHomeLedgerFilter(context: common.Context, ledgerName: string): Promise<void> {
    const normalized = ledgerName.trim();
    const data = await this.load(context);
    if (normalized.length > 0 && data.ledgers.indexOf(normalized) < 0) {
      data.ledgers.push(normalized);
    }
    data.homeLedgerFilter = normalized;
    if (normalized.length > 0) {
      data.activeLedger = normalized;
    }
    await this.save(context, data);
  }

  private parseList(value: string, fallback: string[]): string[] {
    const list = value.split(/[，,]/)
      .map((item: string) => item.trim())
      .filter((item: string) => item.length > 0);
    const unique = this.uniqueList(list);
    return unique.length > 0 ? unique : fallback;
  }

  private uniqueList(list: string[]): string[] {
    const result: string[] = [];
    list.forEach((item: string) => {
      const normalized = item.replace(/#/g, '').trim();
      if (normalized.length > 0 && result.indexOf(normalized) < 0) {
        result.push(normalized);
      }
    });
    return result;
  }

  private toNumber(value: number | string, fallback: number): number {
    const parsed = typeof value === 'number' ? value : Number(value);
    if (Number.isNaN(parsed) || parsed < 0) {
      return fallback;
    }
    return Math.round(parsed * 100) / 100;
  }

  private toDay(value: number | string, fallback: number): number {
    const parsed = typeof value === 'number' ? value : Number(value);
    if (Number.isNaN(parsed)) {
      return fallback;
    }
    return Math.min(31, Math.max(1, Math.round(parsed)));
  }
}
