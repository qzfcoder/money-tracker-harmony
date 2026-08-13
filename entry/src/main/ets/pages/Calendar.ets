import { router } from '@kit.ArkUI';
import { AppColors, AppRadius, AppSpace, Breakpoints, LayoutSizes } from '../constants/DesignSystem';
import { ROUTES } from '../constants/RouteConstants';
import { FeatureFlags } from '../constants/FeatureFlags';
import { RecordListItem, RecordType } from '../model/Record';
import { DailyCashflow, RecordRepository } from '../repository/RecordRepository';
import { DateUtil } from '../utils/DateUtil';
import { NumberUtil } from '../utils/NumberUtil';
import { AppDatabase } from '../database/AppDatabase';
import { ToastUtil } from '../utils/ToastUtil';

class CalendarDayItem {
  timestamp: number = 0;
  day: number = 0;
  currentMonth: boolean = false;
  today: boolean = false;
  income: number = 0;
  expense: number = 0;
}

@Entry
@Component
struct CalendarPage {
  private repository: RecordRepository = new RecordRepository();

  @State viewportWidth: number = 0;
  @State monthTime: number = DateUtil.startOfMonth();
  @State selectedTime: number = DateUtil.startOfDay();
  @State dailyCashflow: DailyCashflow[] = [];
  @State selectedRecords: RecordListItem[] = [];
  @State monthIncome: number = 0;
  @State monthExpense: number = 0;
  @State monthBalance: number = 0;
  @State selectedIncome: number = 0;
  @State selectedExpense: number = 0;

  aboutToAppear(): void {
    this.loadMonth();
  }

  onPageShow(): void {
    this.loadMonth();
  }

  build() {
    Column() {
      this.Header()
      Scroll() {
        Column({ space: this.isNarrow() ? 10 : 16 }) {
          this.MonthToolbar()
          this.MonthOverview()
          this.CalendarPanel()
          this.DayDetail()
        }
        .width('100%')
        .constraintSize({ maxWidth: LayoutSizes.CONTENT_COMPACT })
        .alignSelf(ItemAlign.Center)
        .padding({ left: AppSpace.PAGE, right: AppSpace.PAGE, top: 6, bottom: 24 })
      }
      .layoutWeight(1)
      .backgroundColor(AppColors.CANVAS)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.CANVAS)
    .onAreaChange((oldValue, newValue) => {
      this.viewportWidth = parseFloat(`${newValue.width}`);
    })
  }

