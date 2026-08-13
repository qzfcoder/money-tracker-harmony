import { CategoryExpenseRank, MonthSummary, RecordRepository, TrendPoint } from '../repository/RecordRepository';
import { DateUtil } from '../utils/DateUtil';

export enum StatisticsPeriod {
  WEEK = 'week',
  MONTH = 'month',
  QUARTER = 'quarter',
  YEAR = 'year',
  CUSTOM = 'custom'
}

export class PeriodOption {
  label: string = '';
  value: StatisticsPeriod = StatisticsPeriod.MONTH;

  constructor(label: string, value: StatisticsPeriod) {
    this.label = label;
    this.value = value;
  }
}

export class StatisticsRange {
  startTime: number = 0;
  endTime: number = 0;
  useMonthBucket: boolean = false;

  constructor(startTime: number, endTime: number, useMonthBucket: boolean) {
    this.startTime = startTime;
    this.endTime = endTime;
    this.useMonthBucket = useMonthBucket;
  }
}

export class CategoryRankItem {
  categoryId: number = 0;
  categoryName: string = '';
  categoryColor: string = '#657A55';
  amount: number = 0;
  percent: number = 0;
  recordCount: number = 0;

  constructor(categoryId: number, categoryName: string, categoryColor: string, amount: number, percent: number, recordCount: number) {
    this.categoryId = categoryId;
    this.categoryName = categoryName;
    this.categoryColor = categoryColor;
    this.amount = amount;
    this.percent = percent;
    this.recordCount = recordCount;
  }
}

@Observed
export class StatisticsViewModel {
  private recordRepository: RecordRepository = new RecordRepository();

  periodOptions: PeriodOption[] = [
    new PeriodOption('周', StatisticsPeriod.WEEK),
    new PeriodOption('月', StatisticsPeriod.MONTH),
    new PeriodOption('季', StatisticsPeriod.QUARTER),
    new PeriodOption('年', StatisticsPeriod.YEAR),
    new PeriodOption('自定义', StatisticsPeriod.CUSTOM)
  ];

  period: StatisticsPeriod = StatisticsPeriod.MONTH;
  anchorTime: number = Date.now();
  customStartTime: number = DateUtil.addDays(DateUtil.startOfDay(), -29);
  customEndTime: number = DateUtil.addDays(DateUtil.startOfDay(), 1);
  rangeLabel: string = '';
  income: number = 0;
  expense: number = 0;
  balance: number = 0;
  categoryRanks: CategoryRankItem[] = [];
  trendPoints: TrendPoint[] = [];

  async refresh(): Promise<void> {
    const range = this.getRange();
    this.rangeLabel = DateUtil.rangeLabel(range.startTime, range.endTime);

    const summary: MonthSummary = await this.recordRepository.monthSummary(range.startTime, range.endTime);
    this.income = summary.income;
    this.expense = summary.expense;
    this.balance = summary.balance;

    const ranks = await this.recordRepository.categoryExpenseRanks(range.startTime, range.endTime);
    this.categoryRanks = ranks.map((item: CategoryExpenseRank) => {
      return new CategoryRankItem(
        item.categoryId,
        item.categoryName,
        item.categoryColor,
        item.amount,
        item.percent,
        item.recordCount
      );
    });

    const rawTrend = range.useMonthBucket
      ? await this.recordRepository.trendByMonth(range.startTime, range.endTime)
      : await this.recordRepository.trendByDay(range.startTime, range.endTime);
    this.trendPoints = this.fillTrend(range, rawTrend);
  }

  async setPeriod(period: StatisticsPeriod): Promise<void> {
    this.period = period;
    await this.refresh();
  }

  async movePrevious(): Promise<void> {
    if (this.period === StatisticsPeriod.WEEK) {
      this.anchorTime = DateUtil.addDays(this.anchorTime, -7);
    } else if (this.period === StatisticsPeriod.MONTH) {
      const date = new Date(this.anchorTime);
      this.anchorTime = new Date(date.getFullYear(), date.getMonth() - 1, 1).getTime();
    } else if (this.period === StatisticsPeriod.QUARTER) {
      const date = new Date(this.anchorTime);
      this.anchorTime = new Date(date.getFullYear(), date.getMonth() - 3, 1).getTime();
    } else if (this.period === StatisticsPeriod.YEAR) {
      const date = new Date(this.anchorTime);
      this.anchorTime = new Date(date.getFullYear() - 1, 0, 1).getTime();
    } else {
      const span = this.customEndTime - this.customStartTime;
      this.customStartTime -= span;
      this.customEndTime -= span;
    }
    await this.refresh();
  }

