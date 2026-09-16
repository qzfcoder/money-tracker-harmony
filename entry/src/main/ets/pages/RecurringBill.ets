import { router } from '@kit.ArkUI';
import { AppDatabase } from '../database/AppDatabase';
import { AccountModel } from '../model/Account';
import { CategoryModel } from '../model/Category';
import { RecurringBillModel, RecurringFrequency } from '../model/RecurringBill';
import { RecordType } from '../model/Record';
import { AccountRepository } from '../repository/AccountRepository';
import { CategoryRepository } from '../repository/CategoryRepository';
import { RecurringBillRepository } from '../repository/RecurringBillRepository';
import { AppColors, AppRadius, AppSpace, Breakpoints, LayoutSizes } from '../constants/DesignSystem';
import { AppState } from '../viewmodel/AppState';
import { NumberUtil } from '../utils/NumberUtil';
import { ToastUtil } from '../utils/ToastUtil';
import { DateUtil } from '../utils/DateUtil';
import { SpendingCardService } from '../widget/SpendingCardService';

@Entry
@Component
struct RecurringBill {
  private repository: RecurringBillRepository = new RecurringBillRepository();
  private categoryRepository: CategoryRepository = new CategoryRepository();
  private accountRepository: AccountRepository = new AccountRepository();

  @State viewportWidth: number = 0;
  @State bills: RecurringBillModel[] = [];
  @State expenseCategories: CategoryModel[] = [];
  @State incomeCategories: CategoryModel[] = [];
  @State accounts: AccountModel[] = [];
  @State editorVisible: boolean = false;
  @State editingId: number = 0;
  @State draftName: string = '';
  @State draftType: RecordType.EXPENSE | RecordType.INCOME = RecordType.EXPENSE;
  @State draftAmountText: string = '';
  @State draftCategoryId: number = 0;
  @State draftAccountId: number = 0;
  @State draftFrequency: RecurringFrequency = RecurringFrequency.MONTHLY;
  @State draftDayText: string = '1';
  @State draftRemark: string = '';
  @State draftEnabled: boolean = true;
  @StorageLink('ledgerIsDarkMode') isDarkMode: boolean = false;

  aboutToAppear(): void {
    this.loadAll();
  }

  onPageShow(): void {
    this.loadAll();
  }

