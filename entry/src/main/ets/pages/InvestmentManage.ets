import { router } from '@kit.ArkUI';
import { AppDatabase } from '../database/AppDatabase';
import { InvestmentPosition, InvestmentType } from '../model/Investment';
import { InvestmentRepository } from '../repository/InvestmentRepository';
import { MarketQuote, MarketQuoteService } from '../service/MarketQuoteService';
import { AppColors, AppRadius, AppSpace, LayoutSizes } from '../constants/DesignSystem';
import { NumberUtil } from '../utils/NumberUtil';
import { ToastUtil } from '../utils/ToastUtil';

interface InvestmentManageParams {
  type?: number;
  positionId?: number;
}

@Entry
@Component
struct InvestmentManage {
  private repository: InvestmentRepository = new InvestmentRepository();
  private initialPositionId: number = 0;
  @State type: InvestmentType = InvestmentType.STOCK;
  @State items: InvestmentPosition[] = [];
  @State selectedId: number = 0;
  @State nameText: string = '';
  @State codeText: string = '';
  @State quantityText: string = '';
  @State costText: string = '';
  @State priceText: string = '';
  @State quoteTime: number = 0;
  @State loadingQuote: boolean = false;

  aboutToAppear(): void {
    const params = router.getParams() as InvestmentManageParams;
    this.type = Number(params?.type || InvestmentType.STOCK) === InvestmentType.FUND ? InvestmentType.FUND : InvestmentType.STOCK;
    this.initialPositionId = Number(params?.positionId || 0);
    this.load();
  }

  build() {
    Column() {
      this.Header()
      Scroll() {
        Column({ space: 18 }) {
          this.Editor()
          this.PositionList()
        }
        .width('100%').constraintSize({ maxWidth: LayoutSizes.CONTENT_COMPACT }).alignSelf(ItemAlign.Center)
        .padding({ left: AppSpace.PAGE, right: AppSpace.PAGE, top: 10, bottom: 28 })
      }.layoutWeight(1).backgroundColor(AppColors.CANVAS)
    }.width('100%').height('100%').backgroundColor(AppColors.CANVAS)
  }

  @Builder
  private Header() {
    Row() {
      Button('‹').fontSize(24).fontColor(AppColors.CHART_BLUE).width(44).height(44)
        .backgroundColor(AppColors.SURFACE).borderRadius(22).onClick(() => router.back())
      Column({ space: 3 }) {
        Text(this.type === InvestmentType.STOCK ? '股票持仓' : '基金持仓')
          .fontSize(24).fontWeight(FontWeight.Bold).fontColor(AppColors.INK)
        Text('持仓数据独立于日常账户').fontSize(12).fontColor(AppColors.MUTED)
      }.alignItems(HorizontalAlign.Start).margin({ left: 12 })
    }.width('100%').padding({ left: AppSpace.PAGE, right: AppSpace.PAGE, top: 22, bottom: 8 })
  }

