import { router } from '@kit.ArkUI';
import { AssetsViewModel } from '../viewmodel/AssetsViewModel';
import { AccountModel } from '../model/Account';
import { NumberUtil } from '../utils/NumberUtil';
import { AppColors, AppRadius, AppSpace, Breakpoints, LayoutSizes } from '../constants/DesignSystem';
import { ROUTES } from '../constants/RouteConstants';

@Entry
@Component
struct Assets {
  @State vm: AssetsViewModel = new AssetsViewModel();
  @State viewportWidth: number = 0;

  aboutToAppear(): void {
    this.vm.refresh();
  }

  build() {
    Column() {
      Scroll() {
        Column({ space: 18 }) {
          this.Header('资产')
          this.SummaryCard()
          this.SectionTitle('账户列表', `${this.vm.accounts.length} 个`)
          this.AccountGrid()
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
        Text('账户与余额')
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
  private SummaryCard() {
    Column({ space: 18 }) {
      Row() {
        Text('卡')
          .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.LEDGER)
        .width(54)
        .height(54)
        .textAlign(TextAlign.Center)
        .borderRadius(27)
        .backgroundColor(AppColors.SURFACE_TINT)
        Blank()
        Text('管理')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.CHART_BLUE)
          .padding({ left: 14, right: 14, top: 6, bottom: 6 })
          .backgroundColor(AppColors.SURFACE_TINT)
          .borderRadius(AppRadius.PILL)
          .onClick(() => router.pushUrl({ url: ROUTES.ACCOUNT_MANAGE }))
      }
      .width('100%')

      Column({ space: 5 }) {
        Text('净资产')
          .fontSize(13)
          .fontColor(AppColors.MUTED)
          .width('100%')
        Text(NumberUtil.compactMoney(this.vm.totalAssets))
          .fontSize(36)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .width('100%')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(`${this.vm.accounts.length} 个账户，账户余额一目了然`)
          .fontSize(13)
          .fontColor(AppColors.MUTED)
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
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
  private AccountGrid() {
    Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
      ForEach(this.vm.accounts, (item: AccountModel) => {
        this.AccountCard(item)
      }, (item: AccountModel) => `${item.id}`)
    }
    .width('100%')
  }

  @Builder
  private AccountCard(item: AccountModel) {
    Row({ space: 12 }) {
      Text(item.name.substring(0, 1))
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(item.color)
        .width(44)
        .height(44)
        .textAlign(TextAlign.Center)
        .borderRadius(22)
        .backgroundColor(AppColors.SURFACE_TINT)
      Column({ space: 4 }) {
        Text(item.name)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .width('100%')
          .maxLines(1)
        Text(item.isLiability ? '负债账户' : '资产账户')
          .fontSize(12)
          .fontColor(AppColors.MUTED)
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Text(NumberUtil.compactMoney(item.balance))
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(item.isLiability ? AppColors.EXPENSE : AppColors.INK)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .constraintSize({ maxWidth: 118 })
    }
    .height(68)
    .width(this.cardWidth())
    .padding({ left: 16, right: 16 })
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 18, color: AppColors.SHADOW, offsetY: 8 })
    .margin({ bottom: 12 })
  }

  private cardWidth(): string {
    return this.viewportWidth >= Breakpoints.WIDE ? '48%' : '100%';
  }

  private contentMaxWidth(): number {
    return this.viewportWidth >= Breakpoints.DESKTOP ? LayoutSizes.CONTENT_MAX : LayoutSizes.CONTENT_COMPACT;
  }
}
