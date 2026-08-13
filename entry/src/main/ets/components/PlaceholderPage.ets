import { router } from '@kit.ArkUI';
import { AppColors, AppRadius, AppSpace } from '../constants/DesignSystem';

@Component
export struct PlaceholderPage {
  @Prop title: string = '';
  @Prop description: string = '';

  build() {
    Column({ space: 18 }) {
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
        Column({ space: 5 }) {
          Text(this.title)
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.INK)
            .width('100%')
          Text('功能设置')
            .fontSize(13)
            .fontColor(AppColors.MUTED)
            .width('100%')
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }
      .width('100%')

      Column({ space: 14 }) {
        Text('账')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.LEDGER)
          .width(52)
          .height(52)
          .textAlign(TextAlign.Center)
          .borderRadius(18)
          .backgroundColor(AppColors.SURFACE_TINT)
        Text(this.title)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .width('100%')
        Text(this.description)
          .fontSize(14)
          .fontColor(AppColors.MUTED)
          .lineHeight(23)
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .padding(22)
      .backgroundColor(AppColors.SURFACE)
      .borderRadius(AppRadius.CARD)
      .shadow({ radius: 24, color: AppColors.SHADOW, offsetY: 10 })
      .width('100%')
    }
    .padding({ left: AppSpace.PAGE, right: AppSpace.PAGE, top: 40 })
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.CANVAS)
  }
}
