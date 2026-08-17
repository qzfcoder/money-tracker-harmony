import { router } from '@kit.ArkUI';
import { AccountModel, AccountType } from '../model/Account';
import { AccountRepository } from '../repository/AccountRepository';
import { AppState } from '../viewmodel/AppState';
import { AppColors, AppRadius, AppSpace, LayoutSizes } from '../constants/DesignSystem';
import { NumberUtil } from '../utils/NumberUtil';
import { ToastUtil } from '../utils/ToastUtil';
import { AppDatabase } from '../database/AppDatabase';

@Entry
@Component
struct AccountManage {
  private repository: AccountRepository = new AccountRepository();

  @State accounts: AccountModel[] = [];
  @State selectedId: number = 0;
  @State nameText: string = '';
  @State typeValue: AccountType = AccountType.CASH;
  @State balanceText: string = '0';
  @State initialText: string = '0';
  @State iconText: string = 'wallet';
  @State colorText: string = '#2F7EF7';
  @State sortText: string = '1';
  @State isLiability: boolean = false;

  aboutToAppear(): void {
    this.loadAccounts();
  }

  build() {
    Column() {
      this.Header()

      Scroll() {
        Column({ space: 18 }) {
          this.FormCard()
          this.AccountList()
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
        Text('账户管理')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .width('100%')
        Text('新增、编辑账户和余额')
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
  private FormCard() {
    Column({ space: 14 }) {
      Row() {
        Text(this.selectedId > 0 ? '编辑账户' : '新增账户')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
        Blank()
        Text(this.selectedId > 0 ? '编辑中' : '新账户')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.CHART_BLUE)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor(AppColors.SURFACE_TINT)
          .borderRadius(AppRadius.PILL)
      }
      .width('100%')

      TextInput({ text: this.nameText, placeholder: '账户名称，如微信钱包' })
        .height(50)
        .backgroundColor(AppColors.SURFACE_SOFT)
        .borderRadius(16)
        .padding({ left: 16, right: 16 })
        .onChange((value: string) => {
          this.nameText = value;
        })

      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
        this.TypeChip('现金', AccountType.CASH)
        this.TypeChip('储蓄卡', AccountType.DEBIT_CARD)
        this.TypeChip('信用卡', AccountType.CREDIT_CARD)
        this.TypeChip('支付宝', AccountType.ALIPAY)
        this.TypeChip('微信', AccountType.WECHAT)
        this.TypeChip('其他', AccountType.OTHER)
      }
      .width('100%')

      Row({ space: 10 }) {
        TextInput({ text: this.balanceText, placeholder: '当前余额' })
          .type(InputType.NUMBER_DECIMAL)
          .height(50)
          .layoutWeight(1)
          .backgroundColor(AppColors.SURFACE_SOFT)
          .borderRadius(16)
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => {
            this.balanceText = this.normalizeAmount(value);
          })
        TextInput({ text: this.initialText, placeholder: '初始余额' })
          .type(InputType.NUMBER_DECIMAL)
          .height(50)
          .layoutWeight(1)
          .backgroundColor(AppColors.SURFACE_SOFT)
          .borderRadius(16)
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => {
            this.initialText = this.normalizeAmount(value);
          })
      }
      .width('100%')

      Row({ space: 10 }) {
        TextInput({ text: this.iconText, placeholder: '图标标识' })
          .height(50)
          .layoutWeight(1)
          .backgroundColor(AppColors.SURFACE_SOFT)
          .borderRadius(16)
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => {
            this.iconText = value;
          })
        TextInput({ text: this.colorText, placeholder: '#2F7EF7' })
          .height(50)
          .layoutWeight(1)
          .backgroundColor(AppColors.SURFACE_SOFT)
          .borderRadius(16)
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => {
            this.colorText = value;
          })
      }
      .width('100%')

