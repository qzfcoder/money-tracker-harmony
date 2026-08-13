import { router } from '@kit.ArkUI';
import { AppColors, AppRadius, AppSpace, Breakpoints, LayoutSizes } from '../constants/DesignSystem';
import { FeatureFlags } from '../constants/FeatureFlags';
import { ROUTES } from '../constants/RouteConstants';

@Entry
@Component
struct Profile {
  @State viewportWidth: number = 0;

  build() {
    Column() {
      Scroll() {
        Column({ space: 18 }) {
          this.Header('我的')
          this.IntroCard()
          this.SectionTitle('常用功能', '快捷管理')
          this.ShortcutGrid()
        }
        .width('100%')
        .constraintSize({ maxWidth: this.contentMaxWidth() })
        .alignSelf(ItemAlign.Center)
        .padding({ left: AppSpace.PAGE, right: AppSpace.PAGE, top: 24, bottom: 24 })
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
      Column({ space: 5 }) {
        Text(title)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .width('100%')
        Text('设置与数据')
          .fontSize(13)
          .fontColor(AppColors.MUTED)
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  private IntroCard() {
    Column({ space: 14 }) {
      Row() {
        Text('账')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.LEDGER)
          .width(54)
          .height(54)
          .textAlign(TextAlign.Center)
          .borderRadius(27)
          .backgroundColor(AppColors.SURFACE_TINT)
        Blank()
        Text('轻量好用')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.LEDGER)
          .padding({ left: 14, right: 14, top: 6, bottom: 6 })
          .backgroundColor(AppColors.SURFACE_TINT)
          .borderRadius(AppRadius.PILL)
      }
      .width('100%')

      Text('我的账本')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.INK)
        .width('100%')
      Text('管理分类、预算、导出和偏好设置。')
        .fontSize(14)
        .fontColor(AppColors.MUTED)
        .lineHeight(22)
        .width('100%')
    }
    .width('100%')
    .padding(18)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 24, color: AppColors.SHADOW, offsetY: 10 })
  }

  @Builder
  private SectionTitle(title: string, badge: string) {
    Row() {
      Text(title)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.INK)
      Blank()
      Text(badge)
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
  private ShortcutGrid() {
    Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
      this.ShortcutCard('收支日历', '查看每日收入支出', '日', AppColors.LILAC, '#EEEAFE', ROUTES.CALENDAR)
      this.ShortcutCard('分类管理', '调整常用分类', '类', AppColors.LEDGER, AppColors.SURFACE_TINT, ROUTES.CATEGORY_MANAGE)
      this.ShortcutCard('账户管理', '维护账户余额', '户', AppColors.CHART_CYAN, '#E5F8F6', ROUTES.ACCOUNT_MANAGE)
      this.ShortcutCard('预算管理', '控制月度支出', '预', AppColors.WARNING, '#FFF5DF', ROUTES.BUDGET_SETTING)
      if (FeatureFlags.AUTO_BOOKKEEPING_VISIBLE) {
        this.ShortcutCard('主动识别记账', '截图 OCR', '识', AppColors.CHART_BLUE, '#EAF4FF', ROUTES.AUTO_BOOKKEEPING)
      }
      this.ShortcutCard('数据导出与备份', '导出账单和恢复备份', '备', AppColors.INCOME, '#E6F6F0', ROUTES.DATA_EXPORT)
      this.ShortcutCard('设置', '主题与提醒', '设', AppColors.LILAC, '#EEEAFE', ROUTES.SETTINGS)
      this.ShortcutCard('关于', '版本与说明', '关', AppColors.MUTED, AppColors.SURFACE_SOFT, ROUTES.ABOUT)
    }
    .width('100%')
  }

  @Builder
  private ShortcutCard(label: string, subtitle: string, mark: string, color: string, bgColor: string, url: string) {
    Row({ space: 12 }) {
      Text(mark)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
        .width(44)
        .height(44)
        .textAlign(TextAlign.Center)
        .borderRadius(22)
        .backgroundColor(bgColor)
      Column({ space: 4 }) {
        Text(label)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .width('100%')
          .maxLines(1)
        Text(subtitle)
          .fontSize(12)
          .fontColor(AppColors.MUTED)
          .width('100%')
          .maxLines(1)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Text('›')
        .fontSize(22)
        .fontColor(AppColors.FAINT)
    }
    .width(this.cardWidth())
    .height(68)
    .padding({ left: 16, right: 16 })
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 18, color: AppColors.SHADOW, offsetY: 8 })
    .margin({ bottom: 12 })
    .onClick(() => router.pushUrl({ url }))
  }

  private cardWidth(): string {
    return this.viewportWidth >= Breakpoints.WIDE ? '48%' : '100%';
  }

  private contentMaxWidth(): number {
    return this.viewportWidth >= Breakpoints.DESKTOP ? LayoutSizes.CONTENT_MAX : LayoutSizes.CONTENT_COMPACT;
  }
}