  @Builder
  private Editor() {
    Column({ space: 13 }) {
      Row() {
        Text(this.selectedId > 0 ? '编辑持仓' : '新增持仓').fontSize(20).fontWeight(FontWeight.Bold).fontColor(AppColors.INK)
        Blank()
        Text(this.type === InvestmentType.STOCK ? '股票' : '基金').fontSize(12).fontWeight(FontWeight.Bold)
          .fontColor(this.typeColor()).padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor(this.typeBackground()).borderRadius(AppRadius.PILL)
      }.width('100%')

      this.FieldLabel('名称')
      TextInput({ text: this.nameText, placeholder: this.type === InvestmentType.STOCK ? '例如：贵州茅台' : '例如：招商中证白酒' })
        .height(50).backgroundColor(AppColors.SURFACE_SOFT).borderRadius(16).padding({ left: 16, right: 16 })
        .onChange((value: string) => { this.nameText = value; })

      this.FieldLabel(this.type === InvestmentType.STOCK ? '股票代码' : '基金代码')
      Row({ space: 10 }) {
        TextInput({ text: this.codeText, placeholder: this.type === InvestmentType.STOCK ? '例如：600519' : '例如：161725' })
          .height(50).layoutWeight(1).backgroundColor(AppColors.SURFACE_SOFT).borderRadius(16).padding({ left: 16, right: 16 })
          .onChange((value: string) => { this.codeText = MarketQuoteService.normalizeCode(value); })
        Button(this.loadingQuote ? '读取中' : '读取价格').fontSize(13).fontWeight(FontWeight.Bold).fontColor(AppColors.CHART_BLUE)
          .width(96).height(50).backgroundColor(AppColors.SURFACE_TINT).borderRadius(16).enabled(!this.loadingQuote)
          .onClick(() => this.readQuote())
      }.width('100%')

      Row({ space: 10 }) {
        Column({ space: 7 }) {
          this.FieldLabel(this.type === InvestmentType.STOCK ? '持有股数' : '持有份额')
          TextInput({ text: this.quantityText, placeholder: '0' })
            .type(InputType.NUMBER_DECIMAL).height(50).width('100%')
            .backgroundColor(AppColors.SURFACE_SOFT).borderRadius(16).padding({ left: 16, right: 16 })
            .onChange((value: string) => { this.quantityText = NumberUtil.normalizeDecimalInput(value, 4); })
        }.layoutWeight(1).alignItems(HorizontalAlign.Start)
        Column({ space: 7 }) {
          this.FieldLabel('买入均价')
          TextInput({ text: this.costText, placeholder: '0.00' })
            .type(InputType.NUMBER_DECIMAL).height(50).width('100%')
            .backgroundColor(AppColors.SURFACE_SOFT).borderRadius(16).padding({ left: 16, right: 16 })
            .onChange((value: string) => { this.costText = NumberUtil.normalizeDecimalInput(value, 4); })
        }.layoutWeight(1).alignItems(HorizontalAlign.Start)
      }.width('100%')

      this.FieldLabel(this.type === InvestmentType.FUND ? '最近净值（可手动修改）' : '当前价格（可手动修改）')
      TextInput({ text: this.priceText, placeholder: '0.00' })
        .type(InputType.NUMBER_DECIMAL).height(50).width('100%')
        .backgroundColor(AppColors.SURFACE_SOFT).borderRadius(16).padding({ left: 16, right: 16 })
        .onChange((value: string) => { this.priceText = NumberUtil.normalizeDecimalInput(value, 4); })

      Row() {
        Column({ space: 3 }) {
          Text('当前市值').fontSize(11).fontColor(AppColors.MUTED)
          Text(NumberUtil.compactMoney(this.marketValue())).fontSize(18).fontWeight(FontWeight.Bold).fontColor(AppColors.INK)
        }.alignItems(HorizontalAlign.Start)
        Blank()
        Column({ space: 3 }) {
          Text('浮动盈亏').fontSize(11).fontColor(AppColors.MUTED)
          Text(this.profitText()).fontSize(18).fontWeight(FontWeight.Bold)
            .fontColor(this.profit() >= 0 ? AppColors.INCOME : AppColors.EXPENSE)
        }.alignItems(HorizontalAlign.End)
      }.width('100%').padding(14).backgroundColor(this.typeBackground()).borderRadius(16)

      Row({ space: 10 }) {
        Button('保存持仓').fontSize(15).fontWeight(FontWeight.Bold).fontColor(AppColors.SURFACE)
          .layoutWeight(1).height(50).backgroundColor(this.typeColor()).borderRadius(AppRadius.PILL).onClick(() => this.save())
        Button('清空').fontSize(15).fontWeight(FontWeight.Bold).fontColor(AppColors.CHART_BLUE)
          .width(88).height(50).backgroundColor(AppColors.SURFACE_TINT).borderRadius(AppRadius.PILL).onClick(() => this.reset())
      }.width('100%')
    }
    .width('100%').padding(16).backgroundColor(AppColors.SURFACE).borderRadius(AppRadius.CARD)
    .shadow({ radius: 18, color: AppColors.SHADOW, offsetY: 8 })
  }

  @Builder private FieldLabel(text: string) { Text(text).fontSize(12).fontColor(AppColors.MUTED).width('100%') }

  @Builder
  private PositionList() {
    Column({ space: 10 }) {
      Row() {
        Text('已有持仓').fontSize(20).fontWeight(FontWeight.Bold).fontColor(AppColors.INK)
        Blank()
        Text(`${this.items.length} 个`).fontSize(12).fontColor(AppColors.MUTED)
      }.width('100%')
      if (this.items.length === 0) {
        Text('还没有持仓，填写上方信息后保存。').fontSize(13).fontColor(AppColors.MUTED)
          .width('100%').height(96).textAlign(TextAlign.Center).backgroundColor(AppColors.SURFACE).borderRadius(AppRadius.CARD)
      } else {
        ForEach(this.items, (item: InvestmentPosition) => { this.PositionRow(item) },
          (item: InvestmentPosition) => `${item.id}-${item.currentPrice}-${item.holdingQuantity}`)
      }
    }.width('100%')
  }

