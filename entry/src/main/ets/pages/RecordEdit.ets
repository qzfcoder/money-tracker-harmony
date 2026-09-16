import { router } from '@kit.ArkUI';
import { CategoryIcon } from '../components/CategoryIcon';
import { CategoryModel } from '../model/Category';
import { AccountModel } from '../model/Account';
import { RecordListItem, RecordModel, RecordType } from '../model/Record';
import { RecordTemplateModel } from '../model/RecordTemplate';
import { LedgerEnhancementRepository } from '../repository/LedgerEnhancementRepository';
import { RecordTemplateRepository } from '../repository/RecordTemplateRepository';
import { RecordViewModel } from '../viewmodel/RecordViewModel';
import { AppState } from '../viewmodel/AppState';
import { ToastUtil } from '../utils/ToastUtil';
import { NumberUtil } from '../utils/NumberUtil';
import { AppColors, AppRadius, AppSpace, Breakpoints, LayoutSizes } from '../constants/DesignSystem';
import { SpendingCardService } from '../widget/SpendingCardService';

interface RecordEditParams {
  recordId?: number;
  recordTime?: number;
  templateId?: number;
  ledgerName?: string;
}

interface DatePickerResult {
  year?: number;
  month?: number;
  day?: number;
}

@Entry
@Component
struct RecordEdit {
  private enhancementRepository: LedgerEnhancementRepository = new LedgerEnhancementRepository();
  private templateRepository: RecordTemplateRepository = new RecordTemplateRepository();

  @State vm: RecordViewModel = new RecordViewModel();
  @State amountText: string = '';
  @State templates: RecordTemplateModel[] = [];
  @State templateCount: number = 0;
  @State selectedTemplateId: number = 0;
  @State ledgerOptions: string[] = ['日常账本'];
  @State showMoreDetails: boolean = false;
  @State viewportWidth: number = 0;

  aboutToAppear(): void {
    const params = router.getParams() as RecordEditParams;
    const recordId = Number(params?.recordId || 0);
    const templateId = Number(params?.templateId || 0);
    this.vm.init(getContext(this), recordId).then(() => {
      const routeLedger = `${params?.ledgerName || ''}`.trim();
      if (recordId <= 0 && routeLedger.length > 0) {
        this.vm.ledgerName = routeLedger;
      }
      if (recordId <= 0 && Number(params?.recordTime || 0) > 0) {
        this.vm.recordTime = Number(params.recordTime);
      }
      this.amountText = this.vm.amountText;
      this.showMoreDetails = this.vm.type === RecordType.TRANSFER;
      Promise.all([this.loadTemplates(), this.loadLedgers()]).then(() => {
        if (recordId <= 0 && templateId > 0) {
          this.applyTemplateById(templateId);
        }
      });
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
                this.TemplatePanel()
                this.AmountPanel()
                this.LedgerPanel()
                this.MoreInfoSummary()
                if (this.showMoreDetails) {
                  this.DateTimePanel()
                  this.RemarkPanel()
                }
              }
              .layoutWeight(1)
              .constraintSize({ minWidth: 340 })

              Column({ space: 20 }) {
                this.CategoryPanel()
                if (this.showMoreDetails) {
                  this.AccountPanel()
                }
              }
              .layoutWeight(1)
              .constraintSize({ minWidth: 340 })
            }
            .width('100%')
          } else {
            Column({ space: 20 }) {
              this.TypeSwitch()
              this.TemplatePanel()
              this.AmountPanel()
              this.LedgerPanel()
              this.CategoryPanel()
              this.MoreInfoSummary()
              if (this.showMoreDetails) {
                this.AccountPanel()
                this.DateTimePanel()
                this.RemarkPanel()
              }
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
      this.TypeButton('转账', RecordType.TRANSFER)
    }
    .height(50)
    .padding(4)
    .backgroundColor('#E7EAEE')
    .borderRadius(AppRadius.PILL)
  }