  build() {
    Column() {
      this.Header()
      Scroll() {
        Column({ space: 16 }) {
          this.SummaryCard()
          this.Toolbar()
          if (this.editorVisible) {
            this.EditorCard()
          }
          this.ListCard()
        }
        .width('100%')
        .constraintSize({ maxWidth: this.contentMaxWidth() })
        .alignSelf(ItemAlign.Center)
        .padding({ left: AppSpace.PAGE, right: AppSpace.PAGE, top: 10, bottom: 24 })
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
        Text('周期账单')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .width('100%')
        Text('房租、会员、工资等固定收支')
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
  private SummaryCard() {
    Column({ space: 14 }) {
      Row() {
        Text('循')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.CHART_BLUE)
          .width(50)
          .height(50)
          .textAlign(TextAlign.Center)
          .borderRadius(18)
          .backgroundColor(AppColors.softBlue())
        Blank()
        Text(`${this.enabledCount()} 项启用`)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.LEDGER)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor(AppColors.SURFACE_TINT)
          .borderRadius(AppRadius.PILL)
      }
      .width('100%')

      Text(NumberUtil.compactMoney(this.monthlyEstimate()))
        .fontSize(this.isPhone() ? 32 : 38)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.INK)
        .width('100%')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(this.summaryHint())
        .fontSize(13)
        .fontColor(AppColors.MUTED)
        .lineHeight(20)
        .width('100%')
    }
    .width('100%')
    .padding(18)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 24, color: AppColors.SHADOW, offsetY: 10 })
  }

  @Builder
  private Toolbar() {
    Row({ space: 10 }) {
      Button(this.editorVisible ? '收起' : '新增周期账单')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.SURFACE)
        .height(48)
        .layoutWeight(1)
        .backgroundColor(AppColors.CHART_BLUE)
        .borderRadius(AppRadius.PILL)
        .onClick(() => {
          if (this.editorVisible) {
            this.editorVisible = false;
          } else {
            this.startCreate();
          }
        })
      Button('生成到今天')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.CHART_GREEN)
        .height(48)
        .layoutWeight(1)
        .backgroundColor(AppColors.softGreen())
        .borderRadius(AppRadius.PILL)
        .onClick(() => this.generateDue())
    }
    .width('100%')
  }

  @Builder
  private EditorCard() {
    Column({ space: 12 }) {
      this.CardTitle(this.editingId > 0 ? '修改周期账单' : '新增周期账单', this.draftEnabled ? '启用' : '停用')
      Row({ space: 8 }) {
        this.TypeButton('支出', RecordType.EXPENSE)
        this.TypeButton('收入', RecordType.INCOME)
      }
      .height(44)
      .padding(4)
      .backgroundColor(AppColors.TRACK)
      .borderRadius(AppRadius.PILL)

      TextInput({ text: this.draftName, placeholder: '名称，如房租、会员、工资' })
        .height(48)
        .fontSize(15)
        .fontColor(AppColors.INK)
        .backgroundColor(AppColors.SURFACE_SOFT)
        .borderRadius(16)
        .padding({ left: 14, right: 14 })
        .onChange((value: string) => {
          this.draftName = value;
        })

      Row({ space: 10 }) {
        TextInput({ text: this.draftAmountText, placeholder: '金额' })
          .type(InputType.NUMBER_DECIMAL)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .height(48)
          .layoutWeight(1)
          .backgroundColor(AppColors.SURFACE_SOFT)
          .borderRadius(16)
          .padding({ left: 14, right: 14 })
          .onChange((value: string) => {
            this.draftAmountText = NumberUtil.normalizeAmountInput(value);
          })
        TextInput({ text: this.draftDayText, placeholder: this.draftFrequency === RecurringFrequency.MONTHLY ? '日' : '周' })
          .type(InputType.NUMBER_DECIMAL)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .height(48)
          .width(82)
          .textAlign(TextAlign.Center)
          .backgroundColor(AppColors.SURFACE_SOFT)
          .borderRadius(16)
          .onChange((value: string) => {
            this.draftDayText = value.replace(/[^0-9]/g, '');
          })
      }
      .width('100%')

      Row({ space: 8 }) {
        this.FrequencyButton('每月', RecurringFrequency.MONTHLY)
        this.FrequencyButton('每周', RecurringFrequency.WEEKLY)
        this.ToggleButton(this.draftEnabled ? '停用' : '启用')
      }
      .height(42)
      .width('100%')

      this.CategoryScroller()
      this.AccountScroller()

      TextInput({ text: this.draftRemark, placeholder: '备注，可选' })
        .height(44)
        .fontSize(14)
        .fontColor(AppColors.INK)
        .backgroundColor(AppColors.SURFACE_SOFT)
        .borderRadius(16)
        .padding({ left: 14, right: 14 })
        .onChange((value: string) => {
          this.draftRemark = value;
        })

      Row({ space: 10 }) {
        Button('保存')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.SURFACE)
          .height(46)
          .layoutWeight(1)
          .backgroundColor(AppColors.CHART_BLUE)
          .borderRadius(AppRadius.PILL)
          .onClick(() => this.saveDraft())
        Button('取消')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.MUTED)
          .height(46)
          .width(96)
          .backgroundColor(AppColors.SURFACE_SOFT)
          .borderRadius(AppRadius.PILL)
          .onClick(() => {
            this.editorVisible = false;
          })
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
  private ListCard() {
    Column({ space: 12 }) {
      this.CardTitle('周期列表', `${this.bills.length} 项`)
      if (this.bills.length === 0) {
        Column({ space: 8 }) {
          Text('还没有周期账单')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.INK)
          Text('可以先添加房租、会员、工资等固定收支。')
            .fontSize(12)
            .fontColor(AppColors.MUTED)
        }
        .width('100%')
        .height(110)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(AppColors.SURFACE_SOFT)
        .borderRadius(18)
      } else {
        ForEach(this.bills, (item: RecurringBillModel) => {
          this.BillRow(item)
        }, (item: RecurringBillModel) => `${item.id}-${item.updateTime}-${item.enabled ? 1 : 0}`)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 20, color: AppColors.SHADOW, offsetY: 8 })
  }

  @Builder
  private BillRow(item: RecurringBillModel) {
    Column({ space: 10 }) {
      Row({ space: 12 }) {
        Text(item.name.substring(0, 1))
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(item.type === RecordType.INCOME ? AppColors.CHART_GREEN : AppColors.CHART_PINK)
          .width(42)
          .height(42)
          .textAlign(TextAlign.Center)
          .borderRadius(16)
          .backgroundColor(item.type === RecordType.INCOME ? AppColors.softGreen() : AppColors.softPink())
        Column({ space: 3 }) {
          Text(item.name)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.INK)
            .width('100%')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(`${this.typeText(item.type)} · ${this.frequencyText(item)}`)
            .fontSize(12)
            .fontColor(AppColors.MUTED)
            .width('100%')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Text(NumberUtil.compactMoney(item.amount))
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(item.type === RecordType.INCOME ? AppColors.CHART_GREEN : AppColors.EXPENSE)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .constraintSize({ maxWidth: 112 })
      }
      .width('100%')

      Row({ space: 8 }) {
        Text(this.dueText(item))
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.dueColor(item))
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor(this.dueBgColor(item))
          .borderRadius(AppRadius.PILL)
        Text(this.dueHint(item))
          .fontSize(12)
          .fontColor(AppColors.MUTED)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')

      Row({ space: 8 }) {
        this.SmallAction('生成', AppColors.CHART_GREEN, AppColors.softGreen(), () => this.generateBill(item))
        this.SmallAction(item.enabled ? '停用' : '启用', AppColors.CHART_BLUE, AppColors.SURFACE_TINT, () => this.toggleBill(item))
        this.SmallAction('修改', AppColors.LEDGER, AppColors.softBlue(), () => this.startEdit(item))
        this.SmallAction('删除', AppColors.EXPENSE, AppColors.softDanger(), () => this.deleteBill(item))
      }
      .width('100%')
    }
    .width('100%')
    .padding(14)
    .backgroundColor(AppColors.SURFACE_SOFT)
    .border({ width: 1, color: AppColors.LINE })
    .borderRadius(18)
  }

  @Builder
  private CardTitle(title: string, badge: string) {
    Row() {
      Text(title)
        .fontSize(19)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.INK)
      Blank()
      Text(badge)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.LEDGER)
        .padding({ left: 12, right: 12, top: 5, bottom: 5 })
        .backgroundColor(AppColors.SURFACE_TINT)
        .borderRadius(AppRadius.PILL)
    }
    .width('100%')
  }

  @Builder
  private TypeButton(label: string, type: RecordType.EXPENSE | RecordType.INCOME) {
    Text(label)
      .fontSize(14)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.draftType === type ? AppColors.SURFACE : AppColors.MUTED)
      .height(36)
      .layoutWeight(1)
      .textAlign(TextAlign.Center)
      .backgroundColor(this.draftType === type ? AppColors.CHART_BLUE : '#00000000')
      .borderRadius(AppRadius.PILL)
      .onClick(() => {
        this.draftType = type;
        this.ensureDraftCategory();
      })
  }

  @Builder
  private FrequencyButton(label: string, frequency: RecurringFrequency) {
    Text(label)
      .fontSize(13)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.draftFrequency === frequency ? AppColors.SURFACE : AppColors.INK)
      .height(42)
      .layoutWeight(1)
      .textAlign(TextAlign.Center)
      .backgroundColor(this.draftFrequency === frequency ? AppColors.CHART_BLUE : AppColors.SURFACE_SOFT)
      .borderRadius(AppRadius.PILL)
      .onClick(() => {
        this.draftFrequency = frequency;
        this.draftDayText = this.normalizeDay(this.draftDayText).toString();
      })
  }

  @Builder
  private ToggleButton(label: string) {
    Text(label)
      .fontSize(13)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.draftEnabled ? AppColors.EXPENSE : AppColors.CHART_GREEN)
      .height(42)
      .width(84)
      .textAlign(TextAlign.Center)
      .backgroundColor(this.draftEnabled ? AppColors.softDanger() : AppColors.softGreen())
      .borderRadius(AppRadius.PILL)
      .onClick(() => {
        this.draftEnabled = !this.draftEnabled;
      })
  }

  @Builder
  private CategoryScroller() {
    Column({ space: 8 }) {
      Text('分类')
        .fontSize(12)
        .fontColor(AppColors.MUTED)
        .width('100%')
      Scroll() {
        Row({ space: 8 }) {
          ForEach(this.currentCategories(), (item: CategoryModel) => {
            Text(item.name)
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.draftCategoryId === item.id ? AppColors.SURFACE : AppColors.INK)
              .height(36)
              .padding({ left: 12, right: 12 })
              .backgroundColor(this.draftCategoryId === item.id ? item.color : AppColors.SURFACE_SOFT)
              .borderRadius(AppRadius.PILL)
              .onClick(() => {
                this.draftCategoryId = item.id || 0;
              })
          }, (item: CategoryModel) => `${item.id}`)
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .height(40)
    }
    .width('100%')
  }

  @Builder
  private AccountScroller() {
    Column({ space: 8 }) {
      Text('账户')
        .fontSize(12)
        .fontColor(AppColors.MUTED)
        .width('100%')
      Scroll() {
        Row({ space: 8 }) {
          ForEach(this.accounts, (item: AccountModel) => {
            Text(item.name)
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.draftAccountId === item.id ? AppColors.SURFACE : AppColors.INK)
              .height(36)
              .padding({ left: 12, right: 12 })
              .backgroundColor(this.draftAccountId === item.id ? item.color : AppColors.SURFACE_SOFT)
              .borderRadius(AppRadius.PILL)
              .onClick(() => {
                this.draftAccountId = item.id || 0;
              })
          }, (item: AccountModel) => `${item.id}`)
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .height(40)
    }
    .width('100%')
  }

  @Builder
  private SmallAction(label: string, color: string, bgColor: string, action: () => void) {
    Text(label)
      .fontSize(13)
      .fontWeight(FontWeight.Bold)
      .fontColor(color)
      .height(36)
      .layoutWeight(1)
      .textAlign(TextAlign.Center)
      .backgroundColor(bgColor)
      .borderRadius(AppRadius.PILL)
      .onClick(action)
  }

  private async loadAll(): Promise<void> {
    try {
      await AppDatabase.getInstance().init(getContext(this));
      this.expenseCategories = await this.categoryRepository.listByType(RecordType.EXPENSE);
      this.incomeCategories = await this.categoryRepository.listByType(RecordType.INCOME);
      this.accounts = await this.accountRepository.list();
      this.bills = await this.repository.list();
      this.ensureDraftDefaults();
    } catch (error) {
      ToastUtil.show('周期账单加载失败');
    }
  }

  private startCreate(): void {
    this.editingId = 0;
    this.draftName = '';
    this.draftType = RecordType.EXPENSE;
    this.draftAmountText = '';
    this.draftFrequency = RecurringFrequency.MONTHLY;
    this.draftDayText = '1';
    this.draftRemark = '';
    this.draftEnabled = true;
    this.ensureDraftDefaults();
    this.editorVisible = true;
  }

  private startEdit(item: RecurringBillModel): void {
    this.editingId = item.id || 0;
    this.draftName = item.name;
    this.draftType = item.type;
    this.draftAmountText = NumberUtil.plainMoney(item.amount);
    this.draftCategoryId = item.categoryId;
    this.draftAccountId = item.accountId;
    this.draftFrequency = item.frequency;
    this.draftDayText = `${item.frequency === RecurringFrequency.MONTHLY ? item.dayOfMonth : item.dayOfWeek}`;
    this.draftRemark = item.remark;
    this.draftEnabled = item.enabled;
    this.editorVisible = true;
  }

  private async saveDraft(): Promise<void> {
    const amount = NumberUtil.toCentSafe(this.draftAmountText);
    if (amount <= 0) {
      ToastUtil.show('请输入有效金额');
      return;
    }
    if (this.draftCategoryId <= 0 || this.draftAccountId <= 0) {
      ToastUtil.show('请选择分类和账户');
      return;
    }
    const now = Date.now();
    const day = this.normalizeDay(this.draftDayText);
    const item: RecurringBillModel = {
      id: this.editingId > 0 ? this.editingId : undefined,
      name: this.draftName.trim() || this.defaultName(),
      type: this.draftType,
      amount,
      categoryId: this.draftCategoryId,
      accountId: this.draftAccountId,
      frequency: this.draftFrequency,
      dayOfMonth: this.draftFrequency === RecurringFrequency.MONTHLY ? day : 1,
      dayOfWeek: this.draftFrequency === RecurringFrequency.WEEKLY ? day : 1,
      remark: this.draftRemark.trim(),
      enabled: this.draftEnabled,
      lastGeneratedKey: '',
      createTime: now,
      updateTime: now
    };
    try {
      await this.repository.save(item);
      this.editorVisible = false;
      await this.loadAll();
      ToastUtil.show('周期账单已保存');
    } catch (error) {
      ToastUtil.show('保存失败，请稍后重试');
    }
  }

  private async toggleBill(item: RecurringBillModel): Promise<void> {
    const next: RecurringBillModel = {
      id: item.id,
      name: item.name,
      type: item.type,
      amount: item.amount,
      categoryId: item.categoryId,
      accountId: item.accountId,
      frequency: item.frequency,
      dayOfMonth: item.dayOfMonth,
      dayOfWeek: item.dayOfWeek,
      remark: item.remark,
      enabled: !item.enabled,
      lastGeneratedKey: item.lastGeneratedKey,
      createTime: item.createTime,
      updateTime: Date.now()
    };
    await this.repository.save(next);
    await this.loadAll();
  }

  private async deleteBill(item: RecurringBillModel): Promise<void> {
    if (!item.id) {
      return;
    }
    await this.repository.deleteById(item.id);
    await this.loadAll();
    ToastUtil.show('已删除');
  }

  private async generateDue(): Promise<void> {
    try {
      const result = await this.repository.generateDue(Date.now());
      await AppState.getInstance().refreshAll();
      await SpendingCardService.refreshAllForms(getContext(this));
      await this.loadAll();
      ToastUtil.show(result.generatedCount > 0 ? `已生成 ${result.generatedCount} 笔账单` : '当前没有到期账单');
    } catch (error) {
      ToastUtil.show('生成失败，请稍后重试');
    }
  }

  private async generateBill(item: RecurringBillModel): Promise<void> {
    if (!item.id) {
      return;
    }
    try {
      const result = await this.repository.generateOne(item.id, Date.now());
      await AppState.getInstance().refreshAll();
      await SpendingCardService.refreshAllForms(getContext(this));
      await this.loadAll();
      ToastUtil.show(result.generatedCount > 0 ? '已生成账单' : '该账单未到期或已生成');
    } catch (error) {
      ToastUtil.show('生成失败，请稍后重试');
    }
  }

  private ensureDraftDefaults(): void {
    this.ensureDraftCategory();
    if (this.draftAccountId <= 0 && this.accounts.length > 0) {
      this.draftAccountId = this.accounts[0].id || 0;
    }
  }

  private ensureDraftCategory(): void {
    const list = this.currentCategories();
    const exists = list.some((item: CategoryModel) => item.id === this.draftCategoryId);
    if (!exists && list.length > 0) {
      this.draftCategoryId = list[0].id || 0;
    }
  }

  private currentCategories(): CategoryModel[] {
    return this.draftType === RecordType.INCOME ? this.incomeCategories : this.expenseCategories;
  }

  private normalizeDay(value: string): number {
    const parsed = Number(value);
    if (this.draftFrequency === RecurringFrequency.WEEKLY) {
      return Math.max(1, Math.min(7, Number.isNaN(parsed) ? 1 : Math.round(parsed)));
    }
    return Math.max(1, Math.min(28, Number.isNaN(parsed) ? 1 : Math.round(parsed)));
  }

  private enabledCount(): number {
    return this.bills.filter((item: RecurringBillModel) => item.enabled).length;
  }

  private monthlyEstimate(): number {
    return this.bills.reduce((sum: number, item: RecurringBillModel) => {
      if (!item.enabled) {
        return sum;
      }
      const amount = item.frequency === RecurringFrequency.WEEKLY ? item.amount * 4 : item.amount;
      return item.type === RecordType.INCOME ? sum + amount : sum - amount;
    }, 0);
  }

  private summaryHint(): string {
    if (this.bills.length === 0) {
      return '添加固定账单后，可按到期日生成收入或支出。';
    }
    return '不会后台自动入账，点击生成后只生成到今天已到期的项目。';
  }

  private defaultName(): string {
    return this.draftType === RecordType.INCOME ? '固定收入' : '固定支出';
  }

  private typeText(type: RecordType.EXPENSE | RecordType.INCOME): string {
    return type === RecordType.INCOME ? '收入' : '支出';
  }

  private frequencyText(item: RecurringBillModel): string {
    if (item.frequency === RecurringFrequency.WEEKLY) {
      return `每周${this.weekdayText(item.dayOfWeek)}`;
    }
    return `每月 ${item.dayOfMonth} 日`;
  }

  private weekdayText(dayOfWeek: number): string {
    const labels: string[] = ['一', '二', '三', '四', '五', '六', '日'];
    return labels[Math.max(1, Math.min(7, dayOfWeek)) - 1];
  }

  private dueText(item: RecurringBillModel): string {
    if (!item.enabled) {
      return '已停用';
    }
    if (this.repository.generatedInCurrentPeriod(item, Date.now())) {
      return '本期已生成';
    }
    if (this.repository.isDue(item, Date.now())) {
      return '今日可生成';
    }
    return '未到期';
  }

  private dueHint(item: RecurringBillModel): string {
    if (!item.enabled) {
      return '启用后才会参与生成';
    }
    const recordTime = this.repository.nextRecordTime(item, Date.now());
    if (this.repository.generatedInCurrentPeriod(item, Date.now())) {
      return `已生成 ${DateUtil.dayLabel(recordTime)} 的账单`;
    }
    return `计划日期 ${DateUtil.dayLabel(recordTime)}`;
  }

  private dueColor(item: RecurringBillModel): string {
    if (!item.enabled) {
      return AppColors.MUTED;
    }
    if (this.repository.isDue(item, Date.now())) {
      return AppColors.CHART_GREEN;
    }
    if (this.repository.generatedInCurrentPeriod(item, Date.now())) {
      return AppColors.CHART_BLUE;
    }
    return AppColors.WARNING;
  }

  private dueBgColor(item: RecurringBillModel): string {
    if (!item.enabled) {
      return AppColors.SURFACE;
    }
    if (this.repository.isDue(item, Date.now())) {
      return AppColors.softGreen();
    }
    if (this.repository.generatedInCurrentPeriod(item, Date.now())) {
      return AppColors.SURFACE_TINT;
    }
    return AppColors.softYellow();
  }

  private isPhone(): boolean {
    return this.viewportWidth < Breakpoints.TABLET;
  }

  private contentMaxWidth(): number {
    return this.viewportWidth >= Breakpoints.DESKTOP ? LayoutSizes.CONTENT_MAX : LayoutSizes.CONTENT_COMPACT;
  }
}
