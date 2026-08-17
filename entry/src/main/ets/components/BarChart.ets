import { TrendPoint } from '../repository/RecordRepository';
import { AppColors } from '../constants/DesignSystem';
import { NumberUtil } from '../utils/NumberUtil';

@Component
export struct BarChart {
  @Prop @Watch('onPointsChanged') points: TrendPoint[] = [];
  @Prop @Watch('onTotalsChanged') totalIncome: number = 0;
  @Prop @Watch('onTotalsChanged') totalExpense: number = 0;
  @Prop @Watch('onRefreshKeyChanged') refreshKey: number = 0;
  @State viewportWidth: number = 0;
  @StorageLink('ledgerIsDarkMode') isDarkMode: boolean = false;
  private readonly chartHeight: number = 196;
  private readonly plotTop: number = 10;
  private readonly plotBottom: number = 34;
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  build() {
    Column({ space: 12 }) {
      this.ChartSummary()
      this.LegendRow()

      Row() {
        Text('Y轴  金额（元）')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.MUTED)
        Blank()
        Text('X轴  时间')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.MUTED)
      }
      .width('100%')

      Row({ space: 8 }) {
        this.YAxisLabels()

        Scroll() {
          Canvas(this.context)
            .id(this.canvasKey())
            .width(this.chartWidth())
            .height(this.chartHeight)
            .backgroundColor(AppColors.PANEL)
            .onReady(() => this.drawChart())
            .onAreaChange(() => this.drawChart())
        }
        .layoutWeight(1)
        .height(this.chartHeight)
        .backgroundColor(AppColors.PANEL)
        .borderRadius(16)
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Auto)
        .onAreaChange((oldValue, newValue) => {
          const width = parseFloat(`${newValue.width}`);
          if (width > 0 && Math.abs(width - this.viewportWidth) > 1) {
            this.viewportWidth = width;
          }
        })
      }
      .width('100%')
      .height(this.chartHeight)

      Text(this.maxValue() <= 0 ? '本期暂无收支变化' : '左右滑动查看每个时间点的收支对比')
        .fontSize(11)
        .fontColor(AppColors.MUTED)
        .width('100%')
    }
    .width('100%')
  }

  @Builder
  private ChartSummary() {
    Row() {
      Row({ space: 14 }) {
        Column({ space: 2 }) {
          Text('本期收入')
            .fontSize(11)
            .fontColor(AppColors.MUTED)
          Text(NumberUtil.money(this.totalIncome))
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.CHART_GREEN)
            .maxLines(1)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Column({ space: 2 }) {
          Text('本期支出')
            .fontSize(11)
            .fontColor(AppColors.MUTED)
          Text(NumberUtil.money(this.totalExpense))
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.CHART_PINK)
            .maxLines(1)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .layoutWeight(1)

      Text(this.points.length === 0 ? '无数据' : `${this.points.length} 组`)
        .fontSize(11)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.CHART_BLUE)
        .padding({ left: 10, right: 10, top: 5, bottom: 5 })
        .backgroundColor(AppColors.softBlue())
        .borderRadius(999)
    }
    .width('100%')
  }

  @Builder
  private LegendRow() {
    Row({ space: 14 }) {
      this.Legend('收入', AppColors.CHART_GREEN)
      this.Legend('支出', AppColors.CHART_PINK)
      Blank()
      Text('柱高对应金额')
        .fontSize(11)
        .fontColor(AppColors.MUTED)
    }
    .width('100%')
  }

  @Builder
  private Legend(label: string, color: string) {
    Row({ space: 6 }) {
      Circle()
        .width(8)
        .height(8)
        .fill(color)
      Text(label)
        .fontSize(12)
        .fontColor(AppColors.MUTED)
    }
  }

  @Builder
  private YAxisLabels() {
    Column() {
      Text(this.axisText(this.axisMax()))
        .fontSize(13)
        .fontColor(AppColors.MUTED)
      Text(this.axisText(this.axisMax() / 2))
        .fontSize(13)
        .fontColor(AppColors.MUTED)
      Text('0')
        .fontSize(13)
        .fontColor(AppColors.MUTED)
    }
    .width(42)
    .height(this.chartHeight - this.plotTop - this.plotBottom)
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(HorizontalAlign.End)
    .margin({ top: this.plotTop, bottom: this.plotBottom })
  }

  private drawChart(): void {
    const width = this.chartWidth();
    const height = this.chartHeight;
    const left = 8;
    const right = 12;
    const top = this.plotTop;
    const bottom = this.plotBottom;
    const plotWidth = Math.max(1, width - left - right);
    const plotHeight = Math.max(1, height - top - bottom);
    const max = this.axisMax();

    this.context.clearRect(0, 0, width, height);
    this.context.fillStyle = AppColors.PANEL;
    this.context.fillRect(0, 0, width, height);
    this.drawGrid(left, top, plotWidth, plotHeight);

    if (this.points.length === 0 || this.maxValue() <= 0) {
      this.drawEmpty(width, top, plotHeight);
      this.drawXLabels(left, top, plotWidth, plotHeight);
      return;
    }

    const slotWidth = plotWidth / this.points.length;
    const barWidth = Math.min(10, slotWidth * 0.24);
    const gap = 3;
    this.points.forEach((point: TrendPoint, index: number) => {
      const centerX = left + slotWidth * index + slotWidth / 2;
      this.drawBar(centerX - gap / 2 - barWidth, top, plotHeight, max, point.income, barWidth,
        AppColors.CHART_GREEN);
      this.drawBar(centerX + gap / 2, top, plotHeight, max, point.expense, barWidth,
        AppColors.CHART_PINK);
      this.drawXLabel(point.label, centerX, top + plotHeight + 22);
    });
  }

  private onPointsChanged(): void {
    setTimeout(() => {
      this.drawChart();
    }, 0);
  }

  private onRefreshKeyChanged(): void {
    setTimeout(() => {
      this.drawChart();
    }, 0);
  }

  private onTotalsChanged(): void {
    setTimeout(() => {
      this.drawChart();
    }, 0);
  }

  private drawGrid(left: number, top: number, plotWidth: number, plotHeight: number): void {
    this.context.strokeStyle = AppColors.LINE;
    this.context.lineWidth = 0.6;
    for (let index = 0; index <= 2; index++) {
      const y = top + plotHeight / 2 * index;
      this.context.beginPath();
      this.context.moveTo(left, y);
      this.context.lineTo(left + plotWidth, y);
      this.context.stroke();
    }

    this.context.strokeStyle = AppColors.MUTED;
    this.context.lineWidth = 1;
    this.context.beginPath();
    this.context.moveTo(left, top);
    this.context.lineTo(left, top + plotHeight);
    this.context.lineTo(left + plotWidth, top + plotHeight);
    this.context.stroke();
  }

  private drawBar(x: number, top: number, plotHeight: number, max: number, value: number,
    width: number, color: string): void {
    if (value <= 0) {
      return;
    }
    const height = Math.max(3, value / max * plotHeight);
    const y = top + plotHeight - height;
    const radius = Math.min(width / 2, height / 2);
    this.context.fillStyle = color;
    this.context.fillRect(x, y + radius, width, Math.max(0, height - radius));
    this.context.beginPath();
    this.context.arc(x + width / 2, y + radius, radius, Math.PI, Math.PI * 2);
    this.context.fill();
  }

  private drawXLabel(label: string, x: number, y: number): void {
    this.context.fillStyle = AppColors.MUTED;
    this.context.font = `bold ${vp2px(12)}px sans-serif`;
    this.context.textAlign = 'center';
    this.context.fillText(this.shortLabel(label), x, y);
  }

  private drawXLabels(left: number, top: number, plotWidth: number, plotHeight: number): void {
    const slotWidth = plotWidth / Math.max(1, this.points.length);
    this.points.forEach((point: TrendPoint, index: number) => {
      const x = left + slotWidth * index + slotWidth / 2;
      this.drawXLabel(point.label, x, top + plotHeight + 22);
    });
  }

  private drawEmpty(width: number, top: number, plotHeight: number): void {
    this.context.fillStyle = AppColors.MUTED;
    this.context.font = `${vp2px(13)}px sans-serif`;
    this.context.textAlign = 'center';
    this.context.fillText('暂无收支变化', Math.min(width / 2, 150), top + plotHeight / 2);
  }

  private maxValue(): number {
    let max = 0;
    this.points.forEach((point: TrendPoint) => {
      max = Math.max(max, point.income, point.expense);
    });
    return max;
  }

  private axisMax(): number {
    const max = this.maxValue();
    if (max <= 0) {
      return 100;
    }
    return max;
  }

  private chartWidth(): number {
    const visibleWidth = Math.max(280, this.viewportWidth);
    return Math.max(visibleWidth, this.points.length * 50 + 16);
  }

  private axisText(value: number): string {
    if (value >= 10000) {
      return `${Math.round(value / 1000)}k`;
    }
    if (value >= 1000) {
      return `${(value / 1000).toFixed(1)}k`;
    }
    return `${Math.round(value)}`;
  }

  private canvasKey(): string {
    const first = this.points.length > 0 ? this.points[0].label : 'empty';
    const last = this.points.length > 0 ? this.points[this.points.length - 1].label : 'empty';
    return `bar-chart-${first}-${last}-${this.points.length}-${this.maxValue()}-${this.totalValue()}-${this.totalIncome}-${this.totalExpense}-${this.refreshKey}-${this.isDarkMode}`;
  }

  private totalValue(): number {
    let total = 0;
    this.points.forEach((point: TrendPoint) => {
      total += point.income + point.expense;
    });
    return Math.round(total * 100);
  }

  private shortLabel(label: string): string {
    if (label.length >= 10) {
      return label.substring(5).replace('-', '/');
    }
    if (label.length === 7) {
      return label.substring(5);
    }
    return label;
  }
}
