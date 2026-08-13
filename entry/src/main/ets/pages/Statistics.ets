import { router } from '@kit.ArkUI';
import { StatisticsDashboard } from '../components/StatisticsDashboard';
import { AppColors, AppSpace, LayoutSizes } from '../constants/DesignSystem';

@Entry
@Component
struct Statistics {
  @State refreshKey: number = 0;

  onPageShow(): void {
    this.refreshKey++;
  }

  build() {
    Column() {
      Column({ space: 6 }) {
        Button('‹')
          .fontSize(28)
          .fontColor(AppColors.CHART_BLUE)
          .width(46)
          .height(46)
          .backgroundColor(AppColors.SURFACE)
          .borderRadius(23)
          .shadow({ radius: 14, color: AppColors.SHADOW, offsetY: 6 })
          .alignSelf(ItemAlign.Start)
          .onClick(() => router.back())
        Column({ space: 2 }) {
          Text('统计')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.INK)
            .width('100%')
          Text('按时间查看收支变化')
            .fontSize(13)
            .fontColor(AppColors.MUTED)
            .width('100%')
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }
      .padding({ left: AppSpace.PAGE, right: AppSpace.PAGE, top: 34 })
      .width('100%')
      .constraintSize({ maxWidth: LayoutSizes.CONTENT_MAX })
      .alignSelf(ItemAlign.Center)

      StatisticsDashboard({ showHeader: false, active: true, refreshKey: this.refreshKey })
        .layoutWeight(1)
        .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.CANVAS)
  }
}
