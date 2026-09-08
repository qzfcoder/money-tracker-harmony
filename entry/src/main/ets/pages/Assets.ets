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

  onPageShow(): void {
    this.vm.refresh();
  }

  build() {
    Column() {
      Scroll() {
        Column({ space: 18 }) {
          this.Header('资产')
          this.SummaryCard()
          if (this.vm.liabilityAccountCount > 0) {
            this.LiabilityInsightCard()
          }
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

      Row({ space: 10 }) {
        this.AssetMetric('资产', NumberUtil.compactMoney(this.vm.assetBalance), AppColors.CHART_GREEN, AppColors.softGreen())
        this.AssetMetric('负债', NumberUtil.compactMoney(this.vm.liabilityBalance), AppColors.EXPENSE, AppColors.softDanger())
        this.AssetMetric('账户', `${this.vm.assetAccountCount}/${this.vm.liabilityAccountCount}`, AppColors.CHART_BLUE, AppColors.SURFACE_TINT)
      }
      .width('100%')

      Text(this.assetInsight())
        .fontSize(12)
        .fontColor(AppColors.MUTED)
        .lineHeight(19)
        .width('100%')
    }
    .width('100%')
    .padding(18)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 24, color: AppColors.SHADOW, offsetY: 10 })
  }

  @Builder
  private AssetMetric(label: string, value: string, color: string, bgColor: string) {
    Column({ space: 4 }) {
      Text(label)
        .fontSize(12)
        .fontColor(AppColors.MUTED)
        .maxLines(1)
      Text(value)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .textAlign(TextAlign.Center)
    }
    .layoutWeight(1)
    .height(64)
    .justifyContent(FlexAlign.Center)
    .padding(10)
    .backgroundColor(bgColor)
    .borderRadius(16)
  }

  @Builder
  private LiabilityInsightCard() {
    Column({ space: 14 }) {
      Row() {
        Column({ space: 4 }) {
          Text('负债观察')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.INK)
            .width('100%')
          Text(this.liabilityInsightText())
            .fontSize(12)
            .fontColor(AppColors.MUTED)
            .width('100%')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Text(`${this.liabilityRatio()}%`)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.liabilityRatioColor())
          .maxLines(1)
          .constraintSize({ maxWidth: 92 })
      }
      .width('100%')

      Stack({ alignContent: Alignment.Start }) {
        Column()
          .height(9)
          .width('100%')
          .backgroundColor(AppColors.TRACK)
          .borderRadius(5)
        Column()
          .height(9)
          .width(`${Math.min(100, this.liabilityRatio())}%`)
          .backgroundColor(this.liabilityRatioColor())
          .borderRadius(5)
      }
      .width('100%')
      .height(9)

      Row({ space: 8 }) {
        this.AssetMetric('负债合计', NumberUtil.compactMoney(this.vm.liabilityBalance), AppColors.EXPENSE, AppColors.softDanger())
        this.AssetMetric('净资产', NumberUtil.compactMoney(this.vm.totalAssets), AppColors.CHART_BLUE, AppColors.SURFACE_TINT)
        this.AssetMetric('最大负债', this.largestLiabilityName(), this.liabilityRatioColor(), AppColors.SURFACE_SOFT)
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 20, color: AppColors.SHADOW, offsetY: 8 })
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
      }, (item: AccountModel) => this.accountRenderKey(item))
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
    .onClick(() => router.pushUrl({ url: ROUTES.ACCOUNT_LEDGER, params: { accountId: item.id || 0 } }))
  }

  private cardWidth(): string {
    return this.viewportWidth >= Breakpoints.WIDE ? '48%' : '100%';
  }

  private contentMaxWidth(): number {
    return this.viewportWidth >= Breakpoints.DESKTOP ? LayoutSizes.CONTENT_MAX : LayoutSizes.CONTENT_COMPACT;
  }

  private accountRenderKey(account: AccountModel): string {
    const balanceCent = Math.round(account.balance * 100);
    return `${account.id}-${account.name}-${account.type}-${balanceCent}-${account.isLiability ? 1 : 0}-${account.sortOrder}-${account.color}`;
  }

  private assetInsight(): string {
    if (this.vm.accounts.length === 0) {
      return '还没有账户，先添加常用钱包或银行卡。';
    }
    if (this.vm.assetBalance <= 0 && this.vm.liabilityBalance <= 0) {
      return '账户余额还没有录入，维护余额后可查看净资产。';
    }
    if (this.vm.assetBalance <= 0) {
      return '当前主要是负债账户，建议补充资产账户余额。';
    }
    const ratio = Math.round(this.vm.liabilityBalance / this.vm.assetBalance * 100);
    if (ratio <= 0) {
      return '当前没有负债账户，资产结构比较清爽。';
    }
    if (ratio >= 80) {
      return `负债约为资产的 ${ratio}%，建议优先关注还款安排。`;
    }
    return `负债约为资产的 ${ratio}%，可结合账户列表定期检查余额。`;
  }

  private liabilityAccounts(): AccountModel[] {
    return this.vm.accounts.filter((account: AccountModel) => account.isLiability);
  }

  private largestLiability(): AccountModel | null {
    const list = this.liabilityAccounts();
    if (list.length === 0) {
      return null;
    }
    let target = list[0];
    list.forEach((item: AccountModel) => {
      if (item.balance > target.balance) {
        target = item;
      }
    });
    return target;
  }

  private largestLiabilityName(): string {
    const account = this.largestLiability();
    if (!account) {
      return '无';
    }
    return account.name.length > 4 ? `${account.name.substring(0, 4)}…` : account.name;
  }

  private liabilityRatio(): number {
    if (this.vm.assetBalance <= 0) {
      return this.vm.liabilityBalance > 0 ? 100 : 0;
    }
    return Math.max(0, Math.round(this.vm.liabilityBalance / this.vm.assetBalance * 100));
  }

  private liabilityRatioColor(): string {
    const ratio = this.liabilityRatio();
    if (ratio >= 80) {
      return AppColors.EXPENSE;
    }
    if (ratio >= 50) {
      return AppColors.WARNING;
    }
    return AppColors.CHART_GREEN;
  }

  private liabilityInsightText(): string {
    const largest = this.largestLiability();
    const ratio = this.liabilityRatio();
    if (!largest) {
      return '当前没有负债账户。';
    }
    if (ratio >= 80) {
      return `${largest.name} 是当前最大负债账户，建议优先安排还款。`;
    }
    if (ratio >= 50) {
      return `${largest.name} 占比较高，适合定期核对账单和还款计划。`;
    }
    return `负债压力较轻，最大负债账户为 ${largest.name}。`;
  }
}
