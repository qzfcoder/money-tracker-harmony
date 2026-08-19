import { router } from '@kit.ArkUI';
import { CategoryIcon } from '../components/CategoryIcon';
import { CategoryModel } from '../model/Category';
import { AccountModel } from '../model/Account';
import { RecordListItem, RecordModel, RecordType } from '../model/Record';
import { RecordTemplateModel } from '../model/RecordTemplate';
import { RecordTemplateRepository } from '../repository/RecordTemplateRepository';
import { RecordViewModel } from '../viewmodel/RecordViewModel';
import { AppState } from '../viewmodel/AppState';
import { ToastUtil } from '../utils/ToastUtil';
import { NumberUtil } from '../utils/NumberUtil';
import { AppColors, AppRadius, AppSpace, Breakpoints, LayoutSizes } from '../constants/DesignSystem';

interface RecordEditParams {
  recordId?: number;
  recordTime?: number;
}

interface DatePickerResult {
  year?: number;
  month?: number;
  day?: number;
}

@Entry
@Component
struct RecordEdit {
  private templateRepository: RecordTemplateRepository = new RecordTemplateRepository();

  @State vm: RecordViewModel = new RecordViewModel();
  @State amountText: string = '';
  @State templates: RecordTemplateModel[] = [];
  @State viewportWidth: number = 0;

  aboutToAppear(): void {
    const params = router.getParams() as RecordEditParams;
    const recordId = Number(params?.recordId || 0);
    this.vm.init(getContext(this), recordId).then(() => {
      if (recordId <= 0 && Number(params?.recordTime || 0) > 0) {
        this.vm.recordTime = Number(params.recordTime);
      }
      this.amountText = this.vm.amountText;
      this.loadTemplates();
    }).catch((error: Error) => {
      ToastUtil.show(ToastUtil.error(error, '账单初始化失败'));
    });
  }

  build() {
    Column() {
      this.Header()

      Scroll() {
        Column({ space: 20 }) {
          if (this.isWide()) {
            Row({ space: 16 }) {
              Column({ space: 20 }) {
                this.TypeSwitch()
                this.AmountPanel()
                this.TemplatePanel()
                this.DateTimePanel()
                this.RemarkPanel()
              }
              .layoutWeight(1)
              .constraintSize({ minWidth: 340 })

              Column({ space: 20 }) {
                this.CategoryPanel()
                this.AccountPanel()
              }
              .layoutWeight(1)
              .constraintSize({ minWidth: 340 })
            }
            .width('100%')
          } else {
            Column({ space: 20 }) {
              this.TypeSwitch()
              this.AmountPanel()
              this.TemplatePanel()
              this.DateTimePanel()
              this.CategoryPanel()
              this.AccountPanel()
              this.RemarkPanel()
            }
            .width('100%')
          }
        }
        .width('100%')
        .constraintSize({ maxWidth: this.contentMaxWidth() })
        .alignSelf(ItemAlign.Center)
        .padding({ left: AppSpace.PAGE, right: AppSpace.PAGE, top: 8, bottom: 100 })
      }
      .layoutWeight(1)

      Row() {
      Button('保存')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.SURFACE)
          .height(52)
          .layoutWeight(1)
          .backgroundColor(AppColors.CHART_BLUE)
          .borderRadius(AppRadius.PILL)
          .shadow({ radius: 18, color: '#3B8CFF30', offsetY: 8 })
          .onClick(() => this.save())
      }
      .width('100%')
      .constraintSize({ maxWidth: this.contentMaxWidth() })
      .alignSelf(ItemAlign.Center)
      .padding({ left: AppSpace.PAGE, right: AppSpace.PAGE, bottom: 18 })
    }
    .height('100%')
    .backgroundColor(AppColors.CANVAS)
    .onAreaChange((oldValue, newValue) => {
      this.viewportWidth = parseFloat(`${newValue.width}`);
    })
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
      Column({ space: 2 }) {
        Text(this.vm.recordId > 0 ? '编辑账单' : '记一笔')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .width('100%')
        Text(this.vm.recordId > 0 ? '修改这笔记录' : '快速记录')
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
  private TypeSwitch() {
    Row() {
      this.TypeButton('支出', RecordType.EXPENSE)
      this.TypeButton('收入', RecordType.INCOME)
    }
    .height(50)
    .padding(4)
    .backgroundColor('#E7EAEE')
    .borderRadius(AppRadius.PILL)
  }

  @Builder
  private TypeButton(label: string, type: RecordType.EXPENSE | RecordType.INCOME) {
    Text(label)
      .fontSize(15)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.vm.type === type ? AppColors.INK : AppColors.MUTED)
      .textAlign(TextAlign.Center)
      .height(42)
      .layoutWeight(1)
      .borderRadius(AppRadius.PILL)
      .backgroundColor(this.vm.type === type ? AppColors.SURFACE : '#00000000')
      .shadow(this.vm.type === type ? { radius: 10, color: AppColors.SHADOW, offsetY: 4 } : { radius: 0, color: '#00000000', offsetY: 0 })
      .onClick(() => {
        this.switchType(type);
      })
  }