  @Builder
  private TypeButton(label: string, type: RecordType.EXPENSE | RecordType.INCOME | RecordType.TRANSFER) {
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
        Text(this.vm.type === RecordType.EXPENSE ? '支' : this.vm.type === RecordType.INCOME ? '收' : '转')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.vm.type === RecordType.EXPENSE ? AppColors.EXPENSE :
            this.vm.type === RecordType.INCOME ? AppColors.INCOME : AppColors.CHART_BLUE)
          .width(44)
          .height(44)
          .textAlign(TextAlign.Center)
          .borderRadius(15)
          .backgroundColor(this.vm.type === RecordType.EXPENSE ? AppColors.softDanger() :
            this.vm.type === RecordType.INCOME ? AppColors.softGreen() : AppColors.SURFACE_TINT)
        Column({ space: 3 }) {
          Text('金额')
            .fontSize(13)
            .fontColor(AppColors.MUTED)
            Text(this.vm.type === RecordType.EXPENSE ? '记录一笔支出' :
              this.vm.type === RecordType.INCOME ? '记录一笔收入' : '在账户之间转一笔钱')
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
          this.selectedTemplateId = 0;
        })
    }
    .padding(16)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 22, color: AppColors.SHADOW, offsetY: 9 })
  }

  @Builder
  private TemplatePanel() {
    if (this.vm.type !== RecordType.TRANSFER) {
      Column({ space: 10 }) {
        Row() {
          Column({ space: 2 }) {
            Text('快捷模板')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.INK)
            Text(`${this.vm.type === RecordType.INCOME ? '收入' : '支出'}模板 · 共 ${this.templateCount} 个`)
              .fontSize(11)
              .fontColor(AppColors.MUTED)
          }
          .alignItems(HorizontalAlign.Start)
          Blank()
          Button('存为模板')
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
          Text('还没有模板，填好一笔后可保存为模板')
            .fontSize(12)
            .fontColor(AppColors.MUTED)
            .width('100%')
            .height(38)
            .textAlign(TextAlign.Center)
            .backgroundColor(AppColors.SURFACE_SOFT)
            .borderRadius(14)
        } else {
          Scroll() {
            Row({ space: 8 }) {
              ForEach(this.templates, (item: RecordTemplateModel) => {
                this.TemplateChip(item, this.selectedTemplateId === (item.id || 0))
              }, (item: RecordTemplateModel) =>
                `${item.id}-${this.selectedTemplateId === (item.id || 0) ? 'selected' : 'idle'}`)
            }
          }
          .width('100%')
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
        }
      }
      .padding({ left: 16, right: 16, top: 13, bottom: 13 })
      .backgroundColor(AppColors.SURFACE)
      .borderRadius(AppRadius.CARD)
      .shadow({ radius: 22, color: AppColors.SHADOW, offsetY: 9 })
    }
  }

  @Builder
  private TemplateChip(item: RecordTemplateModel, selected: boolean) {
    Row({ space: 8 }) {
      Text(selected ? '✓' : item.name.substring(0, 1))
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor(selected ? AppColors.CHART_BLUE : (item.categoryColor || AppColors.CHART_BLUE))
        .width(28)
        .height(28)
        .textAlign(TextAlign.Center)
        .backgroundColor(selected ? '#FFFFFF' : AppColors.SURFACE)
        .borderRadius(14)
      Column({ space: 4 }) {
        Text(item.name)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(selected ? '#FFFFFF' : AppColors.INK)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        Text(`${NumberUtil.money(item.amount)} · ${item.accountName || '账户'}`)
          .fontSize(12)
          .fontColor(selected ? '#EAF2FF' : AppColors.MUTED)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .onClick(() => this.applyTemplate(item))

      Button('删除')
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor(selected ? AppColors.CHART_BLUE : AppColors.EXPENSE)
        .width(58)
        .height(32)
        .padding({ left: 4, right: 4 })
        .backgroundColor(selected ? '#FFFFFF' : AppColors.softDanger())
        .border({ width: 1, color: selected ? '#FFFFFF' : AppColors.EXPENSE })
        .borderRadius(16)
        .onClick(() => this.deleteTemplate(item))
    }
    .alignItems(VerticalAlign.Top)
    .width(210)
    .height(64)
    .padding({ left: 10, right: 8, top: 8, bottom: 8 })
    .backgroundColor(selected ? AppColors.CHART_BLUE : AppColors.SURFACE_SOFT)
    .border({ width: selected ? 2 : 1, color: selected ? AppColors.CHART_BLUE : (item.categoryColor || AppColors.LINE) })
    .borderRadius(14)
  }

  @Builder
  private MoreInfoSummary() {
    Column({ space: 5 }) {
      Row() {
        Text('更多信息')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
        Blank()
        Text(this.showMoreDetails ? '收起' : '修改')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.CHART_BLUE)
      }
      .width('100%')

      Text(this.moreInfoText())
        .fontSize(12)
        .fontColor(AppColors.MUTED)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .onClick(() => {
      this.showMoreDetails = !this.showMoreDetails;
    })
  }

  @Builder
  private CategoryPanel() {
    if (this.vm.type !== RecordType.TRANSFER) {
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
              this.selectedTemplateId = 0;
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
        Text(this.vm.type === RecordType.TRANSFER ? '选择转出账户' : '默认使用最近账户')
          .fontSize(12)
          .fontColor(AppColors.MUTED)
      }
      .width('100%')

      if (this.vm.type === RecordType.TRANSFER) {
        Text('转入账户')
          .fontSize(13)
          .fontColor(AppColors.MUTED)
          .width('100%')
        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
          ForEach(this.vm.accounts, (item: AccountModel) => {
            Text(item.name)
              .fontSize(14)
              .fontColor(this.isTransferAccountSelected(item) ? AppColors.SURFACE : AppColors.INK)
              .height(36)
              .padding({ left: 14, right: 14 })
              .borderRadius(AppRadius.PILL)
              .backgroundColor(this.isTransferAccountSelected(item) ? item.color : AppColors.SURFACE_SOFT)
              .margin({ right: 10, bottom: 10 })
              .onClick(() => {
                if (item.id !== this.vm.selectedAccount?.id) {
                  this.vm.selectedTransferAccount = item;
                }
              })
          }, (item: AccountModel) => `transfer-${item.id}`)
        }
        .width('100%')
      }

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
              this.selectedTemplateId = 0;
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
  private LedgerPanel() {
    Column({ space: 10 }) {
      Row() {
        Column({ space: 2 }) {
          Text('所属账本')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.INK)
          Text('本笔账单将归入所选账本')
            .fontSize(11)
            .fontColor(AppColors.MUTED)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Text(this.vm.ledgerName)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.CHART_BLUE)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .constraintSize({ maxWidth: '42%' })
      }
      .width('100%')

      Scroll() {
        Row({ space: 8 }) {
          ForEach(this.ledgerOptions, (item: string) => {
            this.LedgerChip(item)
          }, (item: string) => `${item}-${this.vm.ledgerName === item ? 'selected' : 'idle'}`)
        }
      }
      .width('100%')
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 13, bottom: 13 })
    .backgroundColor(AppColors.SURFACE)
    .border({ width: 1, color: AppColors.LINE })
    .borderRadius(AppRadius.CARD)
  }

  @Builder
  private LedgerChip(ledgerName: string) {
    Text(ledgerName)
      .fontSize(14)
      .fontWeight(this.vm.ledgerName === ledgerName ? FontWeight.Bold : FontWeight.Medium)
      .fontColor(this.vm.ledgerName === ledgerName ? '#FFFFFF' : AppColors.INK)
      .height(36)
      .padding({ left: 14, right: 14 })
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .constraintSize({ minWidth: 72, maxWidth: 150 })
      .textAlign(TextAlign.Center)
      .backgroundColor(this.vm.ledgerName === ledgerName ? AppColors.CHART_BLUE : AppColors.SURFACE_SOFT)
      .border({
        width: this.vm.ledgerName === ledgerName ? 2 : 1,
        color: this.vm.ledgerName === ledgerName ? AppColors.CHART_BLUE : AppColors.LINE
      })
      .borderRadius(AppRadius.PILL)
      .onClick(() => this.selectLedger(ledgerName))
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
          this.selectedTemplateId = 0;
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
      const isNewRecord = this.vm.recordId <= 0;
      this.vm.amountText = this.amountText;
      if (isNewRecord && this.vm.type !== RecordType.TRANSFER) {
        this.vm.remark = await this.enhancementRepository.decorateRemark(getContext(this), this.vm.remark);
      }
      const savedRecord = await this.vm.save();
      this.applySavedRecord(savedRecord);
      await this.refreshAppState();
      await this.refreshSpendingCard();
      ToastUtil.show(isNewRecord ? '已保存' : '账单已更新');
      router.back();
    } catch (error) {
      ToastUtil.show(ToastUtil.error(error, '账单保存失败'));
    }
  }

  private async switchType(type: RecordType.EXPENSE | RecordType.INCOME | RecordType.TRANSFER): Promise<void> {
    if (this.vm.type === type) {
      return;
    }
    await this.vm.switchType(type);
    this.selectedTemplateId = 0;
    this.showMoreDetails = type === RecordType.TRANSFER;
    await this.loadTemplates();
  }

  private async loadTemplates(): Promise<void> {
    if (this.vm.type === RecordType.TRANSFER) {
      this.templates = [];
      this.templateCount = 0;
      return;
    }
    const recordType: RecordType.EXPENSE | RecordType.INCOME =
      this.vm.type === RecordType.INCOME ? RecordType.INCOME : RecordType.EXPENSE;
    try {
      this.templates = await this.templateRepository.listByType(recordType, 8);
      this.templateCount = await this.templateRepository.countByType(recordType);
    } catch (error) {
      this.templates = [];
      this.templateCount = 0;
    }
  }

  private async loadLedgers(): Promise<void> {
    try {
      const data = await this.enhancementRepository.load(getContext(this));
      const ledgers = data.ledgers.slice();
      if (ledgers.indexOf(this.vm.ledgerName) < 0) {
        ledgers.push(this.vm.ledgerName);
      }
      this.ledgerOptions = ledgers;
    } catch (error) {
      this.ledgerOptions = [this.vm.ledgerName || '日常账本'];
    }
  }

  private async selectLedger(ledgerName: string): Promise<void> {
    if (this.vm.ledgerName === ledgerName) {
      return;
    }
    this.vm.ledgerName = ledgerName;
    try {
      await this.enhancementRepository.setActiveLedger(getContext(this), ledgerName);
      ToastUtil.show(`已切换到“${ledgerName}”`);
    } catch (error) {
      ToastUtil.show('已用于当前账单，但默认账本保存失败');
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
      this.selectedTemplateId = item.id || 0;
      if (item.id) {
        await this.templateRepository.markUsed(item.id);
      }
      await this.loadTemplates();
      ToastUtil.show('已套用模板');
    } catch (error) {
      ToastUtil.show('模板套用失败');
    }
  }

  private async applyTemplateById(templateId: number): Promise<void> {
    try {
      const item = await this.templateRepository.findById(templateId);
      if (!item) {
        ToastUtil.show('模板不存在或已删除');
        return;
      }
      await this.applyTemplate(item);
    } catch (error) {
      ToastUtil.show('模板读取失败');
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
    if (this.vm.type === RecordType.TRANSFER) {
      ToastUtil.show('转账不保存为模板');
      return;
    }
    const recordType: RecordType.EXPENSE | RecordType.INCOME =
      this.vm.type === RecordType.INCOME ? RecordType.INCOME : RecordType.EXPENSE;
    const now = Date.now();
    const remark = this.vm.remark.trim();
    const template: RecordTemplateModel = {
      name: remark || this.vm.selectedCategory.name,
      type: recordType,
      amount,
      categoryId: this.vm.selectedCategory.id || 0,
      accountId: this.vm.selectedAccount.id || 0,
      remark,
      useCount: 0,
      createTime: now,
      updateTime: now
    };
    try {
      this.selectedTemplateId = await this.templateRepository.save(template);
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
      if (this.selectedTemplateId === item.id) {
        this.selectedTemplateId = 0;
      }
      await this.loadTemplates();
      ToastUtil.show('模板已删除');
    } catch (error) {
      ToastUtil.show('模板删除失败');
    }
  }

  private applySavedRecord(record: RecordModel): void {
    if (!record.id || !this.vm.selectedAccount) {
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
      ledgerName: record.ledgerName,
      remark: record.remark,
      createTime: record.createTime,
      updateTime: record.updateTime,
      categoryName: this.vm.selectedCategory?.name || '转账',
      categoryIcon: this.vm.selectedCategory?.icon || '转',
      categoryColor: this.vm.selectedCategory?.color || AppColors.CHART_BLUE,
      accountName: this.vm.selectedAccount.name,
      transferAccountName: this.vm.selectedTransferAccount?.name
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

  private async refreshSpendingCard(): Promise<void> {
    try {
      await SpendingCardService.refreshAllForms(getContext(this));
    } catch (error) {
      // Card refresh is best-effort; the system scheduled update will retry later.
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

  private moreInfoText(): string {
    const accountName = this.vm.selectedAccount?.name || '默认账户';
    const ledgerName = this.vm.ledgerName || '日常账本';
    if (this.vm.type === RecordType.TRANSFER) {
      const transferAccountName = this.vm.selectedTransferAccount?.name || '请选择转入账户';
      return `${accountName} → ${transferAccountName} · ${ledgerName} · ${this.recordDateLabel()}`;
    }
    return `${accountName} · ${ledgerName} · ${this.recordDateLabel()} ${this.recordTimeLabel()}`;
  }

  private isCategorySelected(item: CategoryModel): boolean {
    return !!this.vm.selectedCategory && this.vm.selectedCategory.id === item.id;
  }

  private isAccountSelected(item: AccountModel): boolean {
    return !!this.vm.selectedAccount && this.vm.selectedAccount.id === item.id;
  }

  private isTransferAccountSelected(item: AccountModel): boolean {
    return !!this.vm.selectedTransferAccount && this.vm.selectedTransferAccount.id === item.id;
  }

  private isWide(): boolean {
    return this.viewportWidth >= Breakpoints.WIDE;
  }

  private contentMaxWidth(): number {
    return this.viewportWidth >= Breakpoints.DESKTOP ? LayoutSizes.CONTENT_MAX : LayoutSizes.CONTENT_COMPACT;
  }
}
