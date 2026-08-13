import { router } from '@kit.ArkUI';
import { AccountModel, AccountType } from '../model/Account';
import { AccountRepository } from '../repository/AccountRepository';
import { AppColors, AppRadius, AppSpace, LayoutSizes } from '../constants/DesignSystem';
import { NumberUtil } from '../utils/NumberUtil';
import { AppDatabase } from '../database/AppDatabase';
import { ToastUtil } from '../utils/ToastUtil';

@Entry
@Component
struct AccountPicker {
  private repository: AccountRepository = new AccountRepository();

  @State accounts: AccountModel[] = [];

  aboutToAppear(): void {
    this.loadAccounts();
  }

  build() {
    Column() {
      this.Header()
      Scroll() {
        Column({ space: 12 }) {
          ForEach(this.accounts, (item: AccountModel) => {
            this.AccountRow(item)
          }, (item: AccountModel) => `${item.id}`)
        }
        .width('100%')
        .constraintSize({ maxWidth: LayoutSizes.CONTENT_MAX })
        .alignSelf(ItemAlign.Center)
        .padding({ left: AppSpace.PAGE, right: AppSpace.PAGE, top: 10, bottom: 24 })
      }
      .layoutWeight(1)
      .backgroundColor(AppColors.CANVAS)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.CANVAS)
  }

  @Builder
  private Header() {
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
      Column({ space: 4 }) {
        Text('选择账户')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .width('100%')
        Text('查看账户余额并选择')
          .fontSize(13)
          .fontColor(AppColors.MUTED)
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
    }
    .width('100%')
    .padding({ left: AppSpace.PAGE, right: AppSpace.PAGE, top: 22, bottom: 8 })
  }

  @Builder
  private AccountRow(item: AccountModel) {
    Row({ space: 12 }) {
      Text(item.name.substring(0, 1))
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(item.color)
        .width(46)
        .height(46)
        .textAlign(TextAlign.Center)
        .backgroundColor(AppColors.SURFACE_TINT)
        .borderRadius(15)
      Column({ space: 4 }) {
        Text(item.name)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .maxLines(1)
        Text(this.typeLabel(item.type))
          .fontSize(12)
          .fontColor(AppColors.MUTED)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Text(NumberUtil.money(item.balance))
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(item.isLiability ? AppColors.EXPENSE : AppColors.INK)
    }
    .height(68)
    .width('100%')
    .padding({ left: 16, right: 16 })
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 16, color: AppColors.SHADOW, offsetY: 6 })
    .onClick(() => router.back())
  }

  private async loadAccounts(): Promise<void> {
    try {
      await AppDatabase.getInstance().init(getContext(this));
      this.accounts = await this.repository.list();
    } catch (error) {
      this.accounts = [];
      ToastUtil.show('账户加载失败，请重试');
    }
  }

  private typeLabel(type: AccountType): string {
    if (type === AccountType.CASH) {
      return '现金';
    }
    if (type === AccountType.DEBIT_CARD) {
      return '储蓄卡';
    }
    if (type === AccountType.CREDIT_CARD) {
      return '信用卡';
    }
    if (type === AccountType.ALIPAY) {
      return '支付宝';
    }
    if (type === AccountType.WECHAT) {
      return '微信';
    }
    return '其他';
  }
}
