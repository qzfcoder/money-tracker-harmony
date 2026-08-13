import { TrendPoint } from '../repository/RecordRepository';
import { AppColors } from '../constants/DesignSystem';
import { NumberUtil } from '../utils/NumberUtil';

@Component
export struct LineChart {
  @Prop points: TrendPoint[] = [];
  @State viewportWidth: number = 0;
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
          .fontColor('#536D80')
        Blank()
        Text('X轴  时间')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor('#536D80')
      }
      .width('100%')

      Row({ space: 8 }) {
        this.YAxisLabels()

        Scroll() {
          Canvas(this.context)
            .id(this.canvasKey())
            .width(this.chartWidth())
            .height(this.chartHeight)
            .backgroundColor('#F7FBFF')
            .onReady(() => this.drawChart())
            .onAreaChange(() => this.drawChart())
        }
        .layoutWeight(1)
        .height(this.chartHeight)
        .backgroundColor('#F7FBFF')
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

      Text(this.maxValue() <= 0 ? '本期暂无收支变化' : '左右滑动查看收入与支出的连续变化')
        .fontSize(11)
        .fontColor(AppColors.MUTED)
        .width('100%')
    }
    .width('100%')
  }

  @Builder
  private ChartSummary() {
    Row() {
      Column({ space: 2 }) {
        Text('区间峰值')
          .fontSize(11)
          .fontColor(AppColors.MUTED)
        Text(NumberUtil.money(this.maxValue()))
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .maxLines(1)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text(this.points.length === 0 ? '无数据' : `${this.points.length} 个节点`)
        .fontSize(11)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.CHART_BLUE)
        .padding({ left: 10, right: 10, top: 5, bottom: 5 })
        .backgroundColor('#EAF4FF')
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
      Text('平滑曲线')
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
        .fontColor('#536D80')
      Text(this.axisText(this.axisMax() / 2))
        .fontSize(13)
        .fontColor('#536D80')
      Text('0')
        .fontSize(13)
        .fontColor('#536D80')
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
    this.context.fillStyle = '#F7FBFF';
    this.context.fillRect(0, 0, width, height);
    this.context.lineCap = 'round';
    this.context.lineJoin = 'round';
    this.drawGrid(left, top, plotWidth, plotHeight);

    if (this.points.length === 0 || this.maxValue() <= 0) {
      this.drawEmpty(width, top, plotHeight);
      this.drawXLabels(left, top, plotWidth, plotHeight);
      return;
    }

    this.drawSeries(left, top, plotWidth, plotHeight, max, AppColors.CHART_GREEN, true);
    this.drawSeries(left, top, plotWidth, plotHeight, max, AppColors.CHART_PINK, false);
    this.drawXLabels(left, top, plotWidth, plotHeight);
  }

  private drawGrid(left: number, top: number, plotWidth: number, plotHeight: number): void {
    this.context.strokeStyle = '#D9E7F2';
    this.context.lineWidth = 0.6;
    for (let index = 0; index <= 2; index++) {
      const y = top + plotHeight / 2 * index;
      this.context.beginPath();
      this.context.moveTo(left, y);
      this.context.lineTo(left + plotWidth, y);
      this.context.stroke();
    }

    this.context.strokeStyle = '#6D879A';
    this.context.lineWidth = 1;
    this.context.beginPath();
    this.context.moveTo(left, top);
    this.context.lineTo(left, top + plotHeight);
    this.context.lineTo(left + plotWidth, top + plotHeight);
    this.context.stroke();
  }

  private drawSeries(left: number, top: number, plotWidth: number, plotHeight: number, max: number,
    color: string, useIncome: boolean): void {
    if (this.points.length === 0) {
      return;
    }
    const slotWidth = plotWidth / this.points.length;
    this.context.beginPath();
    this.context.lineWidth = 2.2;
    this.context.strokeStyle = color;

    const first = this.points[0];
    this.context.moveTo(
      left + slotWidth / 2,
      this.pointY(top, plotHeight, max, useIncome ? first.income : first.expense)
    );

    for (let index = 0; index < this.points.length - 1; index++) {
      const previousIndex = index === 0 ? 0 : index - 1;
      const nextIndex = index + 2 >= this.points.length ? this.points.length - 1 : index + 2;
      const previousPoint = this.points[previousIndex];
      const startPoint = this.points[index];
      const endPoint = this.points[index + 1];
      const nextPoint = this.points[nextIndex];
      const previousX = left + slotWidth * previousIndex + slotWidth / 2;
      const startX = left + slotWidth * index + slotWidth / 2;
      const endX = left + slotWidth * (index + 1) + slotWidth / 2;
      const nextX = left + slotWidth * nextIndex + slotWidth / 2;
      const previousY = this.pointY(top, plotHeight, max, useIncome ? previousPoint.income : previousPoint.expense);
      const startY = this.pointY(top, plotHeight, max, useIncome ? startPoint.income : startPoint.expense);
      const endY = this.pointY(top, plotHeight, max, useIncome ? endPoint.income : endPoint.expense);
      const nextY = this.pointY(top, plotHeight, max, useIncome ? nextPoint.income : nextPoint.expense);
      const control1X = startX + (endX - previousX) / 6;
      const control1Y = this.clampY(startY + (endY - previousY) / 6, top, top + plotHeight);
      const control2X = endX - (nextX - startX) / 6;
      const control2Y = this.clampY(endY - (nextY - startY) / 6, top, top + plotHeight);
      this.context.bezierCurveTo(control1X, control1Y, control2X, control2Y, endX, endY);
    }
    this.context.stroke();

    this.points.forEach((point: TrendPoint, index: number) => {
      const x = left + slotWidth * index + slotWidth / 2;
      const value = useIncome ? point.income : point.expense;
      const y = this.pointY(top, plotHeight, max, value);
      this.context.beginPath();
      this.context.fillStyle = AppColors.SURFACE;
      this.context.arc(x, y, 3.5, 0, Math.PI * 2);
      this.context.fill();
      this.context.beginPath();
      this.context.fillStyle = color;
      this.context.arc(x, y, 2, 0, Math.PI * 2);
      this.context.fill();
    });
  }

  private drawXLabels(left: number, top: number, plotWidth: number, plotHeight: number): void {
    const slotWidth = plotWidth / Math.max(1, this.points.length);
    const y = top + plotHeight + 22;
    this.context.fillStyle = '#536D80';
    this.context.font = `bold ${vp2px(12)}px sans-serif`;
    this.context.textAlign = 'center';
    this.points.forEach((point: TrendPoint, index: number) => {
      const x = left + slotWidth * index + slotWidth / 2;
      this.context.fillText(this.shortLabel(point.label), x, y);
    });
  }

  private drawEmpty(width: number, top: number, plotHeight: number): void {
    this.context.fillStyle = AppColors.MUTED;
    this.context.font = `${vp2px(13)}px sans-serif`;
    this.context.textAlign = 'center';
    this.context.fillText('暂无收支变化', Math.min(width / 2, 150), top + plotHeight / 2);
  }

  private pointY(top: number, plotHeight: number, max: number, value: number): number {
    return top + plotHeight - value / max * plotHeight;
  }

  private clampY(value: number, min: number, max: number): number {
    return Math.max(min, Math.min(max, value));
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
    return `line-chart-${first}-${last}-${this.points.length}-${this.maxValue()}`;
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
