import { router } from '@kit.ArkUI';
import { AppDatabase } from '../database/AppDatabase';
import { CategoryRankItem } from '../viewmodel/StatisticsViewModel';
import { CategoryExpenseRank, MonthSummary, RecordRepository, TrendPoint } from '../repository/RecordRepository';
import { AppColors, AppRadius, AppSpace, Breakpoints, LayoutSizes } from '../constants/DesignSystem';
import { DateUtil } from '../utils/DateUtil';
import { NumberUtil } from '../utils/NumberUtil';
import { ToastUtil } from '../utils/ToastUtil';

enum ReportMode {
  MONTH = 'month',
  YEAR = 'year'
}

@Entry
@Component
struct Reports {
  private repository: RecordRepository = new RecordRepository();
  private loadGeneration: number = 0;

  @State viewportWidth: number = 0;
  @State mode: ReportMode = ReportMode.MONTH;
  @State anchorTime: number = Date.now();
  @State income: number = 0;
  @State expense: number = 0;
  @State balance: number = 0;
  @State recordCount: number = 0;
  @State ranks: CategoryRankItem[] = [];
  @State trendPoints: TrendPoint[] = [];
  @StorageLink('ledgerIsDarkMode') isDarkMode: boolean = false;

  aboutToAppear(): void {
    this.loadData();
  }

  onPageShow(): void {
    this.loadData();
  }

  build() {
    Column() {
      this.Header()
      Scroll() {
        Column({ space: 16 }) {
          this.ModeSwitch()
          this.ReportHero()
          this.InsightCard()
          this.TopCategoryCard()
          this.TrendListCard()
        }
        .width('100%')
        .constraintSize({ maxWidth: this.contentMaxWidth() })
        .alignSelf(ItemAlign.Center)
        .padding({ left: AppSpace.PAGE, right: AppSpace.PAGE, top: 10, bottom: 24 })
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
    Column({ space: 6 }) {
      Button('‹')
        .fontSize(24)
        .fontColor(AppColors.CHART_BLUE)
        .width(46)
        .height(46)
        .backgroundColor(AppColors.SURFACE)
        .borderRadius(23)
        .shadow({ radius: 14, color: AppColors.SHADOW, offsetY: 6 })
        .alignSelf(ItemAlign.Start)
        .onClick(() => router.back())
      Column({ space: 4 }) {
        Text('账本报告')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .width('100%')
        Text('月报、年报和消费结构摘要')
          .fontSize(13)
          .fontColor(AppColors.MUTED)
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
    }
    .width('100%')
    .padding({ left: AppSpace.PAGE, right: AppSpace.PAGE, top: 22, bottom: 8 })
  }

  @Builder
  private ModeSwitch() {
    Column({ space: 10 }) {
      Row({ space: 6 }) {
        this.ModeButton('月报', ReportMode.MONTH)
        this.ModeButton('年报', ReportMode.YEAR)
      }
      .height(46)
      .padding(4)
      .backgroundColor(AppColors.TRACK)
      .borderRadius(AppRadius.PILL)

      Row() {
        Button('‹')
          .fontSize(24)
          .fontColor(AppColors.CHART_BLUE)
          .width(42)
          .height(36)
          .backgroundColor(AppColors.softBlue())
          .borderRadius(18)
          .onClick(() => this.move(-1))
        Text(this.rangeTitle())
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Button('›')
          .fontSize(24)
          .fontColor(AppColors.CHART_BLUE)
          .width(42)
          .height(36)
          .backgroundColor(AppColors.softBlue())
          .borderRadius(18)
          .onClick(() => this.move(1))
      }
      .width('100%')
    }
    .width('100%')
    .padding(12)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 18, color: AppColors.SHADOW, offsetY: 8 })
  }

  @Builder
  private ReportHero() {
    Column({ space: 14 }) {
      Row() {
        Text(this.mode === ReportMode.MONTH ? '月' : '年')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.CHART_BLUE)
          .width(48)
          .height(48)
          .textAlign(TextAlign.Center)
          .borderRadius(18)
          .backgroundColor(AppColors.softBlue())
        Blank()
        Text(`${this.recordCount} 笔`)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.LEDGER)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor(AppColors.SURFACE_TINT)
          .borderRadius(AppRadius.PILL)
      }
      .width('100%')

      Text(this.reportTitle())
        .fontSize(this.isPhone() ? 24 : 30)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.INK)
        .width('100%')
      Text(this.reportCopy())
        .fontSize(13)
        .fontColor(AppColors.MUTED)
        .lineHeight(21)
        .width('100%')
        .maxLines(3)