  @Builder
  private PositionRow(item: InvestmentPosition) {
    Column({ space: 10 }) {
      Row() {
        Column({ space: 3 }) {
          Text(item.name).fontSize(16).fontWeight(FontWeight.Bold).fontColor(AppColors.INK)
          Text(`${item.securityCode} · ${item.holdingQuantity} ${this.type === InvestmentType.STOCK ? '股' : '份'}`)
            .fontSize(11).fontColor(AppColors.MUTED)
        }.alignItems(HorizontalAlign.Start).layoutWeight(1)
        Column({ space: 3 }) {
          Text(NumberUtil.compactMoney(item.holdingQuantity * item.currentPrice)).fontSize(15).fontWeight(FontWeight.Bold).fontColor(AppColors.INK)
          Text(this.itemProfitText(item)).fontSize(11)
            .fontColor(this.itemProfit(item) >= 0 ? AppColors.INCOME : AppColors.EXPENSE)
        }.alignItems(HorizontalAlign.End)
      }.width('100%')
      Row({ space: 8 }) {
        Blank()
        Button('编辑').fontSize(12).fontColor(AppColors.CHART_BLUE).height(32).backgroundColor(AppColors.SURFACE_TINT)
          .borderRadius(16).onClick(() => this.edit(item))
        Button('删除').fontSize(12).fontColor(AppColors.EXPENSE).height(32).backgroundColor(AppColors.softDanger())
          .borderRadius(16).onClick(() => this.remove(item))
      }.width('100%')
    }.width('100%').padding(15).backgroundColor(AppColors.SURFACE).borderRadius(AppRadius.CARD)
  }

  private async load(): Promise<void> {
    await AppDatabase.getInstance().init(getContext(this));
    this.items = await this.repository.list(this.type);
    if (this.initialPositionId > 0) {
      const initialItem = this.items.find((item: InvestmentPosition) => item.id === this.initialPositionId);
      if (initialItem) {
        this.edit(initialItem);
      }
      this.initialPositionId = 0;
    }
  }

  private async readQuote(): Promise<void> {
    if (!this.codeText) { ToastUtil.show('请先输入代码'); return; }
    this.loadingQuote = true;
    try {
      const quote: MarketQuote = await MarketQuoteService.fetch(this.type, this.codeText);
      this.codeText = quote.code;
      this.priceText = `${quote.price}`;
      this.quoteTime = quote.quoteTime;
      if (!this.nameText.trim() && quote.name !== quote.code) this.nameText = quote.name;
      ToastUtil.show(this.type === InvestmentType.FUND ? '已读取最近净值' : '已读取当前价格');
    } catch (error) {
      ToastUtil.show('价格读取失败，可手动填写');
    } finally { this.loadingQuote = false; }
  }

  private async save(): Promise<void> {
    const quantity = NumberUtil.toDecimalSafe(this.quantityText, 4);
    const cost = NumberUtil.toDecimalSafe(this.costText, 4);
    const price = NumberUtil.toDecimalSafe(this.priceText, 4);
    if (!this.codeText || quantity <= 0 || cost <= 0 || price <= 0) {
      ToastUtil.show('请完整填写代码、数量、买入均价和当前价格'); return;
    }
    const current = this.items.find((item: InvestmentPosition) => item.id === this.selectedId);
    await this.repository.save({
      id: this.selectedId || undefined,
      name: this.nameText.trim() || this.codeText,
      type: this.type,
      securityCode: this.codeText,
      holdingQuantity: quantity,
      costPrice: cost,
      currentPrice: price,
      color: this.typeColor(),
      sortOrder: current?.sortOrder || this.items.length + 1,
      quoteTime: this.quoteTime,
      createTime: current?.createTime || Date.now()
    });
    ToastUtil.show('持仓已保存'); this.reset(); await this.load();
  }

  private edit(item: InvestmentPosition): void {
    this.selectedId = item.id || 0; this.nameText = item.name; this.codeText = item.securityCode;
    this.quantityText = `${item.holdingQuantity}`; this.costText = `${item.costPrice}`;
    this.priceText = `${item.currentPrice}`; this.quoteTime = item.quoteTime;
  }

  private async remove(item: InvestmentPosition): Promise<void> {
    if (!item.id) return;
    await this.repository.deleteById(item.id); if (this.selectedId === item.id) this.reset(); await this.load();
    ToastUtil.show('持仓已删除');
  }

  private reset(): void {
    this.selectedId = 0; this.nameText = ''; this.codeText = ''; this.quantityText = '';
    this.costText = ''; this.priceText = ''; this.quoteTime = 0;
  }
  private marketValue(): number { return NumberUtil.toDecimalSafe(this.quantityText, 4) * NumberUtil.toDecimalSafe(this.priceText, 4); }
  private profit(): number { return NumberUtil.toDecimalSafe(this.quantityText, 4) * (NumberUtil.toDecimalSafe(this.priceText, 4) - NumberUtil.toDecimalSafe(this.costText, 4)); }
  private profitText(): string { const value = this.profit(); return `${value >= 0 ? '+' : ''}${NumberUtil.compactMoney(value)}`; }
  private itemProfit(item: InvestmentPosition): number { return item.holdingQuantity * (item.currentPrice - item.costPrice); }
  private itemProfitText(item: InvestmentPosition): string { const value = this.itemProfit(item); return `${value >= 0 ? '+' : ''}${NumberUtil.compactMoney(value)}`; }
  private typeColor(): string { return this.type === InvestmentType.STOCK ? AppColors.CHART_BLUE : AppColors.CHART_GREEN; }
  private typeBackground(): string { return this.type === InvestmentType.STOCK ? AppColors.SURFACE_TINT : AppColors.softGreen(); }
}
