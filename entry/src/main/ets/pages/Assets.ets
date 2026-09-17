import { router } from '@kit.ArkUI';
import { AssetsViewModel } from '../viewmodel/AssetsViewModel';
import { AccountModel } from '../model/Account';
import { InvestmentPosition, InvestmentType } from '../model/Investment';
import { NumberUtil } from '../utils/NumberUtil';
import { AppColors, AppRadius, AppSpace, LayoutSizes } from '../constants/DesignSystem';
import { ROUTES } from '../constants/RouteConstants';
import { ToastUtil } from '../utils/ToastUtil';

@Entry
@Component
struct Assets {
  @State vm: AssetsViewModel = new AssetsViewModel();
  @State selectedDeck: number = 0;
  @State quoteRefreshing: boolean = false;
  @State viewportWidth: number = 0;

  aboutToAppear(): void { this.vm.refresh(); }
  onPageShow(): void { this.vm.refresh(); }

  build() {
    Column() {
      Scroll() {
        Column({ space: 18 }) {
          this.Header()
          this.SummaryDeck()
          this.SectionTitle(this.sectionTitle(), this.sectionBadge())
          if (this.selectedDeck === 0) {
            this.AccountContent()
          } else {
            this.InvestmentContent(this.selectedDeck === 1 ? InvestmentType.STOCK : InvestmentType.FUND)
          }
        }
        .width('100%').constraintSize({ maxWidth: this.contentMaxWidth() }).alignSelf(ItemAlign.Center)
        .padding({ left: AppSpace.PAGE, right: AppSpace.PAGE, top: 22, bottom: 28 })
      }.layoutWeight(1).backgroundColor(AppColors.CANVAS)
    }
    .width('100%').height('100%').backgroundColor(AppColors.CANVAS)
    .onAreaChange((oldValue, newValue) => { this.viewportWidth = parseFloat(`${newValue.width}`); })
  }

  @Builder
  private Header() {
    Row() {
      Button('‹').fontSize(24).fontColor(AppColors.CHART_BLUE).width(44).height(44)
        .backgroundColor(AppColors.SURFACE).borderRadius(22).onClick(() => router.back())
      Column({ space: 3 }) {
        Text('资产').fontSize(26).fontWeight(FontWeight.Bold).fontColor(AppColors.INK)
        Text('账户、股票与基金').fontSize(12).fontColor(AppColors.MUTED)
      }.alignItems(HorizontalAlign.Start).margin({ left: 12 }).layoutWeight(1)
      if (this.selectedDeck > 0) {
        Button('↻').fontSize(16).fontColor(AppColors.CHART_BLUE).width(44).height(44)
          .backgroundColor(AppColors.SURFACE).borderRadius(22).margin({ right: 8 })
          .enabled(!this.quoteRefreshing).onClick(() => this.refreshQuotes())
      }
      Button('+').fontSize(16).fontColor(AppColors.SURFACE).width(44).height(44)
        .backgroundColor(this.selectedColor()).borderRadius(22).onClick(() => this.openManage())
    }.width('100%').alignItems(VerticalAlign.Center)
  }

  @Builder
  private SummaryDeck() {
    Column({ space: 0 }) {
      ForEach(this.deckOrder(), (type: number, index: number) => {
        this.SummaryCard(type, index, type === this.selectedDeck)
      }, (type: number) => `${type}-${this.selectedDeck}`)
    }.width('100%')
  }

