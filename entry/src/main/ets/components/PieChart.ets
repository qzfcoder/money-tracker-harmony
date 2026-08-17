import { CategoryRankItem } from '../viewmodel/StatisticsViewModel';
import { AppColors } from '../constants/DesignSystem';
import { NumberUtil } from '../utils/NumberUtil';

@Component
export struct PieChart {
  @Prop items: CategoryRankItem[] = [];
  @State viewportWidth: number = 0;
  @StorageLink('ledgerIsDarkMode') isDarkMode: boolean = false;
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  build() {
    Column({ space: this.isPhone() ? 12 : 20 }) {
      Column({ space: 12 }) {
        Row() {
          Column({ space: 5 }) {
            Text('总支出')
              .fontSize(13)
              .fontColor(AppColors.MUTED)
              .width('100%')
            Text(NumberUtil.compactMoney(this.totalAmount()))
              .fontSize(this.totalFontSize())
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.INK)
              .width('100%')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Column({ space: 4 }) {
            Text(`${this.totalRecords()} 笔`)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.CHART_BLUE)
            Text('支出记录')
              .fontSize(12)
              .fontColor(AppColors.MUTED)
          }
          .alignItems(HorizontalAlign.End)
        }
        .width('100%')

        Stack({ alignContent: Alignment.Center }) {
          Canvas(this.context)
            .id(this.canvasKey())
            .width('100%')
            .height(this.chartHeight())
            .backgroundColor(AppColors.PANEL)
            .borderRadius(24)
            .onReady(() => this.drawChart())
            .onAreaChange(() => this.drawChart())

          if (this.items.length > 0) {
            Column({ space: 3 }) {
              Text('支出')
                .fontSize(12)
                .fontColor(AppColors.MUTED)
              Text(NumberUtil.compactMoney(this.totalAmount()))
                .fontSize(this.centerFontSize())
                .fontWeight(FontWeight.Bold)
                .fontColor(AppColors.INK)
                .width(this.centerTextWidth())
                .textAlign(TextAlign.Center)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
          } else {
            Text('暂无支出数据')
              .fontSize(14)
              .fontColor(AppColors.MUTED)
          }
        }
        .height(this.chartHeight())
        .width('100%')

        Text(this.items.length === 0 ? '记录支出后会显示分类占比' : `最高分类：${this.primaryName()}，占 ${this.primaryPercent()}`)
          .fontSize(13)
          .fontColor(AppColors.MUTED)
          .width('100%')
          .maxLines(1)
      }
      .width('100%')
      .padding(this.isPhone() ? 12 : 18)
      .backgroundColor(AppColors.PANEL)
      .borderRadius(24)

      if (this.items.length > 0) {
        Text('分类图例')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.MUTED)
          .width('100%')
        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
          ForEach(this.items.slice(0, 6), (item: CategoryRankItem, index: number) => {
            this.LegendItem(item, index)
          }, (item: CategoryRankItem) => `${item.categoryId}`)
        }
        .width('100%')
      } else {
        Blank()
          .height(0)
      }
    }
    .width('100%')
    .onAreaChange((oldValue, newValue) => {
      this.viewportWidth = parseFloat(`${newValue.width}`);
    })
  }

  @Builder
  private LegendItem(item: CategoryRankItem, index: number) {
    Column({ space: 7 }) {
      Row({ space: 8 }) {
        Text(item.categoryName.substring(0, 1))
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.rankColorByIndex(index))
          .width(this.isPhone() ? 30 : 36)
          .height(this.isPhone() ? 30 : 36)
          .textAlign(TextAlign.Center)
          .borderRadius(this.isPhone() ? 15 : 18)
          .backgroundColor(this.rankBgByIndex(index))
        Column({ space: 2 }) {
          Text(item.categoryName)
            .fontSize(this.isPhone() ? 12 : 14)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.INK)
            .width('100%')
            .maxLines(1)
          Text(`${item.recordCount} 笔 · ${item.percent}%`)
            .fontSize(10)
            .fontColor(AppColors.MUTED)
            .width('100%')
            .maxLines(1)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      Stack({ alignContent: Alignment.Start }) {
        Column()
          .width('100%')
          .height(6)
          .backgroundColor(AppColors.SURFACE_SOFT)
          .borderRadius(3)
        Column()
          .width(this.percentWidth(item.percent))
          .height(6)
          .backgroundColor(this.rankColorByIndex(index))
          .borderRadius(3)
      }
      .height(6)
      .width('100%')
    }
    .height(this.isPhone() ? 54 : 64)
    .width(this.isPhone() ? '48%' : '100%')
    .margin({ bottom: this.isPhone() ? 6 : 0 })
  }

  private primaryName(): string {
    return this.items.length > 0 ? this.items[0].categoryName : '暂无';
  }

  private drawChart(): void {
    const width = Math.max(1, this.context.width);
    const height = Math.max(1, this.context.height);
    this.context.clearRect(0, 0, width, height);
    this.context.fillStyle = AppColors.PANEL;
    this.context.fillRect(0, 0, width, height);
    if (this.items.length === 0) {
      return;
    }

    const total = this.totalAmount();
    if (total <= 0) {
      return;
    }
    const centerX = width / 2;
    const centerY = height / 2;
    const radius = Math.min(width, height) / 2 - 18;
    let startAngle = -Math.PI / 2;
    this.items.slice(0, 8).forEach((item: CategoryRankItem, index: number) => {
      const sweep = item.amount / total * Math.PI * 2;
      this.context.beginPath();
      this.context.moveTo(centerX, centerY);
      this.context.arc(centerX, centerY, radius, startAngle, startAngle + sweep);
      this.context.closePath();
      this.context.fillStyle = this.rankColorByIndex(index);
      this.context.fill();
      this.context.strokeStyle = AppColors.PANEL;
      this.context.lineWidth = 2;
      this.context.stroke();
      startAngle += sweep;
    });

    this.context.beginPath();
    this.context.arc(centerX, centerY, radius * 0.66, 0, Math.PI * 2);
    this.context.fillStyle = AppColors.PANEL;
    this.context.fill();
  }

  private primaryPercent(): string {
    return this.items.length > 0 ? `${this.items[0].percent}%` : '0%';
  }

  private totalAmount(): number {
    let amount = 0;
    this.items.forEach((item: CategoryRankItem) => {
      amount += item.amount;
    });
    return amount;
  }

  private totalRecords(): number {
    let count = 0;
    this.items.forEach((item: CategoryRankItem) => {
      count += item.recordCount;
    });
    return count;
  }

  private percentWidth(percent: number): string {
    return `${Math.max(6, Math.min(100, percent))}%`;
  }

  private isPhone(): boolean {
    return this.viewportWidth < 840;
  }

  private chartHeight(): number {
    if (this.items.length === 0) {
      return this.isPhone() ? 108 : 150;
    }
    return this.isPhone() ? 174 : 214;
  }

  private totalFontSize(): number {
    const length = NumberUtil.compactMoney(this.totalAmount()).length;
    if (!this.isPhone()) {
      return length <= 12 ? 30 : 25;
    }
    return length <= 10 ? 28 : 23;
  }

  private centerFontSize(): number {
    const length = NumberUtil.compactMoney(this.totalAmount()).length;
    if (this.isPhone()) {
      return length <= 8 ? 17 : 15;
    }
    return length <= 10 ? 20 : 17;
  }

  private centerTextWidth(): number {
    return this.isPhone() ? 92 : 118;
  }

  private canvasKey(): string {
    return `pie-chart-${this.items.length}-${this.totalAmount()}-${this.totalRecords()}-${this.isDarkMode}`;
  }

  private rankColorByIndex(index: number): string {
    const colors: string[] = [
      AppColors.CHART_PINK,
      AppColors.CHART_ORANGE,
      AppColors.CHART_BLUE,
      AppColors.CHART_CYAN,
      AppColors.CHART_PURPLE,
      AppColors.CHART_GREEN
    ];
    return colors[index % colors.length];
  }

  private rankBgByIndex(index: number): string {
    const colors: string[] = [
      AppColors.softPink(),
      AppColors.softYellow(),
      AppColors.softBlue(),
      AppColors.softCyan(),
      AppColors.softPurple(),
      AppColors.softGreen()
    ];
    return colors[index % colors.length];
  }
}