  @Builder
  private Header() {
    Row({ space: 12 }) {
      Button('‹')
        .fontSize(24)
        .fontColor(AppColors.CHART_BLUE)
        .width(44)
        .height(44)
        .backgroundColor(AppColors.SURFACE)
        .borderRadius(22)
        .shadow({ radius: 14, color: AppColors.SHADOW, offsetY: 6 })
        .onClick(() => router.back())
      Column({ space: 4 }) {
        Text('收支日历')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .width('100%')
        Text('按日期查看每天的收入、支出和流水')
          .fontSize(13)
          .fontColor(AppColors.MUTED)
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .alignItems(VerticalAlign.Center)
    .width('100%')
    .padding({ left: AppSpace.PAGE, right: AppSpace.PAGE, top: this.isNarrow() ? 10 : 18, bottom: 6 })
  }

  @Builder
  private MonthToolbar() {
    Row() {
      Button('‹')
        .fontSize(24)
        .fontColor(AppColors.CHART_BLUE)
        .width(42)
        .height(42)
        .backgroundColor(AppColors.SURFACE_TINT)
        .borderRadius(21)
        .onClick(() => this.changeMonth(-1))
      Column({ space: 2 }) {
        Text(this.monthTitle())
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
        Text(this.isCurrentMonth() ? '本月' : '月度账单')
          .fontSize(11)
          .fontColor(AppColors.MUTED)
      }
      .layoutWeight(1)
      Button('今')
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.CHART_BLUE)
        .width(42)
        .height(42)
        .backgroundColor(AppColors.SURFACE_TINT)
        .borderRadius(21)
        .onClick(() => this.goToday())
      Button('›')
        .fontSize(24)
        .fontColor(AppColors.CHART_BLUE)
        .width(42)
        .height(42)
        .backgroundColor(AppColors.SURFACE_TINT)
        .borderRadius(21)
        .margin({ left: 8 })
        .onClick(() => this.changeMonth(1))
    }
    .width('100%')
    .height(this.isNarrow() ? 52 : 58)
    .padding({ left: 10, right: 10 })
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 18, color: AppColors.SHADOW, offsetY: 7 })
  }

  @Builder
  private MonthOverview() {
    Row({ space: 8 }) {
      this.SummaryMetric('收入', () => this.monthIncome, AppColors.INCOME, '#E6F7EF')
      this.SummaryMetric('支出', () => this.monthExpense, AppColors.EXPENSE, '#FFEAF0')
      this.SummaryMetric('结余', () => this.monthBalance, AppColors.CHART_BLUE, AppColors.SURFACE_TINT)
    }
    .width('100%')
  }

  @Builder
  private SummaryMetric(label: string, amount: () => number, color: string, background: string) {
    Column({ space: 4 }) {
      Text(label)
        .fontSize(11)
        .fontColor(AppColors.MUTED)
      Text(NumberUtil.money(amount()))
        .fontSize(this.isNarrow() ? 12 : 15)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .layoutWeight(1)
    .height(this.isNarrow() ? 54 : 64)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(background)
    .borderRadius(16)
  }

  @Builder
  private CalendarPanel() {
    Column({ space: 0 }) {
      Row() {
        ForEach(['一', '二', '三', '四', '五', '六', '日'], (label: string) => {
          Text(label)
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.MUTED)
            .width('14.2857%')
            .height(this.isNarrow() ? 30 : 36)
            .textAlign(TextAlign.Center)
        })
      }
      .width('100%')

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.calendarDays(), (item: CalendarDayItem) => {
          this.DayCell(item)
        }, (item: CalendarDayItem) => `${item.timestamp}-${item.income}-${item.expense}`)
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 6, right: 6, top: 4, bottom: 8 })
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 20, color: AppColors.SHADOW, offsetY: 8 })
  }

  @Builder
  private DayCell(item: CalendarDayItem) {
    Column({ space: 3 }) {
      Text(`${item.day}`)
        .fontSize(13)
        .fontWeight(this.isSelected(item.timestamp) || item.today ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.dayNumberColor(item))
        .width(this.isNarrow() ? 25 : 27)
        .height(this.isNarrow() ? 25 : 27)
        .textAlign(TextAlign.Center)
        .backgroundColor(item.today && !this.isSelected(item.timestamp) ? AppColors.SURFACE_TINT : '#00000000')
        .borderRadius(14)
      Row({ space: 3 }) {
        if (item.income > 0) {
          Circle()
            .width(5)
            .height(5)
            .fill(AppColors.INCOME)
        }
        if (item.expense > 0) {
          Circle()
            .width(5)
            .height(5)
            .fill(AppColors.EXPENSE)
        }
      }
      .height(6)
      .justifyContent(FlexAlign.Center)
    }
    .width('14.2857%')
    .height(this.isNarrow() ? 46 : 60)
    .justifyContent(FlexAlign.Center)
    .opacity(item.currentMonth ? 1 : 0.35)
    .backgroundColor(this.isSelected(item.timestamp) ? '#EDF5FF' : '#00000000')
    .borderRadius(12)
    .onClick(() => this.selectDay(item.timestamp))
  }

  @Builder
  private DayDetail() {
    Column({ space: 12 }) {
      Row() {
        Column({ space: 3 }) {
          Text(this.selectedDateTitle())
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.INK)
          Text(`${this.selectedRecords.length} 笔流水`)
            .fontSize(12)
            .fontColor(AppColors.MUTED)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Column({ space: 3 }) {
          Text(`收 +${NumberUtil.plainMoney(this.selectedIncome)}`)
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.INCOME)
          Text(`支 -${NumberUtil.plainMoney(this.selectedExpense)}`)
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.EXPENSE)
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')
      .padding({ left: 4, right: 4 })

      Row({ space: 10 }) {
        Button(this.selectedRecords.length === 0 ? '补记这一天' : '在这一天记一笔')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.SURFACE)
          .height(46)
          .layoutWeight(1)
          .backgroundColor(AppColors.CHART_BLUE)
          .borderRadius(AppRadius.PILL)
          .onClick(() => {
            const selected = new Date(this.selectedTime);
            const now = new Date();
            selected.setHours(now.getHours(), now.getMinutes(), 0, 0);
            router.pushUrl({ url: ROUTES.RECORD_EDIT, params: { recordTime: selected.getTime() } });
          })
        Button(FeatureFlags.AUTO_BOOKKEEPING_VISIBLE ? '识别账单' : '导入账单')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.CHART_BLUE)
          .height(46)
          .layoutWeight(1)
          .backgroundColor(AppColors.SURFACE_TINT)
          .borderRadius(AppRadius.PILL)
          .onClick(() => {
            if (!FeatureFlags.AUTO_BOOKKEEPING_VISIBLE) {
              router.pushUrl({ url: ROUTES.ALIPAY_IMPORT });
              return;
            }
            const selected = new Date(this.selectedTime);
            const now = new Date();
            selected.setHours(now.getHours(), now.getMinutes(), 0, 0);
            router.pushUrl({
              url: ROUTES.AUTO_BOOKKEEPING,
              params: {
                launchAction: 'galleryOcr',
                recordTime: selected.getTime()
              }
            });
          })
      }
      .width('100%')

      if (this.selectedRecords.length === 0) {
        Column({ space: 8 }) {
          Text('这天还没有流水')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.INK)
          Text('可以直接补记这一天的收入或支出')
            .fontSize(12)
            .fontColor(AppColors.MUTED)
        }
        .width('100%')
        .height(126)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(AppColors.SURFACE)
        .borderRadius(AppRadius.CARD)
      } else {
        ForEach(this.selectedRecords, (item: RecordListItem) => {
          this.RecordRow(item)
        }, (item: RecordListItem) => `${item.id}-${item.updateTime}`)
      }
    }
    .width('100%')
  }

  @Builder
  private RecordRow(item: RecordListItem) {
    Row({ space: 12 }) {
      Text(item.categoryName.substring(0, 1))
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(item.categoryColor)
        .width(40)
        .height(40)
        .textAlign(TextAlign.Center)
        .backgroundColor(item.type === RecordType.INCOME ? '#E6F7EF' : '#F2F7FC')
        .borderRadius(14)
      Column({ space: 3 }) {
        Text(item.categoryName)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .maxLines(1)
        Text(`${DateUtil.timeLabel(item.recordTime)} · ${item.remark || item.accountName}`)
          .fontSize(11)
          .fontColor(AppColors.MUTED)
          .maxLines(1)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Text(`${item.type === RecordType.EXPENSE ? '-' : '+'}${NumberUtil.money(item.amount)}`)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(item.type === RecordType.EXPENSE ? AppColors.EXPENSE : AppColors.INCOME)
        .maxLines(1)
    }
    .width('100%')
    .height(68)
    .padding({ left: 14, right: 14 })
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 14, color: AppColors.SHADOW, offsetY: 6 })
    .onClick(() => {
      if (item.id) {
        router.pushUrl({ url: ROUTES.RECORD_DETAIL, params: { recordId: item.id } });
      }
    })
  }

  private async loadMonth(): Promise<void> {
    try {
      await AppDatabase.getInstance().init(getContext(this));
      const start = DateUtil.startOfMonth(this.monthTime);
      const end = DateUtil.startOfNextMonth(this.monthTime);
      const monthRecords = await this.repository.listByRange(start, end, 5000, 0);
      this.applyMonthRecords(monthRecords);
      await this.loadSelectedDay();
    } catch (error) {
      ToastUtil.show('日历数据加载失败，请重试');
    }
  }

  private applyMonthRecords(records: RecordListItem[]): void {
    const cashflowMap = new Map<string, DailyCashflow>();
    let income = 0;
    let expense = 0;
    records.forEach((record: RecordListItem) => {
      if (record.type !== RecordType.INCOME && record.type !== RecordType.EXPENSE) {
        return;
      }
      const dayKey = DateUtil.dayKey(record.recordTime);
      let cashflow = cashflowMap.get(dayKey);
      if (!cashflow) {
        cashflow = new DailyCashflow(dayKey, 0, 0);
        cashflowMap.set(dayKey, cashflow);
      }
      if (record.type === RecordType.INCOME) {
        income += record.amount;
        cashflow.income += record.amount;
      } else {
        expense += record.amount;
        cashflow.expense += record.amount;
      }
    });
    this.dailyCashflow = Array.from(cashflowMap.values());
    this.monthIncome = income;
    this.monthExpense = expense;
    this.monthBalance = income - expense;
  }

  private async loadSelectedDay(): Promise<void> {
    const start = DateUtil.startOfDay(this.selectedTime);
    const end = new Date(new Date(start).getFullYear(), new Date(start).getMonth(), new Date(start).getDate() + 1).getTime();
    this.selectedRecords = await this.repository.listByRange(start, end, 200, 0);
    let income = 0;
    let expense = 0;
    this.selectedRecords.forEach((item: RecordListItem) => {
      if (item.type === RecordType.INCOME) {
        income += item.amount;
      } else if (item.type === RecordType.EXPENSE) {
        expense += item.amount;
      }
    });
    this.selectedIncome = income;
    this.selectedExpense = expense;
  }

  private calendarDays(): CalendarDayItem[] {
    const month = new Date(this.monthTime);
    const first = new Date(month.getFullYear(), month.getMonth(), 1);
    const mondayOffset = first.getDay() === 0 ? 6 : first.getDay() - 1;
    const gridStart = new Date(month.getFullYear(), month.getMonth(), 1 - mondayOffset);
    const result: CalendarDayItem[] = [];
    for (let index = 0; index < 42; index++) {
      const timestamp = new Date(gridStart.getFullYear(), gridStart.getMonth(), gridStart.getDate() + index).getTime();
      const date = new Date(timestamp);
      const cashflow = this.cashflowFor(DateUtil.dayKey(timestamp));
      const item = new CalendarDayItem();
      item.timestamp = timestamp;
      item.day = date.getDate();
      item.currentMonth = date.getFullYear() === month.getFullYear() && date.getMonth() === month.getMonth();
      item.today = DateUtil.dayKey(timestamp) === DateUtil.dayKey(Date.now());
      item.income = cashflow ? cashflow.income : 0;
      item.expense = cashflow ? cashflow.expense : 0;
      result.push(item);
    }
    return result;
  }

  private cashflowFor(dayKey: string): DailyCashflow | undefined {
    return this.dailyCashflow.find((item: DailyCashflow) => item.dayKey === dayKey);
  }

  private async selectDay(timestamp: number): Promise<void> {
    const selected = new Date(timestamp);
    const month = new Date(this.monthTime);
    if (selected.getFullYear() !== month.getFullYear() || selected.getMonth() !== month.getMonth()) {
      this.monthTime = DateUtil.startOfMonth(timestamp);
      this.selectedTime = DateUtil.startOfDay(timestamp);
      await this.loadMonth();
      return;
    }
    this.selectedTime = DateUtil.startOfDay(timestamp);
    await this.loadSelectedDay();
  }

  private async changeMonth(offset: number): Promise<void> {
    const current = new Date(this.monthTime);
    this.monthTime = new Date(current.getFullYear(), current.getMonth() + offset, 1).getTime();
    this.selectedTime = this.monthTime;
    await this.loadMonth();
  }

  private async goToday(): Promise<void> {
    this.monthTime = DateUtil.startOfMonth();
    this.selectedTime = DateUtil.startOfDay();
    await this.loadMonth();
  }

  private monthTitle(): string {
    const date = new Date(this.monthTime);
    return `${date.getFullYear()}年${date.getMonth() + 1}月`;
  }

  private selectedDateTitle(): string {
    const date = new Date(this.selectedTime);
    const weekday = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'][date.getDay()];
    return `${date.getMonth() + 1}月${date.getDate()}日 ${weekday}`;
  }

  private dayNumberColor(item: CalendarDayItem): string {
    if (this.isSelected(item.timestamp)) {
      return AppColors.CHART_BLUE;
    }
    return item.currentMonth ? AppColors.INK : AppColors.FAINT;
  }

  private isSelected(timestamp: number): boolean {
    return DateUtil.dayKey(timestamp) === DateUtil.dayKey(this.selectedTime);
  }

  private isCurrentMonth(): boolean {
    return DateUtil.monthKey(this.monthTime) === DateUtil.monthKey(Date.now());
  }

  private isNarrow(): boolean {
    return this.viewportWidth > 0 && this.viewportWidth < Breakpoints.TABLET;
  }
}
