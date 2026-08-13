import { router } from '@kit.ArkUI';
import { CategoryIcon } from '../components/CategoryIcon';
import { CategoryModel } from '../model/Category';
import { AccountModel } from '../model/Account';
import { RecordListItem, RecordModel, RecordType } from '../model/Record';
import { RecordViewModel } from '../viewmodel/RecordViewModel';
import { AppState } from '../viewmodel/AppState';
import { ToastUtil } from '../utils/ToastUtil';
import { AppColors, AppRadius, AppSpace, Breakpoints, LayoutSizes } from '../constants/DesignSystem';

interface RecordEditParams {
  recordId?: number;
  recordTime?: number;
}

@Entry
@Component
struct RecordEdit {
  @State vm: RecordViewModel = new RecordViewModel();
  @State amountText: string = '';
  @State viewportWidth: number = 0;

  aboutToAppear(): void {
    const params = router.getParams() as RecordEditParams;
    const recordId = Number(params?.recordId || 0);
    this.vm.init(getContext(this), recordId).then(() => {
      if (recordId <= 0 && Number(params?.recordTime || 0) > 0) {
        this.vm.recordTime = Number(params.recordTime);
      }
      this.amountText = this.vm.amountText;
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
        this.vm.switchType(type);
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
        .type(InputType.Number)
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
    const cleaned = value.replace(/[^\d.]/g, '');
    const parts = cleaned.split('.');
    if (parts.length <= 1) {
      return cleaned;
    }
    return `${parts[0]}.${parts.slice(1).join('').substring(0, 2)}`;
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
