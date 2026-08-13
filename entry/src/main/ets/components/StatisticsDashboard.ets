import { common } from '@kit.AbilityKit';
import { picker } from '@kit.CoreFileKit';
import { BarChart } from './BarChart';
import { LineChart } from './LineChart';
import { PieChart } from './PieChart';
import { AppColors, AppRadius, AppSpace, Breakpoints, LayoutSizes } from '../constants/DesignSystem';
import { CategoryRankItem, PeriodOption, StatisticsPeriod, StatisticsViewModel } from '../viewmodel/StatisticsViewModel';
import { TrendPoint } from '../repository/RecordRepository';
import { DateUtil } from '../utils/DateUtil';
import { NumberUtil } from '../utils/NumberUtil';
import { StatisticsPdfExporter, StatisticsPdfReport } from '../utils/StatisticsPdfExporter';
import { ToastUtil } from '../utils/ToastUtil';
import { AppDatabase } from '../database/AppDatabase';

interface DatePickerResult {
  year?: number;
  month?: number;
  day?: number;
}

enum TrendChartMode {
  LINE = 'line',
  BAR = 'bar'
}

@Component
export struct StatisticsDashboard {
  @Prop showHeader: boolean = true;
  @Prop @Watch('onActiveChanged') active: boolean = true;
  @Prop @Watch('onRefreshKeyChanged') refreshKey: number = 0;
  @State vm: StatisticsViewModel = new StatisticsViewModel();
  @State viewportWidth: number = 0;
  @State chartMode: TrendChartMode = TrendChartMode.LINE;
  @State income: number = 0;
  @State expense: number = 0;
  @State balance: number = 0;
  @State categoryRanks: CategoryRankItem[] = [];
  @State trendPoints: TrendPoint[] = [];
  @State dataRangeLabel: string = '';
  @State customEditorVisible: boolean = false;
  @State draftCustomStartTime: number = DateUtil.addDays(DateUtil.startOfDay(), -29);
  @State draftCustomEndTime: number = DateUtil.startOfDay();

  aboutToAppear(): void {
    this.refreshData();
  }

  onRefreshKeyChanged(): void {
    this.refreshData();
  }

  onActiveChanged(): void {
    if (this.active) {
      this.refreshData();
    }
  }

  build() {
    Scroll() {
      Column({ space: this.isPhone() ? 12 : 18 }) {
        if (this.showHeader) {
          this.Header()
        }
        this.PeriodSwitch()
        this.RangeToolbar()
        this.SummaryCard()
        this.DimensionOverview()
        this.ChartGrid()
      }
      .width('100%')
      .constraintSize({ maxWidth: this.contentMaxWidth() })
      .alignSelf(ItemAlign.Center)
      .padding({ left: AppSpace.PAGE, right: AppSpace.PAGE, top: this.isPhone() ? 14 : 24, bottom: 82 })
    }
    .height('100%')
    .backgroundColor(AppColors.CANVAS)
    .onAreaChange((oldValue, newValue) => {
      this.viewportWidth = parseFloat(`${newValue.width}`);
    })
  }

  @Builder
  private Header() {
    Row() {
      Column({ space: 5 }) {
        Text('统计')
          .fontSize(this.isPhone() ? 24 : 28)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
        Text('周 / 月 / 季 / 年 / 自定义')
          .fontSize(13)
          .fontColor(AppColors.MUTED)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Button('导出')
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.CHART_BLUE)
        .height(this.isPhone() ? 40 : 44)
        .padding({ left: 20, right: 20 })
        .backgroundColor(AppColors.SURFACE)
        .borderRadius(AppRadius.PILL)
        .shadow({ radius: 16, color: AppColors.SHADOW, offsetY: 7 })
        .onClick(() => this.exportPdf())
    }
    .width('100%')
  }