  @Builder
  private AmountPanel() {
    Column({ space: 12 }) {
      Row({ space: 12 }) {
        Text(this.vm.type === RecordType.EXPENSE ? '支' : '收')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.vm.type === RecordType.EXPENSE ? AppColors.EXPENSE : AppColors.INCOME)
          .width(44)
          .height(44)
          .textAlign(TextAlign.Center)
          .borderRadius(15)
          .backgroundColor(this.vm.type === RecordType.EXPENSE ? '#FCE9E4' : '#E6F6F0')
        Column({ space: 3 }) {
          Text('金额')
            .fontSize(13)
            .fontColor(AppColors.MUTED)
          Text(this.vm.type === RecordType.EXPENSE ? '记录一笔支出' : '记录一笔收入')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.INK)
        }
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      TextInput({ text: this.amountText, placeholder: '0.00' })
        .type(InputType.NUMBER_DECIMAL)
        .fontSize(34)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.INK)
        .placeholderColor(AppColors.FAINT)
        .height(66)
        .backgroundColor(AppColors.SURFACE_SOFT)
        .borderRadius(18)
        .padding({ left: 16, right: 16 })
        .onChange((value: string) => {
          this.amountText = this.normalizeAmount(value);
        })
    }
    .padding(16)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 22, color: AppColors.SHADOW, offsetY: 9 })
  }

  @Builder
  private TemplatePanel() {
    Column({ space: 12 }) {
      Row() {
        Text('账单模板')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
        Blank()
        Button('保存当前')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.CHART_BLUE)
          .height(34)
          .backgroundColor(AppColors.SURFACE_TINT)
          .borderRadius(AppRadius.PILL)
          .onClick(() => this.saveCurrentTemplate())
      }
      .width('100%')

      if (this.templates.length === 0) {
        Text('暂无模板')
          .fontSize(13)
          .fontColor(AppColors.MUTED)
          .width('100%')
          .height(40)
          .textAlign(TextAlign.Center)
          .backgroundColor(AppColors.SURFACE_SOFT)
          .borderRadius(16)
      } else {
        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
          ForEach(this.templates, (item: RecordTemplateModel) => {
            this.TemplateChip(item)
          }, (item: RecordTemplateModel) => `${item.id}`)
        }
        .width('100%')
      }
    }
    .padding(16)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 22, color: AppColors.SHADOW, offsetY: 9 })
  }

  @Builder
  private TemplateChip(item: RecordTemplateModel) {
    Row({ space: 8 }) {
      Column({ space: 4 }) {
        Text(item.name)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        Text(`${NumberUtil.money(item.amount)} · ${item.accountName || '账户'}`)
          .fontSize(12)
          .fontColor(AppColors.MUTED)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .onClick(() => this.applyTemplate(item))

      Button('×')
        .fontSize(14)
        .fontColor(AppColors.EXPENSE)
        .width(32)
        .height(32)
        .backgroundColor('#FCE9E4')
        .borderRadius(16)
        .onClick(() => this.deleteTemplate(item))
    }
    .alignItems(VerticalAlign.Top)
    .width(this.isWide() ? '31%' : '48%')
    .height(62)
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .margin({ right: this.isWide() ? 8 : 6, bottom: 8 })
    .backgroundColor(AppColors.SURFACE_SOFT)
    .border({ width: 1, color: item.categoryColor || AppColors.LINE })
    .borderRadius(16)
  }

  @Builder
  private CategoryPanel() {
    Column({ space: 12 }) {
      Row() {
        Text('分类')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
        Blank()
        Text('点选一个分类')
          .fontSize(12)
          .fontColor(AppColors.MUTED)
      }
      .width('100%')

      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
        ForEach(this.vm.categories, (item: CategoryModel) => {
          CategoryIcon({
            name: item.name,
            color: item.color,
            selected: this.isCategorySelected(item)
          })
            .onClick(() => {
              this.vm.selectedCategory = item;
            })
        }, (item: CategoryModel) => `${item.id}`)
      }
      .width('100%')
    }
    .padding(16)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 22, color: AppColors.SHADOW, offsetY: 9 })
  }

  @Builder
  private AccountPanel() {
    Column({ space: 12 }) {
      Row() {
        Text('账户')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
        Blank()
        Text('默认使用最近账户')
          .fontSize(12)
          .fontColor(AppColors.MUTED)
      }
      .width('100%')

      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
        ForEach(this.vm.accounts, (item: AccountModel) => {
          Text(item.name)
            .fontSize(14)
            .fontColor(this.isAccountSelected(item) ? AppColors.SURFACE : AppColors.INK)
            .height(36)
            .padding({ left: 14, right: 14 })
            .borderRadius(AppRadius.PILL)
            .backgroundColor(this.isAccountSelected(item) ? item.color : AppColors.SURFACE_SOFT)
            .margin({ right: 10, bottom: 10 })
            .onClick(() => {
              this.vm.selectedAccount = item;
            })
        }, (item: AccountModel) => `${item.id}`)
      }
      .width('100%')
    }
    .padding(16)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 22, color: AppColors.SHADOW, offsetY: 9 })
  }

  @Builder
  private RemarkPanel() {
    Column({ space: 8 }) {
      Text('备注')
        .fontSize(13)
        .fontColor(AppColors.MUTED)
        .width('100%')
      TextInput({ text: this.vm.remark, placeholder: '可选' })
        .fontSize(15)
        .height(48)
        .backgroundColor(AppColors.SURFACE_SOFT)
        .borderRadius(18)
        .padding({ left: 14, right: 14 })
        .onChange((value: string) => {
          this.vm.remark = value;
        })
    }
    .padding(16)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 22, color: AppColors.SHADOW, offsetY: 9 })
  }

  @Builder
  private DateTimePanel() {
    Column({ space: 12 }) {
      Row() {
        Column({ space: 3 }) {
          Text('账单日期')
            .fontSize(13)
            .fontColor(AppColors.MUTED)
          Text(this.recordDateLabel())
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.INK)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Button('选择日期')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.CHART_BLUE)
          .height(40)
          .backgroundColor(AppColors.SURFACE_TINT)
          .borderRadius(AppRadius.PILL)
          .onClick(() => this.showDatePicker())
      }
      .width('100%')

      Row() {
        Column({ space: 3 }) {
          Text('账单时间')
            .fontSize(13)
            .fontColor(AppColors.MUTED)
          Text(this.recordTimeLabel())
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.INK)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Button('选择时间')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.CHART_BLUE)
          .height(40)
          .backgroundColor(AppColors.SURFACE_TINT)
          .borderRadius(AppRadius.PILL)
          .onClick(() => this.showTimePicker())
      }
      .width('100%')
    }
    .padding(16)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 22, color: AppColors.SHADOW, offsetY: 9 })
  }

  private async save(): Promise<void> {
    try {
      this.vm.amountText = this.amountText;
      const savedRecord = await this.vm.save();
      this.applySavedRecord(savedRecord);
      await this.refreshAppState();
      ToastUtil.show(this.vm.recordId > 0 ? '账单已更新' : '已保存');
      router.back();
    } catch (error) {
      ToastUtil.show(ToastUtil.error(error, '账单保存失败'));
    }
  }

  private async switchType(type: RecordType.EXPENSE | RecordType.INCOME): Promise<void> {
    if (this.vm.type === type) {
      return;
    }
    await this.vm.switchType(type);
    await this.loadTemplates();
  }

  private async loadTemplates(): Promise<void> {
    try {
      this.templates = await this.templateRepository.listByType(this.vm.type, 8);
    } catch (error) {
      this.templates = [];
    }
  }

  private async applyTemplate(item: RecordTemplateModel): Promise<void> {
    try {
      if (item.type !== this.vm.type) {
        await this.vm.switchType(item.type);
      }
      this.amountText = this.formatAmountInput(item.amount);
      this.vm.remark = item.remark;
      this.vm.selectedCategory = this.vm.categories.find((category: CategoryModel) => category.id === item.categoryId) || this.vm.selectedCategory;
      this.vm.selectedAccount = this.vm.accounts.find((account: AccountModel) => account.id === item.accountId) || this.vm.selectedAccount;
      if (item.id) {
        await this.templateRepository.markUsed(item.id);
      }
      await this.loadTemplates();
      ToastUtil.show('已套用模板');
    } catch (error) {
      ToastUtil.show('模板套用失败');
    }
  }

  private async saveCurrentTemplate(): Promise<void> {
    const amount = NumberUtil.toCentSafe(this.amountText);
    if (!amount || amount <= 0) {
      ToastUtil.show('请输入正确金额');
      return;
    }
    if (!this.vm.selectedCategory || !this.vm.selectedAccount) {
      ToastUtil.show('请选择分类和账户');
      return;
    }
    const now = Date.now();
    const remark = this.vm.remark.trim();
    const template: RecordTemplateModel = {
      name: remark || this.vm.selectedCategory.name,
      type: this.vm.type,
      amount,
      categoryId: this.vm.selectedCategory.id || 0,
      accountId: this.vm.selectedAccount.id || 0,
      remark,
      useCount: 0,
      createTime: now,
      updateTime: now
    };
    try {
      await this.templateRepository.save(template);
      await this.loadTemplates();
      ToastUtil.show('模板已保存');
    } catch (error) {
      ToastUtil.show('模板保存失败');
    }
  }

  private async deleteTemplate(item: RecordTemplateModel): Promise<void> {
    if (!item.id) {
      return;
    }
    try {
      await this.templateRepository.deleteById(item.id);
      await this.loadTemplates();
      ToastUtil.show('模板已删除');
    } catch (error) {
      ToastUtil.show('模板删除失败');
    }
  }

  private applySavedRecord(record: RecordModel): void {
    if (!record.id || !this.vm.selectedCategory || !this.vm.selectedAccount) {
      return;
    }
    const item: RecordListItem = {
      id: record.id,
      type: record.type,
      amount: record.amount,
      categoryId: record.categoryId,
      accountId: record.accountId,
      transferAccountId: record.transferAccountId,
      recordTime: record.recordTime,
      remark: record.remark,
      createTime: record.createTime,
      updateTime: record.updateTime,
      categoryName: this.vm.selectedCategory.name,
      categoryIcon: this.vm.selectedCategory.icon,
      categoryColor: this.vm.selectedCategory.color,
      accountName: this.vm.selectedAccount.name
    };
    AppState.getInstance().applyRecordUpdate(item);
  }

  private async refreshAppState(): Promise<void> {
    try {
      await AppState.getInstance().refreshAfterRecordChange();
    } catch (error) {
      // The saved record is already durable; the visible pages also refresh on show.
    }
  }

  private normalizeAmount(value: string): string {
    return NumberUtil.normalizeAmountInput(value);
  }

  private formatAmountInput(value: number): string {
    const amount = Math.round(value * 100) / 100;
    return `${amount}`;
  }

  private showDatePicker(): void {
    const current = new Date(this.effectiveRecordTime());
    DatePickerDialog.show({
      selected: current,
      start: new Date(2000, 0, 1),
      end: new Date(),
      onAccept: (value: DatePickerResult) => {
        const next = new Date(
          value.year ?? current.getFullYear(),
          value.month ?? current.getMonth(),
          value.day ?? current.getDate(),
          current.getHours(),
          current.getMinutes()
        );
        this.vm.recordTime = next.getTime();
      }
    });
  }

  private showTimePicker(): void {
    const current = new Date(this.effectiveRecordTime());
    TimePickerDialog.show({
      selected: current,
      useMilitaryTime: true,
      onAccept: (value: TimePickerResult) => {
        current.setHours(value.hour, value.minute, 0, 0);
        this.vm.recordTime = current.getTime();
      }
    });
  }

  private effectiveRecordTime(): number {
    return this.vm.recordTime > 0 ? this.vm.recordTime : Date.now();
  }

  private recordDateLabel(): string {
    const date = new Date(this.effectiveRecordTime());
    return `${date.getFullYear()}年${date.getMonth() + 1}月${date.getDate()}日`;
  }

  private recordTimeLabel(): string {
    const date = new Date(this.effectiveRecordTime());
    const hour = `${date.getHours()}`.padStart(2, '0');
    const minute = `${date.getMinutes()}`.padStart(2, '0');
    return `${hour}:${minute}`;
  }

  private isCategorySelected(item: CategoryModel): boolean {
    return !!this.vm.selectedCategory && this.vm.selectedCategory.id === item.id;
  }

  private isAccountSelected(item: AccountModel): boolean {
    return !!this.vm.selectedAccount && this.vm.selectedAccount.id === item.id;
  }

  private isWide(): boolean {
    return this.viewportWidth >= Breakpoints.WIDE;
  }

  private contentMaxWidth(): number {
    return this.viewportWidth >= Breakpoints.DESKTOP ? LayoutSizes.CONTENT_MAX : LayoutSizes.CONTENT_COMPACT;
  }
}