  @Builder
  private SummaryCard(type: number, index: number, active: boolean) {
    Column({ space: 12 }) {
      Row() {
        Text(this.deckMark(type)).fontSize(14).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
          .width(34).height(34).textAlign(TextAlign.Center).borderRadius(17).backgroundColor('#FFFFFF35')
        Column({ space: 2 }) {
          Text(this.deckTitle(type)).fontSize(17).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
          Text(this.deckSubtitle(type)).fontSize(11).fontColor('#FFFFFFCC')
        }.alignItems(HorizontalAlign.Start).margin({ left: 10 }).layoutWeight(1)
        Text(active ? '当前' : '查看').fontSize(10).fontColor('#FFFFFFCC')
      }.width('100%')
      Text(NumberUtil.compactMoney(this.deckValue(type))).fontSize(active ? 31 : 25).fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF').maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%')
      Row() {
        Text(this.deckLeftDetail(type)).fontSize(11).fontColor('#FFFFFFCC')
        Blank()
        Text(this.deckRightDetail(type)).fontSize(12).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
      }.width('100%')
    }
    .width(`${90 + index * 5}%`).height(128).padding(16).backgroundColor(this.deckColor(type))
    .borderRadius(AppRadius.CARD).shadow({ radius: 18, color: AppColors.SHADOW, offsetY: 8 })
    .alignSelf(index % 2 === 0 ? ItemAlign.End : ItemAlign.Start)
    .margin({ top: index === 0 ? 0 : -84 })
    .onClick(() => { this.selectedDeck = type; })
  }

  @Builder
  private SectionTitle(title: string, badge: string) {
    Row() {
      Text(title).fontSize(20).fontWeight(FontWeight.Bold).fontColor(AppColors.INK)
      Blank()
      Text(badge).fontSize(12).fontColor(AppColors.MUTED)
    }.width('100%')
  }

  @Builder
  private AccountContent() {
    Column({ space: 10 }) {
      if (this.vm.accounts.length === 0) {
        this.EmptyState('还没有账户', '添加现金、储蓄卡或信用卡账户')
      } else {
        ForEach(this.vm.accounts, (item: AccountModel) => { this.AccountRow(item) },
          (item: AccountModel) => this.accountRenderKey(item))
      }
    }.width('100%')
  }

  @Builder
  private AccountRow(item: AccountModel) {
    Row({ space: 12 }) {
      Text(item.name.substring(0, 1)).fontSize(14).fontWeight(FontWeight.Bold).fontColor(item.color)
        .width(44).height(44).textAlign(TextAlign.Center).borderRadius(14).backgroundColor(AppColors.SURFACE_TINT)
      Column({ space: 4 }) {
        Text(item.name).fontSize(16).fontWeight(FontWeight.Bold).fontColor(AppColors.INK).maxLines(1)
        Text(item.isLiability ? '负债账户' : '资产账户').fontSize(11).fontColor(AppColors.MUTED)
      }.alignItems(HorizontalAlign.Start).layoutWeight(1)
      Text(NumberUtil.compactMoney(item.balance)).fontSize(15).fontWeight(FontWeight.Bold)
        .fontColor(item.isLiability ? AppColors.EXPENSE : AppColors.INK).maxLines(1)
    }
    .width('100%').height(70).padding({ left: 15, right: 15 }).backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .onClick(() => router.pushUrl({ url: ROUTES.ACCOUNT_LEDGER, params: { accountId: item.id || 0 } }))
  }

  @Builder
  private InvestmentContent(type: InvestmentType) {
    Column({ space: 10 }) {
      if (this.vm.positionsByType(type).length === 0) {
        this.EmptyState(type === InvestmentType.STOCK ? '还没有股票持仓' : '还没有基金持仓',
          '点击右上角 + 添加第一笔持仓')
      } else {
        ForEach(this.vm.positionsByType(type), (item: InvestmentPosition) => { this.InvestmentRow(item) },
          (item: InvestmentPosition) => `${item.id}-${item.currentPrice}-${item.holdingQuantity}`)
      }
    }.width('100%')
  }

  @Builder
  private InvestmentRow(item: InvestmentPosition) {
    Row({ space: 12 }) {
      Text(item.type === InvestmentType.STOCK ? '股' : '基').fontSize(14).fontWeight(FontWeight.Bold)
        .fontColor(item.color).width(44).height(44).textAlign(TextAlign.Center).borderRadius(14)
        .backgroundColor(item.type === InvestmentType.STOCK ? AppColors.SURFACE_TINT : AppColors.softGreen())
      Column({ space: 4 }) {
        Text(item.name).fontSize(16).fontWeight(FontWeight.Bold).fontColor(AppColors.INK).maxLines(1)
        Text(`${item.securityCode} · ${item.holdingQuantity} ${item.type === InvestmentType.STOCK ? '股' : '份'}`)
          .fontSize(11).fontColor(AppColors.MUTED).maxLines(1)
      }.alignItems(HorizontalAlign.Start).layoutWeight(1)
      Column({ space: 3 }) {
        Text(NumberUtil.compactMoney(item.holdingQuantity * item.currentPrice)).fontSize(15)
          .fontWeight(FontWeight.Bold).fontColor(AppColors.INK).maxLines(1)
        Text(this.positionProfitText(item)).fontSize(11)
          .fontColor(this.positionProfit(item) >= 0 ? AppColors.INCOME : AppColors.EXPENSE)
      }.alignItems(HorizontalAlign.End)
    }
    .width('100%').height(72).padding({ left: 15, right: 15 }).backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD).onClick(() => router.pushUrl({
      url: ROUTES.INVESTMENT_MANAGE, params: { type: item.type }
    }))
  }

  @Builder
  private EmptyState(title: string, detail: string) {
    Column({ space: 8 }) {
      Text(title).fontSize(17).fontWeight(FontWeight.Bold).fontColor(AppColors.INK)
      Text(detail).fontSize(12).fontColor(AppColors.MUTED)
      Button('去添加').fontSize(13).fontWeight(FontWeight.Bold).fontColor(AppColors.SURFACE)
        .backgroundColor(this.selectedColor()).borderRadius(AppRadius.PILL).onClick(() => this.openManage())
    }.width('100%').height(150).justifyContent(FlexAlign.Center).backgroundColor(AppColors.SURFACE)
      .borderRadius(AppRadius.CARD)
  }

  private deckOrder(): number[] {
    if (this.selectedDeck === 1) return [2, 0, 1];
    if (this.selectedDeck === 2) return [1, 0, 2];
    return [2, 1, 0];
  }
  private deckTitle(type: number): string { return type === 0 ? '净资产' : type === 1 ? '股票' : '基金'; }
  private deckMark(type: number): string { return type === 0 ? '资' : type === 1 ? '股' : '基'; }
  private deckSubtitle(type: number): string {
    if (type === 0) return '账户余额 + 投资市值';
    return type === 1 ? `${this.vm.positionsByType(InvestmentType.STOCK).length} 个持仓` :
      `${this.vm.positionsByType(InvestmentType.FUND).length} 个持仓`;
  }
  private deckValue(type: number): number { return type === 0 ? this.vm.totalAssets : type === 1 ? this.vm.stockValue : this.vm.fundValue; }
  private deckLeftDetail(type: number): string {
    if (type === 0) return `账户净值 ${NumberUtil.compactMoney(this.vm.accountNetAssets)}`;
    return type === 1 ? '股票当前市值' : '基金当前市值';
  }
  private deckRightDetail(type: number): string {
    if (type === 0) return `投资 ${NumberUtil.compactMoney(this.vm.stockValue + this.vm.fundValue)}`;
    const profit = type === 1 ? this.vm.stockProfit : this.vm.fundProfit;
    return `${profit >= 0 ? '+' : ''}${NumberUtil.compactMoney(profit)}`;
  }
  private deckColor(type: number): string {
    if (type === 0) return AppColors.LEDGER_DARK;
    return type === 1 ? AppColors.CHART_BLUE : AppColors.CHART_GREEN;
  }
  private selectedColor(): string { return this.deckColor(this.selectedDeck); }
  private sectionTitle(): string { return this.selectedDeck === 0 ? '账户列表' : this.selectedDeck === 1 ? '股票持仓' : '基金持仓'; }
  private sectionBadge(): string {
    if (this.selectedDeck === 0) return `${this.vm.accounts.length} 个`;
    return `${this.vm.positionsByType(this.selectedDeck === 1 ? InvestmentType.STOCK : InvestmentType.FUND).length} 个`;
  }
  private positionProfit(item: InvestmentPosition): number { return item.holdingQuantity * (item.currentPrice - item.costPrice); }
  private positionProfitText(item: InvestmentPosition): string {
    const value = this.positionProfit(item); return `${value >= 0 ? '+' : ''}${NumberUtil.compactMoney(value)}`;
  }
  private openManage(): void {
    if (this.selectedDeck === 0) router.pushUrl({ url: ROUTES.ACCOUNT_MANAGE });
    else router.pushUrl({ url: ROUTES.INVESTMENT_MANAGE, params: {
      type: this.selectedDeck === 1 ? InvestmentType.STOCK : InvestmentType.FUND
    } });
  }
  private async refreshQuotes(): Promise<void> {
    if (this.quoteRefreshing) return;
    this.quoteRefreshing = true;
    try {
      const updated = await this.vm.refreshInvestmentQuotes();
      ToastUtil.show(updated > 0 ? `已更新 ${updated} 个持仓` : '暂无可更新的持仓');
    } finally { this.quoteRefreshing = false; }
  }
  private accountRenderKey(item: AccountModel): string {
    const balanceCent = Math.round(item.balance * 100);
    return `${item.id}-${balanceCent}`;
  }
  private contentMaxWidth(): number { return this.viewportWidth >= 900 ? LayoutSizes.CONTENT_MAX : LayoutSizes.CONTENT_COMPACT; }
}
