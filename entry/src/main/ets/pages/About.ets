import { router } from '@kit.ArkUI';
import { AppColors, AppRadius, AppSpace, LayoutSizes } from '../constants/DesignSystem';
import { FeatureFlags } from '../constants/FeatureFlags';

@Entry
@Component
struct About {
  build() {
    Column() {
      this.Header('关于')

      Scroll() {
        Column({ space: 16 }) {
          this.BrandCard()
          this.InfoCard()
          this.PolicyCard()
        }
        .width('100%')
        .constraintSize({ maxWidth: LayoutSizes.CONTENT_MAX })
        .alignSelf(ItemAlign.Center)
        .padding({ left: AppSpace.PAGE, right: AppSpace.PAGE, top: 12, bottom: 24 })
      }
      .layoutWeight(1)
      .backgroundColor(AppColors.CANVAS)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.CANVAS)
  }

  @Builder
  private Header(title: string) {
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
      Column({ space: 2 }) {
        Text(title)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .width('100%')
        Text('版本与说明')
          .fontSize(13)
          .fontColor(AppColors.MUTED)
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
    }
    .width('100%')
    .padding({ left: AppSpace.PAGE, right: AppSpace.PAGE, top: 22 })
  }

  @Builder
  private BrandCard() {
    Column({ space: 14 }) {
      Text('账')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.LEDGER)
        .width(54)
        .height(54)
        .textAlign(TextAlign.Center)
        .borderRadius(27)
        .backgroundColor(AppColors.SURFACE_TINT)
      Text('一页账')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.INK)
        .width('100%')
      Text(FeatureFlags.AUTO_BOOKKEEPING_VISIBLE ? '专注日常收支、统计分析、账户管理和主动识别辅助。' : '专注日常收支、统计分析、预算和账户管理。')
        .fontSize(13)
        .fontColor(AppColors.MUTED)
        .width('100%')
        .lineHeight(22)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(18)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 24, color: AppColors.SHADOW, offsetY: 10 })
  }

  @Builder
  private InfoCard() {
    Column({ space: 12 }) {
      this.InfoRow('版本', '1.0.1')
      this.InfoRow('数据结构', '账单 / 分类 / 账户 / 预算')
      this.InfoRow('系统能力', '按需调用')
      if (FeatureFlags.AUTO_BOOKKEEPING_VISIBLE) {
        this.InfoRow('主动识别', '先待确认，再手动入账')
        this.InfoRow('OCR 文本', '仅用于本机规则匹配')
      }
      this.InfoRow('数据导出', '支持 CSV / 备份')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 20, color: AppColors.SHADOW, offsetY: 8 })
  }

  @Builder
  private InfoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(13)
        .fontColor(AppColors.MUTED)
      Blank()
      Text(value)
        .fontSize(13)
        .fontColor(AppColors.INK)
    }
    .width('100%')
  }

  @Builder
  private PolicyCard() {
    Column({ space: 14 }) {
      Text('数据说明')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.INK)
        .width('100%')
      this.PolicySection('数据说明', '一页账用于记录收支、预算、账户和统计数据。账单数据保存在应用数据区，用于页面展示、筛选、统计和导出。')
      this.PolicySection('文件处理', '导出 CSV 或报表时会调用系统文件选择器，由用户主动选择保存位置。')
      if (FeatureFlags.AUTO_BOOKKEEPING_VISIBLE) {
        this.PolicySection('主动识别', '开启主动识别后，用户手动选择账单截图，OCR 文本仅在本机解析，识别结果先进入待确认账单，用户确认后才入账。')
      } else {
        this.PolicySection('本地使用', '当前版本以手动记账、统计和导出为主，账单数据用于本机页面展示和用户主动导出。')
      }
      this.PolicySection('用户控制', '用户可以编辑、删除账单，导出 CSV 文件，也可以通过系统卸载应用清除应用数据。')
      Text('正式上架时，请在华为 AGC 控制台按应用市场要求配置对应说明链接，并保持内容与本页说明一致。')
        .fontSize(12)
        .fontColor(AppColors.MUTED)
        .lineHeight(20)
        .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 20, color: AppColors.SHADOW, offsetY: 8 })
  }

  @Builder
  private PolicySection(title: string, content: string) {
    Column({ space: 4 }) {
      Text(title)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.INK)
        .width('100%')
      Text(content)
        .fontSize(13)
        .fontColor(AppColors.MUTED)
        .lineHeight(20)
        .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