  async moveNext(): Promise<void> {
    if (this.period === StatisticsPeriod.WEEK) {
      this.anchorTime = DateUtil.addDays(this.anchorTime, 7);
    } else if (this.period === StatisticsPeriod.MONTH) {
      const date = new Date(this.anchorTime);
      this.anchorTime = new Date(date.getFullYear(), date.getMonth() + 1, 1).getTime();
    } else if (this.period === StatisticsPeriod.QUARTER) {
      const date = new Date(this.anchorTime);
      this.anchorTime = new Date(date.getFullYear(), date.getMonth() + 3, 1).getTime();
    } else if (this.period === StatisticsPeriod.YEAR) {
      const date = new Date(this.anchorTime);
      this.anchorTime = new Date(date.getFullYear() + 1, 0, 1).getTime();
    } else {
      const span = this.customEndTime - this.customStartTime;
      this.customStartTime += span;
      this.customEndTime += span;
    }
    await this.refresh();
  }

  async setCustomStart(timestamp: number): Promise<void> {
    this.period = StatisticsPeriod.CUSTOM;
    this.customStartTime = DateUtil.startOfDay(timestamp);
    if (this.customStartTime >= this.customEndTime) {
      this.customEndTime = DateUtil.addDays(this.customStartTime, 1);
    }
    await this.refresh();
  }

  async setCustomEnd(timestamp: number): Promise<void> {
    this.period = StatisticsPeriod.CUSTOM;
    this.customEndTime = DateUtil.addDays(DateUtil.startOfDay(timestamp), 1);
    if (this.customEndTime <= this.customStartTime) {
      this.customStartTime = DateUtil.addDays(this.customEndTime, -1);
    }
    await this.refresh();
  }

  async setCustomRange(startTimestamp: number, endTimestamp: number): Promise<void> {
    this.period = StatisticsPeriod.CUSTOM;
    this.customStartTime = DateUtil.startOfDay(startTimestamp);
    this.customEndTime = DateUtil.addDays(DateUtil.startOfDay(endTimestamp), 1);
    await this.refresh();
  }

  private getRange(): StatisticsRange {
    if (this.period === StatisticsPeriod.WEEK) {
      const start = DateUtil.startOfWeek(this.anchorTime);
      return new StatisticsRange(start, DateUtil.addDays(start, 7), false);
    }
    if (this.period === StatisticsPeriod.MONTH) {
      return new StatisticsRange(DateUtil.startOfMonth(this.anchorTime), DateUtil.startOfNextMonth(this.anchorTime), false);
    }
    if (this.period === StatisticsPeriod.QUARTER) {
      return new StatisticsRange(DateUtil.startOfQuarter(this.anchorTime), DateUtil.startOfNextQuarter(this.anchorTime), true);
    }
    if (this.period === StatisticsPeriod.YEAR) {
      return new StatisticsRange(DateUtil.startOfYear(this.anchorTime), DateUtil.startOfNextYear(this.anchorTime), true);
    }
    return new StatisticsRange(this.customStartTime, this.customEndTime, this.customEndTime - this.customStartTime > 92 * 24 * 60 * 60 * 1000);
  }

  private fillTrend(range: StatisticsRange, rawTrend: TrendPoint[]): TrendPoint[] {
    const valueMap = new Map<string, TrendPoint>();
    rawTrend.forEach((point: TrendPoint) => {
      valueMap.set(point.label, point);
    });

    const list: TrendPoint[] = [];
    if (range.useMonthBucket) {
      let cursor = new Date(range.startTime);
      const end = new Date(range.endTime);
      while (cursor.getTime() < end.getTime()) {
        const label = DateUtil.monthKey(cursor.getTime());
        const value = valueMap.get(label);
        list.push(value || new TrendPoint(label, 0, 0));
        cursor = new Date(cursor.getFullYear(), cursor.getMonth() + 1, 1);
      }
      return list;
    }

    let day = range.startTime;
    while (day < range.endTime) {
      const label = DateUtil.dayKey(day);
      const value = valueMap.get(label);
      list.push(value || new TrendPoint(label, 0, 0));
      day = DateUtil.addDays(day, 1);
    }
    return list;
  }
}