      Row({ space: 10 }) {
        TextInput({ text: this.sortText, placeholder: '排序' })
          .type(InputType.Number)
          .height(50)
          .layoutWeight(1)
          .backgroundColor(AppColors.SURFACE_SOFT)
          .borderRadius(16)
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => {
            this.sortText = value;
          })
        Button(this.isLiability ? '负债账户' : '资产账户')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isLiability ? AppColors.EXPENSE : AppColors.INCOME)
          .height(50)
          .layoutWeight(1)
          .backgroundColor(this.isLiability ? '#FCE9E4' : '#E6F7EF')
          .borderRadius(16)
          .onClick(() => {
            this.isLiability = !this.isLiability;
          })
      }
      .width('100%')

      Row({ space: 10 }) {
        Button('保存账户')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.SURFACE)
          .height(50)
          .layoutWeight(1)
          .backgroundColor(AppColors.CHART_BLUE)
          .borderRadius(AppRadius.PILL)
          .onClick(() => this.save())
        Button('新建')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.CHART_BLUE)
          .height(50)
          .layoutWeight(1)
          .backgroundColor(AppColors.SURFACE_TINT)
          .borderRadius(AppRadius.PILL)
          .onClick(() => this.resetForm())
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
  private TypeChip(label: string, type: AccountType) {
    Text(label)
      .fontSize(13)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.typeValue === type ? AppColors.SURFACE : AppColors.INK)
      .width('31%')
      .height(38)
      .textAlign(TextAlign.Center)
      .backgroundColor(this.typeValue === type ? AppColors.CHART_BLUE : AppColors.SURFACE_SOFT)
      .borderRadius(AppRadius.PILL)
      .margin({ bottom: 8 })
      .onClick(() => {
        this.typeValue = type;
        this.isLiability = type === AccountType.CREDIT_CARD ? true : this.isLiability;
      })
  }

  @Builder
  private AccountList() {
    Column({ space: 12 }) {
      Row() {
        Text('账户列表')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
        Blank()
        Text(`${this.accounts.length} 个`)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.LEDGER)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor(AppColors.SURFACE_TINT)
          .borderRadius(AppRadius.PILL)
      }
      .width('100%')

      ForEach(this.accounts, (item: AccountModel) => {
        this.AccountRow(item)
      }, (item: AccountModel) => `${item.id}`)
    }
    .width('100%')
  }

  @Builder
  private AccountRow(item: AccountModel) {
    Row({ space: 12 }) {
      Text(item.name.substring(0, 1))
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(item.color)
        .width(44)
        .height(44)
        .textAlign(TextAlign.Center)
        .backgroundColor(AppColors.SURFACE_TINT)
        .borderRadius(14)

      Column({ space: 4 }) {
        Text(item.name)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .maxLines(1)
        Text(`${this.typeLabel(item.type)} · 排序 ${item.sortOrder}`)
          .fontSize(12)
          .fontColor(AppColors.MUTED)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Column({ space: 5 }) {
        Text(NumberUtil.compactMoney(item.balance))
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(item.isLiability ? AppColors.EXPENSE : AppColors.INK)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .constraintSize({ maxWidth: 118 })
        Row({ space: 6 }) {
          Button('✎')
            .fontSize(13)
            .fontColor(AppColors.CHART_BLUE)
            .width(34)
            .height(32)
            .backgroundColor(AppColors.SURFACE_TINT)
            .borderRadius(16)
            .onClick(() => this.pickForEdit(item))
          Button('×')
            .fontSize(13)
            .fontColor(AppColors.EXPENSE)
            .width(34)
            .height(32)
            .backgroundColor('#FCE9E4')
            .borderRadius(16)
            .onClick(() => this.remove(item))
        }
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .height(72)
    .padding({ left: 16, right: 16 })
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 16, color: AppColors.SHADOW, offsetY: 6 })
  }

  private async loadAccounts(): Promise<void> {
    try {
      await AppDatabase.getInstance().init(getContext(this));
      this.accounts = await this.repository.list();
      if (this.selectedId === 0) {
        this.sortText = `${this.nextSortOrder()}`;
      }
    } catch (error) {
      this.accounts = [];
      ToastUtil.show('账户加载失败，请重试');
    }
  }

  private async save(): Promise<void> {
    try {
      await AppDatabase.getInstance().init(getContext(this));
      const now = Date.now();
      const account: AccountModel = {
        id: this.selectedId > 0 ? this.selectedId : undefined,
        name: this.nameText.trim() || '未命名账户',
        type: this.typeValue,
        balance: NumberUtil.toCentSafe(this.balanceText),
        initialBalance: NumberUtil.toCentSafe(this.initialText),
        icon: this.iconText.trim() || 'wallet',
        color: this.colorText.trim() || '#2F7EF7',
        isLiability: this.isLiability,
        sortOrder: Number(this.sortText) || this.nextSortOrder(),
        createTime: this.currentSelected()?.createTime || now
      };
      await this.repository.save(account);
      await AppState.getInstance().refreshAll();
      ToastUtil.show('账户已保存');
      this.resetForm();
      await this.loadAccounts();
    } catch (error) {
      ToastUtil.show('账户保存失败，请重试');
    }
  }

  private async remove(item: AccountModel): Promise<void> {
    if (!item.id) {
      return;
    }
    if (this.accounts.length <= 1) {
      ToastUtil.show('至少保留一个账户');
      return;
    }
    try {
      await AppDatabase.getInstance().init(getContext(this));
      await this.repository.deleteById(item.id);
      await AppState.getInstance().refreshAll();
      ToastUtil.show('账户已删除');
      if (this.selectedId === item.id) {
        this.resetForm();
      }
      await this.loadAccounts();
    } catch (error) {
      ToastUtil.show('账户删除失败，请重试');
    }
  }

  private pickForEdit(item: AccountModel): void {
    this.selectedId = item.id || 0;
    this.nameText = item.name;
    this.typeValue = item.type;
    this.balanceText = `${item.balance}`;
    this.initialText = `${item.initialBalance}`;
    this.iconText = item.icon;
    this.colorText = item.color;
    this.sortText = `${item.sortOrder}`;
    this.isLiability = item.isLiability;
  }

  private resetForm(): void {
    this.selectedId = 0;
    this.nameText = '';
    this.typeValue = AccountType.CASH;
    this.balanceText = '0';
    this.initialText = '0';
    this.iconText = 'wallet';
    this.colorText = '#2F7EF7';
    this.isLiability = false;
    this.sortText = `${this.nextSortOrder()}`;
  }

  private normalizeAmount(value: string): string {
    return NumberUtil.normalizeAmountInput(value);
  }

  private nextSortOrder(): number {
    if (this.accounts.length === 0) {
      return 1;
    }
    const max = this.accounts.reduce((result: number, item: AccountModel) => Math.max(result, item.sortOrder), 0);
    return max + 1;
  }

  private currentSelected(): AccountModel | undefined {
    return this.accounts.find((item: AccountModel) => item.id === this.selectedId);
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