      Row({ space: 8 }) {
        this.Metric('收入', () => NumberUtil.compactMoney(this.income), () => AppColors.CHART_GREEN, () => AppColors.softGreen())
        this.Metric('支出', () => NumberUtil.compactMoney(this.expense), () => AppColors.CHART_PINK, () => AppColors.softPink())
        this.Metric('结余', () => NumberUtil.compactMoney(this.balance), () => this.balance >= 0 ? AppColors.CHART_BLUE : AppColors.EXPENSE, () => AppColors.SURFACE_TINT)
      }
      .width('100%')
    }
    .width('100%')
    .padding(18)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 24, color: AppColors.SHADOW, offsetY: 10 })
  }

  @Builder
  private InsightCard() {
    Row({ space: 8 }) {
      this.Metric('日均支出', () => NumberUtil.compactMoney(this.averageExpense()), () => AppColors.CHART_ORANGE, () => AppColors.softYellow())
      this.Metric('收支比', () => `${this.expenseRate()}%`, () => this.expenseRate() <= 80 ? AppColors.CHART_GREEN : AppColors.EXPENSE, () => this.expenseRate() <= 80 ? AppColors.softGreen() : AppColors.softDanger())
      this.Metric('最高分类', () => this.topCategoryName(), () => AppColors.CHART_PURPLE, () => AppColors.softPurple())
    }
    .width('100%')
  }

  @Builder
  private TopCategoryCard() {
    Column({ space: 12 }) {
      this.CardTitle(() => '支出结构', () => this.ranks.length === 0 ? '暂无' : `${this.ranks.length} 类`)
      if (this.ranks.length === 0) {
        this.EmptyState('本期没有支出记录')
      } else {
        ForEach(this.ranks.slice(0, 5), (item: CategoryRankItem) => {
          this.CategoryRow(item)
        }, (item: CategoryRankItem) => `${item.categoryId}-${item.amount}`)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 20, color: AppColors.SHADOW, offsetY: 8 })
  }

  @Builder
  private TrendListCard() {
    Column({ space: 12 }) {
      this.CardTitle(() => this.mode === ReportMode.MONTH ? '每日节奏' : '月度节奏', () => `${this.visibleTrendPoints().length} 段`)
      Row({ space: 14 }) {
        this.TrendLegend('收入', AppColors.CHART_GREEN)
        this.TrendLegend('支出', AppColors.CHART_PINK)
      }
      .width('100%')
      if (this.visibleTrendPoints().length === 0) {
        this.EmptyState('暂无趋势数据')
      } else {
        ForEach(this.visibleTrendPoints(), (item: TrendPoint) => {
          this.TrendRow(item)
        }, (item: TrendPoint) => `${item.label}-${item.income}-${item.expense}`)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 20, color: AppColors.SHADOW, offsetY: 8 })
  }

  @Builder
  private Metric(label: string, value: () => string, color: () => string, bgColor: () => string) {
    Column({ space: 4 }) {
      Text(label)
        .fontSize(11)
        .fontColor(AppColors.MUTED)
        .maxLines(1)
      Text(value())
        .fontSize(this.metricFontSize(value()))
        .fontWeight(FontWeight.Bold)
        .fontColor(color())
        .width('100%')
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .layoutWeight(1)
    .height(64)
    .justifyContent(FlexAlign.Center)
    .padding({ left: 8, right: 8 })
    .backgroundColor(bgColor())
    .borderRadius(16)
    .border({ width: 1, color: AppColors.LINE })
  }

  @Builder
  private CategoryRow(item: CategoryRankItem) {
    Column({ space: 7 }) {
      Row({ space: 10 }) {
        Text(item.categoryName.substring(0, 1))
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(item.categoryColor)
          .width(36)
          .height(36)
          .textAlign(TextAlign.Center)
          .borderRadius(14)
          .backgroundColor(AppColors.SURFACE_TINT)
        Text(item.categoryName)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .layoutWeight(1)
          .maxLines(1)
        Text(NumberUtil.compactMoney(item.amount))
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.EXPENSE)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .constraintSize({ maxWidth: 110 })
      }
      .width('100%')
      Stack({ alignContent: Alignment.Start }) {
        Column()
          .height(7)
          .width('100%')
          .backgroundColor(AppColors.TRACK)
          .borderRadius(4)
        Column()
          .height(7)
          .width(`${Math.min(100, item.percent)}%`)
          .backgroundColor(item.categoryColor)
          .borderRadius(4)
      }
      .width('100%')
      .height(7)
    }
    .width('100%')
  }

  @Builder
  private TrendRow(item: TrendPoint) {
    Row({ space: 10 }) {
      Text(this.shortTrendLabel(item.label))
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.INK)
        .width(54)
        .maxLines(1)
      Column({ space: 5 }) {
        this.MiniBar(item.income, this.maxTrendValue(), AppColors.CHART_GREEN)
        this.MiniBar(item.expense, this.maxTrendValue(), AppColors.CHART_PINK)
      }
      .layoutWeight(1)
      Column({ space: 2 }) {
        Text(`收 ${NumberUtil.compactMoney(item.income)}`)
          .fontSize(10)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.CHART_GREEN)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(`支 ${NumberUtil.compactMoney(item.expense)}`)
          .fontSize(10)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.EXPENSE)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width(82)
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
  }

  @Builder
  private MiniBar(value: number, maxValue: number, color: string) {
    Stack({ alignContent: Alignment.Start }) {
      Column()
        .width('100%')
        .height(6)
        .backgroundColor(AppColors.TRACK)
        .borderRadius(3)
      Column()
        .width(`${maxValue > 0 ? Math.max(4, Math.round(value / maxValue * 100)) : 0}%`)
        .height(6)
        .backgroundColor(color)
        .borderRadius(3)
    }
    .width('100%')
    .height(6)
  }

  @Builder
  private TrendLegend(label: string, color: string) {
    Row({ space: 5 }) {
      Column()
        .width(8)
        .height(8)
        .borderRadius(4)
        .backgroundColor(color)
      Text(label)
        .fontSize(11)
        .fontColor(AppColors.MUTED)
    }
  }

  @Builder
  private CardTitle(title: () => string, badge: () => string) {
    Row() {
      Text(title())
        .fontSize(19)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.INK)
      Blank()
      Text(badge())
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.LEDGER)
        .padding({ left: 12, right: 12, top: 5, bottom: 5 })
        .backgroundColor(AppColors.SURFACE_TINT)
        .borderRadius(AppRadius.PILL)
    }
    .width('100%')
  }

  @Builder
  private ModeButton(label: string, mode: ReportMode) {
    Text(label)
      .fontSize(14)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.mode === mode ? AppColors.SURFACE : AppColors.MUTED)
      .height(38)
      .layoutWeight(1)
      .textAlign(TextAlign.Center)
      .backgroundColor(this.mode === mode ? AppColors.CHART_BLUE : '#00000000')
      .borderRadius(AppRadius.PILL)
      .onClick(() => {
        this.mode = mode;
        this.loadData();
      })
  }

  @Builder
  private EmptyState(text: string) {
    Text(text)
      .fontSize(14)
      .fontColor(AppColors.MUTED)
      .width('100%')
      .height(84)
      .textAlign(TextAlign.Center)
      .backgroundColor(AppColors.SURFACE_SOFT)
      .borderRadius(18)
  }

  private async loadData(): Promise<void> {
    const generation = ++this.loadGeneration;
    const mode = this.mode;
    const anchorTime = this.anchorTime;
    try {
      await AppDatabase.getInstance().init(getContext(this));
      const startTime = mode === ReportMode.YEAR ? DateUtil.startOfYear(anchorTime) : DateUtil.startOfMonth(anchorTime);
      const endTime = mode === ReportMode.YEAR ? DateUtil.startOfNextYear(anchorTime) : DateUtil.startOfNextMonth(anchorTime);
      const summary: MonthSummary = await this.repository.monthSummary(startTime, endTime);
      const recordCount = await this.repository.recordCount(startTime, endTime);
      const ranks = await this.repository.categoryExpenseRanks(startTime, endTime);
      const categoryRanks = ranks.map((item: CategoryExpenseRank) => {
        return new CategoryRankItem(item.categoryId, item.categoryName, item.categoryColor, item.amount, item.percent, item.recordCount);
      });
      const trendPoints = mode === ReportMode.YEAR
        ? await this.repository.trendByMonth(startTime, endTime)
        : await this.repository.trendByDay(startTime, endTime);
      if (generation !== this.loadGeneration) {
        return;
      }
      this.income = summary.income;
      this.expense = summary.expense;
      this.balance = summary.balance;
      this.recordCount = recordCount;
      this.ranks = categoryRanks;
      this.trendPoints = trendPoints;
    } catch (error) {
      if (generation === this.loadGeneration) {
        ToastUtil.show('报告加载失败，请稍后重试');
      }
    }
  }

  private move(direction: number): void {
    const date = new Date(this.anchorTime);
    if (this.mode === ReportMode.YEAR) {
      this.anchorTime = new Date(date.getFullYear() + direction, 0, 1).getTime();
    } else {
      this.anchorTime = new Date(date.getFullYear(), date.getMonth() + direction, 1).getTime();
    }
    this.loadData();
  }

  private rangeStart(): number {
    return this.mode === ReportMode.YEAR ? DateUtil.startOfYear(this.anchorTime) : DateUtil.startOfMonth(this.anchorTime);
  }

  private rangeEnd(): number {
    return this.mode === ReportMode.YEAR ? DateUtil.startOfNextYear(this.anchorTime) : DateUtil.startOfNextMonth(this.anchorTime);
  }

  private rangeTitle(): string {
    const date = new Date(this.anchorTime);
    if (this.mode === ReportMode.YEAR) {
      return `${date.getFullYear()} 年`;
    }
    return `${date.getFullYear()} 年 ${date.getMonth() + 1} 月`;
  }

  private reportTitle(): string {
    if (this.recordCount === 0) {
      return '本期还没有账单';
    }
    if (this.balance >= 0) {
      return '这一期留住了一部分钱';
    }
    return '这一期支出更活跃';
  }

  private reportCopy(): string {
    if (this.recordCount === 0) {
      return '记录收入和支出后，这里会自动整理消费结构、收支比和节奏。';
    }
    return `共记录 ${this.recordCount} 笔，支出占收入 ${this.expenseRate()}%，日均支出 ${NumberUtil.compactMoney(this.averageExpense())}。`;
  }

  private averageExpense(): number {
    const days = Math.max(1, Math.ceil((this.rangeEnd() - this.rangeStart()) / 86400000));
    return Math.round(this.expense / days * 100) / 100;
  }

  private expenseRate(): number {
    if (this.income <= 0) {
      return this.expense > 0 ? 100 : 0;
    }
    return Math.round(this.expense / this.income * 100);
  }

  private topCategoryName(): string {
    return this.ranks.length > 0 ? this.ranks[0].categoryName : '暂无';
  }

  private maxTrendValue(): number {
    return this.visibleTrendPoints().reduce((max: number, item: TrendPoint) => {
      return Math.max(max, item.income, item.expense);
    }, 0);
  }

  private visibleTrendPoints(): TrendPoint[] {
    const nonZero = this.trendPoints.filter((item: TrendPoint) => item.income > 0 || item.expense > 0);
    const limit = this.mode === ReportMode.MONTH ? 10 : 12;
    return nonZero.slice(Math.max(0, nonZero.length - limit));
  }

  private shortTrendLabel(label: string): string {
    if (label.length >= 10) {
      return label.substring(5);
    }
    if (label.length >= 7) {
      return label.substring(5);
    }
    return label;
  }

  private metricFontSize(value: string): number {
    if (value.length <= 6) {
      return this.isPhone() ? 14 : 16;
    }
    if (value.length <= 9) {
      return this.isPhone() ? 13 : 15;
    }
    return 12;
  }

  private isPhone(): boolean {
    return this.viewportWidth < Breakpoints.TABLET;
  }

  private contentMaxWidth(): number {
    return this.viewportWidth >= Breakpoints.DESKTOP ? LayoutSizes.CONTENT_MAX : LayoutSizes.CONTENT_COMPACT;
  }
}