  @Builder
  private PeriodSwitch() {
    Row({ space: 5 }) {
      ForEach(this.vm.periodOptions, (option: PeriodOption) => {
        Text(option.label)
          .fontSize(this.isPeriodSelected(option.value) ? 14 : 13)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isPeriodSelected(option.value) ? AppColors.INK : AppColors.MUTED)
          .textAlign(TextAlign.Center)
          .height(this.isPhone() ? 36 : 42)
          .layoutWeight(1)
          .borderRadius(AppRadius.PILL)
          .backgroundColor(this.isPeriodSelected(option.value) ? AppColors.SURFACE : '#00000000')
          .shadow(this.isPeriodSelected(option.value) ? { radius: 12, color: AppColors.SHADOW, offsetY: 5 } : { radius: 0, color: '#00000000', offsetY: 0 })
          .onClick(() => {
            if (option.value === StatisticsPeriod.CUSTOM) {
              this.openCustomEditor();
            } else {
              this.customEditorVisible = false;
              this.changePeriod(option.value);
            }
          })
      }, (option: PeriodOption) => option.value)
    }
    .height(this.isPhone() ? 44 : 50)
    .padding(4)
    .width('100%')
    .backgroundColor('#E7EAEE')
    .borderRadius(AppRadius.PILL)
  }

  @Builder
  private RangeToolbar() {
    Column({ space: 12 }) {
      Row() {
        Button('‹')
          .fontSize(24)
          .fontColor(AppColors.CHART_BLUE)
          .width(42)
          .height(this.isPhone() ? 34 : 38)
          .backgroundColor('#EAF4FF')
          .borderRadius(19)
          .onClick(() => {
            this.movePrevious();
          })

        Text(this.dataRangeLabel || DateUtil.rangeLabel(DateUtil.startOfMonth(), DateUtil.startOfNextMonth()))
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .textAlign(TextAlign.Center)
          .layoutWeight(1)

        Button('›')
          .fontSize(24)
          .fontColor(AppColors.CHART_BLUE)
          .width(42)
          .height(this.isPhone() ? 34 : 38)
          .backgroundColor('#EAF4FF')
          .borderRadius(19)
          .onClick(() => {
            this.moveNext();
          })
      }
      .width('100%')

      if (this.customEditorVisible) {
        Column({ space: 10 }) {
          Row({ space: 8 }) {
            this.DateField('开始日期', this.draftCustomStartTime, true)
            this.DateField('结束日期', this.draftCustomEndTime, false)
          }
          .width('100%')

          Row({ space: 8 }) {
            Button('取消')
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.MUTED)
              .width(76)
              .height(38)
              .backgroundColor(AppColors.SURFACE_SOFT)
              .borderRadius(AppRadius.PILL)
              .onClick(() => {
                this.customEditorVisible = false;
              })
            Button('确定')
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.SURFACE)
              .layoutWeight(1)
              .height(38)
              .backgroundColor(AppColors.CHART_BLUE)
              .borderRadius(AppRadius.PILL)
              .onClick(() => this.applyCustomRange())
          }
          .width('100%')
        }
        .width('100%')
        .padding({ top: 2 })
      }
    }
    .padding(this.isPhone() ? 12 : 14)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 18, color: AppColors.SHADOW, offsetY: 8 })
  }

  @Builder
  private DateField(label: string, timestamp: number, isStart: boolean) {
    Column({ space: 5 }) {
      Text(label)
        .fontSize(11)
        .fontColor(AppColors.MUTED)
        .width('100%')
      Row() {
        Text(this.fullDateLabel(timestamp))
          .fontSize(this.isPhone() ? 14 : 15)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .layoutWeight(1)
          .maxLines(1)
        Text('›')
          .fontSize(20)
          .fontColor(AppColors.CHART_BLUE)
      }
        .width('100%')
        .height(26)
    }
    .layoutWeight(1)
    .height(62)
    .padding({ left: 12, right: 10, top: 8, bottom: 8 })
    .backgroundColor(AppColors.SURFACE_SOFT)
    .border({ width: 1, color: AppColors.LINE })
    .borderRadius(14)
    .onClick(() => this.showCustomDatePicker(isStart))
  }

  @Builder
  private SummaryCard() {
    Column({ space: this.isDesktop() ? 20 : 12 }) {
      Row() {
        Row({ space: 12 }) {
          Text('¥')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.CHART_BLUE)
            .width(this.isPhone() ? 44 : 52)
            .height(this.isPhone() ? 44 : 52)
            .textAlign(TextAlign.Center)
            .borderRadius(this.isPhone() ? 22 : 26)
            .backgroundColor(AppColors.SURFACE_TINT)
          Column({ space: 6 }) {
            Row({ space: 10 }) {
              Text('收支状态')
                .fontSize(this.isPhone() ? 18 : 22)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppColors.INK)
              Text('i')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppColors.MUTED)
                .width(22)
                .height(22)
                .textAlign(TextAlign.Center)
                .borderRadius(11)
                .border({ width: 1, color: AppColors.FAINT })
            }
            Text(this.dataRangeLabel || DateUtil.rangeLabel(DateUtil.startOfMonth(), DateUtil.startOfNextMonth()))
              .fontSize(14)
              .fontColor(AppColors.MUTED)
          }
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)

        Text(this.flowStatusText())
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.flowStatusColor())
          .padding({ left: 18, right: 18, top: 8, bottom: 8 })
          .backgroundColor(this.flowStatusBackground())
          .borderRadius(AppRadius.PILL)
      }
      .width('100%')

      Row({ space: 14 }) {
        Column()
          .width(5)
          .height(this.isPhone() ? 62 : 108)
          .backgroundColor(AppColors.CHART_BLUE)
          .borderRadius(3)
        Column({ space: 4 }) {
          Row({ space: 4 }) {
            Text(this.flowScoreText())
              .fontSize(this.isPhone() ? 34 : 52)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.INK)
              .maxLines(1)
            if (this.hasFlowData()) {
              Text('分')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppColors.CHART_BLUE)
            }
          }
          Text('现金流评分')
            .fontSize(15)
            .fontColor(AppColors.MUTED)
            .width('100%')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')

      Text(this.balanceCopy())
        .fontSize(15)
        .fontColor(AppColors.MUTED)
        .lineHeight(24)
        .width('100%')
        .maxLines(this.isPhone() ? 2 : 3)

      if (!this.isPhone()) {
        Column()
          .width('100%')
          .height(1)
          .backgroundColor(AppColors.LINE)

        if (this.isTablet()) {
          Column({ space: 12 }) {
            this.InfluenceTile('主要影响', this.primaryImpact(), AppColors.CHART_CYAN, '#E5F8F6')
            Column()
              .width('100%')
              .height(1)
              .backgroundColor(AppColors.LINE)
            this.InfluenceTile('下一步', '查看分类明细', AppColors.CHART_BLUE, AppColors.SURFACE_TINT)
          }
          .width('100%')
        } else {
          Row({ space: 0 }) {
            this.InfluenceTile('主要影响', this.primaryImpact(), AppColors.CHART_CYAN, '#E5F8F6')
            Column()
              .width(1)
              .height(64)
              .backgroundColor(AppColors.LINE)
            this.InfluenceTile('下一步', '查看分类明细', AppColors.CHART_BLUE, AppColors.SURFACE_TINT)
          }
          .width('100%')
        }
      }
    }
    .width('100%')
    .padding(this.isPhone() ? 16 : 26)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 30, color: AppColors.SHADOW, offsetY: 12 })
  }

  @Builder
  private DimensionOverview() {
    Column({ space: 10 }) {
      Text('维度概览')
        .fontSize(this.isPhone() ? 18 : 21)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.INK)
        .width('100%')

      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
        this.DimensionCard('收入', () => NumberUtil.money(this.income), '入', AppColors.CHART_GREEN, '#E6F7EF')
        this.DimensionCard('支出', () => NumberUtil.money(this.expense), '支', AppColors.CHART_PINK, '#FFEAF0')
        this.DimensionCard('结余', () => NumberUtil.money(this.balance), '余', AppColors.CHART_BLUE, '#EAF4FF')
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  private DimensionCard(label: string, value: () => string, mark: string, color: string, bgColor: string) {
    Column({ space: this.isPhone() ? 5 : 14 }) {
      Text(mark)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
        .width(this.isPhone() ? 30 : 42)
        .height(this.isPhone() ? 30 : 42)
        .textAlign(TextAlign.Center)
        .borderRadius(this.isPhone() ? 15 : 21)
        .backgroundColor(bgColor)
      Column({ space: this.isPhone() ? 1 : 5 }) {
        Text(label)
          .fontSize(this.isPhone() ? 13 : 14)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.MUTED)
          .width('100%')
        Text(value())
          .fontSize(this.isPhone() ? 16 : 18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .width('100%')
          .maxLines(1)
      }
      .alignItems(HorizontalAlign.Start)
    }
    .width(this.dimensionCardWidth())
    .height(this.isPhone() ? 94 : 132)
    .padding(this.isPhone() ? 8 : 16)
    .backgroundColor(AppColors.SURFACE_SOFT)
    .border({ width: 1, color: AppColors.LINE })
    .borderRadius(this.isPhone() ? 18 : 24)
    .margin({ bottom: this.isPhone() ? 4 : 12 })
  }

  @Builder
  private InfluenceTile(label: string, value: string, color: string, bgColor: string) {
    Row({ space: 12 }) {
      Text(label === '主要影响' ? '因' : '›')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
        .width(38)
        .height(38)
        .textAlign(TextAlign.Center)
        .borderRadius(19)
        .backgroundColor(bgColor)
      Column({ space: 4 }) {
        Text(label)
          .fontSize(13)
          .fontColor(AppColors.MUTED)
        Text(value)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .maxLines(1)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .layoutWeight(1)
    .padding({ left: 16, right: 16 })
  }

  @Builder
  private ChartGrid() {
    if (this.isDesktop()) {
      Row({ space: 14 }) {
        this.PieCard()
        this.TrendCard()
      }
      .width('100%')
    } else {
      Column({ space: 14 }) {
        this.PieCard()
        this.TrendCard()
      }
      .width('100%')
    }
  }

  @Builder
  private PieCard() {
    Column({ space: 14 }) {
      this.CardTitle('分类占比', () => this.categoryRanks.length === 0 ? '暂无' : `${this.categoryRanks.length} 类`)
      PieChart({ items: this.categoryRanks })
    }
    .width(this.chartCardWidth())
    .constraintSize({ minWidth: 260 })
    .padding(this.isPhone() ? 14 : 22)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 24, color: AppColors.SHADOW, offsetY: 10 })
    .margin({ bottom: 14 })
  }

  @Builder
  private TrendCard() {
    Column({ space: 14 }) {
      this.CardTitle('趋势分析', () => this.chartMode === TrendChartMode.LINE ? '折线' : '柱状')

      Row({ space: 8 }) {
        this.ChartModeButton('折线图', TrendChartMode.LINE)
        this.ChartModeButton('柱状图', TrendChartMode.BAR)
      }
      .height(this.isPhone() ? 42 : 48)
      .padding(4)
      .backgroundColor('#E5EBF2')
      .borderRadius(AppRadius.PILL)

      if (this.chartMode === TrendChartMode.LINE) {
        LineChart({
          points: this.trendPoints,
          totalIncome: this.income,
          totalExpense: this.expense,
          refreshKey: this.refreshKey
        })
      } else {
        BarChart({
          points: this.trendPoints,
          totalIncome: this.income,
          totalExpense: this.expense,
          refreshKey: this.refreshKey
        })
      }
    }
    .width(this.chartCardWidth())
    .constraintSize({ minWidth: 260 })
    .padding(this.isPhone() ? 14 : 22)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 24, color: AppColors.SHADOW, offsetY: 10 })
    .margin({ bottom: 14 })
  }

  @Builder
  private CardTitle(title: string, badge: () => string) {
    Row() {
      Text(title)
        .fontSize(this.isPhone() ? 18 : 20)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.INK)
      Blank()
      Text(badge())
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.LEDGER)
        .padding({ left: 12, right: 12, top: 5, bottom: 5 })
        .backgroundColor(AppColors.SURFACE_TINT)
        .borderRadius(AppRadius.PILL)
    }
    .width('100%')
  }

  @Builder
  private ChartModeButton(label: string, mode: TrendChartMode) {
    Row({ space: 8 }) {
      this.ChartModeIcon(mode)
      Text(label)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.chartMode === mode ? AppColors.INK : AppColors.MUTED)
    }
      .justifyContent(FlexAlign.Center)
      .height(this.isPhone() ? 34 : 40)
      .layoutWeight(1)
      .borderRadius(AppRadius.PILL)
      .backgroundColor(this.chartMode === mode ? AppColors.SURFACE : '#00000000')
      .border({ width: this.chartMode === mode ? 1 : 0, color: '#DCE7F2' })
      .shadow(this.chartMode === mode ? { radius: 10, color: AppColors.SHADOW, offsetY: 4 } : { radius: 0, color: '#00000000', offsetY: 0 })
      .onClick(() => {
        this.chartMode = mode;
      })
  }

  @Builder
  private ChartModeIcon(mode: TrendChartMode) {
    if (mode === TrendChartMode.LINE) {
      Stack() {
        Column()
          .width(2)
          .height(16)
          .backgroundColor('#D6E2EC')
          .borderRadius(1)
          .margin({ left: 2, top: 1 })
        Column()
          .width(18)
          .height(2)
          .backgroundColor(this.chartMode === mode ? AppColors.CHART_BLUE : AppColors.MUTED)
          .borderRadius(1)
          .rotate({ angle: -22 })
          .margin({ top: 12, left: 3 })
        Column()
          .width(16)
          .height(2)
          .backgroundColor(this.chartMode === mode ? AppColors.CHART_BLUE : AppColors.MUTED)
          .borderRadius(1)
          .rotate({ angle: 28 })
          .margin({ top: 8, left: 16 })
        Circle()
          .width(5)
          .height(5)
          .fill(this.chartMode === mode ? AppColors.CHART_BLUE : AppColors.MUTED)
          .margin({ top: 11, left: 2 })
        Circle()
          .width(5)
          .height(5)
          .fill(this.chartMode === mode ? AppColors.CHART_BLUE : AppColors.MUTED)
          .margin({ top: 4, left: 14 })
        Circle()
          .width(5)
          .height(5)
          .fill(this.chartMode === mode ? AppColors.CHART_BLUE : AppColors.MUTED)
          .margin({ top: 10, left: 28 })
      }
      .width(34)
      .height(22)
    } else {
      Row({ space: 3 }) {
        Column()
          .width(2)
          .height(16)
          .backgroundColor('#D6E2EC')
          .borderRadius(1)
        Column()
          .width(5)
          .height(8)
          .backgroundColor(this.chartMode === mode ? AppColors.CHART_BLUE : AppColors.MUTED)
          .borderRadius(3)
        Column()
          .width(5)
          .height(15)
          .backgroundColor(this.chartMode === mode ? AppColors.CHART_BLUE : AppColors.MUTED)
          .borderRadius(3)
        Column()
          .width(5)
          .height(11)
          .backgroundColor(this.chartMode === mode ? AppColors.CHART_BLUE : AppColors.MUTED)
          .borderRadius(3)
      }
      .height(22)
      .alignItems(VerticalAlign.Bottom)
      .justifyContent(FlexAlign.Center)
      .width(34)
    }
  }

  private isWide(): boolean {
    return this.viewportWidth >= Breakpoints.WIDE;
  }

  private isPeriodSelected(period: StatisticsPeriod): boolean {
    if (this.customEditorVisible) {
      return period === StatisticsPeriod.CUSTOM;
    }
    return this.vm.period === period;
  }

  private chartCardWidth(): string {
    return this.isDesktop() ? '48%' : '100%';
  }

  private dimensionCardWidth(): string {
    return '31%';
  }

  private balanceCopy(): string {
    if (!this.hasFlowData()) {
      return '本期还没有账单，记录几笔后就能看到分类、趋势和变化。';
    }
    if (this.income <= 0) {
      return '本期只有支出、没有收入记录，建议补充收入或缩短统计周期查看。';
    }
    const rate = this.expenseRatePercent();
    const score = this.flowScore();
    if (score >= 85) {
      return `支出占收入 ${rate}%，结余充足，现金流状态优秀。`;
    }
    if (score >= 70) {
      return `支出占收入 ${rate}%，收入能够覆盖支出，现金流状态良好。`;
    }
    if (score >= 55) {
      return `支出占收入 ${rate}%，收支接近平衡，建议留意后续支出。`;
    }
    if (score >= 40) {
      return `支出占收入 ${rate}%，本期已经超支，建议检查高占比分类。`;
    }
    return `支出占收入 ${rate}%，超支较多，建议优先压缩非必要支出。`;
  }

  private flowScore(): number {
    if (!this.hasFlowData()) {
      return 0;
    }
    if (this.income <= 0) {
      return 25;
    }
    const expenseRate = Math.max(0, this.expense) / this.income;
    let score = 0;
    if (expenseRate <= 1) {
      score = 60 + (1 - expenseRate) * 40;
    } else {
      score = 60 - (expenseRate - 1) * 70;
    }
    return Math.max(20, Math.min(100, Math.round(score)));
  }

  private flowScoreText(): string {
    return this.hasFlowData() ? `${this.flowScore()}` : '--';
  }

  private hasFlowData(): boolean {
    return this.income > 0 || this.expense > 0;
  }

  private expenseRatePercent(): number {
    if (this.income <= 0) {
      return 100;
    }
    return Math.round(this.expense / this.income * 100);
  }

  private flowStatusText(): string {
    if (!this.hasFlowData()) {
      return '待记录';
    }
    const score = this.flowScore();
    if (score >= 85) {
      return '优秀';
    }
    if (score >= 70) {
      return '良好';
    }
    if (score >= 55) {
      return '平稳';
    }
    if (score >= 40) {
      return '偏高';
    }
    return '需关注';
  }

  private flowStatusColor(): string {
    const score = this.flowScore();
    if (!this.hasFlowData() || score >= 70) {
      return AppColors.CHART_BLUE;
    }
    if (score >= 55) {
      return AppColors.CHART_GREEN;
    }
    if (score >= 40) {
      return AppColors.WARNING;
    }
    return AppColors.EXPENSE;
  }

  private flowStatusBackground(): string {
    const score = this.flowScore();
    if (!this.hasFlowData() || score >= 70) {
      return AppColors.SURFACE_TINT;
    }
    if (score >= 55) {
      return '#E6F7EF';
    }
    if (score >= 40) {
      return '#FFF4DE';
    }
    return '#FFEAF0';
  }

  private primaryImpact(): string {
    if (this.categoryRanks.length > 0) {
      return this.categoryRanks[0].categoryName;
    }
    if (this.expense > this.income) {
      return '支出';
    }
    return '收入';
  }

  private isDesktop(): boolean {
    return this.viewportWidth >= Breakpoints.DESKTOP;
  }

  private isTablet(): boolean {
    return this.viewportWidth >= Breakpoints.TABLET && this.viewportWidth < Breakpoints.DESKTOP;
  }

  private isPhone(): boolean {
    return this.viewportWidth < Breakpoints.TABLET;
  }

  private contentMaxWidth(): number {
    return this.isDesktop() ? LayoutSizes.CONTENT_MAX : LayoutSizes.CONTENT_COMPACT;
  }

  private async exportPdf(): Promise<void> {
    try {
      const report = new StatisticsPdfReport();
      report.rangeLabel = this.dataRangeLabel || DateUtil.rangeLabel(DateUtil.startOfMonth(), DateUtil.startOfNextMonth());
      report.income = this.income;
      report.expense = this.expense;
      report.balance = this.balance;
      report.categoryRanks = this.categoryRanks;
      report.trendPoints = this.trendPoints;
      const context = getContext(this) as common.UIAbilityContext;
      const options = new picker.DocumentSaveOptions();
      options.newFileNames = [`一页账统计-${DateUtil.dayKey(Date.now())}.pdf`];
      options.fileSuffixChoices = ['PDF 文件|.pdf'];
      const uris = await new picker.DocumentViewPicker(context).save(options);
      if (uris.length === 0) {
        ToastUtil.show('未保存 PDF 文件');
        return;
      }
      StatisticsPdfExporter.exportToUri(uris[0], report);
      ToastUtil.show('PDF 文件已保存');
    } catch (error) {
      ToastUtil.show('PDF 未保存，请重新选择文件位置');
    }
  }

  private async refreshData(): Promise<void> {
    try {
      await AppDatabase.getInstance().init(getContext(this));
      await this.vm.refresh();
      this.income = this.vm.income;
      this.expense = this.vm.expense;
      this.balance = this.vm.balance;
      this.categoryRanks = this.vm.categoryRanks.slice();
      this.trendPoints = this.vm.trendPoints.slice();
      this.dataRangeLabel = this.vm.rangeLabel;
    } catch (error) {
      ToastUtil.show('统计数据加载失败，请稍后重试');
    }
  }

  private async changePeriod(period: StatisticsPeriod): Promise<void> {
    await this.vm.setPeriod(period);
    this.applyViewModelData();
  }

  private async movePrevious(): Promise<void> {
    await this.vm.movePrevious();
    this.applyViewModelData();
  }

  private async moveNext(): Promise<void> {
    await this.vm.moveNext();
    this.applyViewModelData();
  }

  private openCustomEditor(): void {
    this.draftCustomStartTime = this.vm.customStartTime;
    this.draftCustomEndTime = this.vm.customEndTime - 1;
    this.customEditorVisible = true;
  }

  private showCustomDatePicker(isStart: boolean): void {
    const current = new Date(isStart ? this.draftCustomStartTime : this.draftCustomEndTime);
    DatePickerDialog.show({
      selected: current,
      start: new Date(2000, 0, 1),
      end: new Date(2100, 11, 31),
      onAccept: (value: DatePickerResult) => {
        const timestamp = new Date(
          value.year ?? current.getFullYear(),
          value.month ?? current.getMonth(),
          value.day ?? current.getDate()
        ).getTime();
        if (isStart) {
          this.draftCustomStartTime = timestamp;
          if (timestamp > this.draftCustomEndTime) {
            this.draftCustomEndTime = timestamp;
          }
        } else {
          this.draftCustomEndTime = timestamp;
          if (timestamp < this.draftCustomStartTime) {
            this.draftCustomStartTime = timestamp;
          }
        }
      }
    });
  }

  private async applyCustomRange(): Promise<void> {
    this.customEditorVisible = false;
    await this.vm.setCustomRange(this.draftCustomStartTime, this.draftCustomEndTime);
    this.applyViewModelData();
  }

  private fullDateLabel(timestamp: number): string {
    const date = new Date(timestamp);
    const month = `${date.getMonth() + 1}`.padStart(2, '0');
    const day = `${date.getDate()}`.padStart(2, '0');
    return `${date.getFullYear()}/${month}/${day}`;
  }

  private applyViewModelData(): void {
    this.income = this.vm.income;
    this.expense = this.vm.expense;
    this.balance = this.vm.balance;
    this.categoryRanks = this.vm.categoryRanks.slice();
    this.trendPoints = this.vm.trendPoints.slice();
    this.dataRangeLabel = this.vm.rangeLabel;
  }
}
