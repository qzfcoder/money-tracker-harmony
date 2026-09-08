import { router } from '@kit.ArkUI';
import { RecordListItem, RecordModel, RecordType } from '../model/Record';
import { RecordRepository } from '../repository/RecordRepository';
import { CategoryRepository } from '../repository/CategoryRepository';
import { AccountRepository } from '../repository/AccountRepository';
import { SalaryInsight, SalarySettingsData } from '../model/Salary';
import { SalaryRepository } from '../repository/SalaryRepository';
import { SalaryInsightService } from '../service/SalaryInsightService';
import { AppState } from '../viewmodel/AppState';
import { AppColors, AppRadius, AppSpace, LayoutSizes } from '../constants/DesignSystem';
import { DateUtil } from '../utils/DateUtil';
import { NumberUtil } from '../utils/NumberUtil';
import { ToastUtil } from '../utils/ToastUtil';
import { ROUTES } from '../constants/RouteConstants';
import { AppDatabase } from '../database/AppDatabase';
import { SpendingCardService } from '../widget/SpendingCardService';

interface DetailParams {
  recordId?: number;
}

@Entry
@Component
struct RecordDetail {
  private recordRepository: RecordRepository = new RecordRepository();
  private categoryRepository: CategoryRepository = new CategoryRepository();
  private accountRepository: AccountRepository = new AccountRepository();
  private salaryRepository: SalaryRepository = new SalaryRepository();

  @State record: RecordModel | null = null;
  @State categoryName: string = '';
  @State accountName: string = '';
  @State transferAccountName: string = '';
  @State appState: AppState = AppState.getInstance();
  @State salarySettings: SalarySettingsData = new SalaryRepository().defaultSettings();
  @State salaryInsight: SalaryInsight = new SalaryInsight();
  private recordId: number = 0;

  aboutToAppear(): void {
    this.captureRecordId();
  }

  onPageShow(): void {
    this.captureRecordId();
    this.applyCachedRecord();
    this.loadRecord();
  }

  build() {
    Column() {
      this.Header()
      Scroll() {
        Column({ space: 16 }) {
          if (this.record) {
            this.AmountCard()
            this.WorkTimeCard()
            this.InfoCard()
            this.ActionCard()
          } else {
            this.EmptyState()
          }
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
        Text('账单详情')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .width('100%')
        Text('查看并修改记录')
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
  private AmountCard() {
    Column({ space: 12 }) {
      Text(this.typeLabel())
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.recordType() === RecordType.EXPENSE ? AppColors.EXPENSE :
          this.recordType() === RecordType.TRANSFER ? AppColors.CHART_BLUE : AppColors.INCOME)
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .backgroundColor(this.recordType() === RecordType.EXPENSE ? AppColors.softDanger() :
          this.recordType() === RecordType.TRANSFER ? AppColors.SURFACE_TINT : AppColors.softGreen())
        .borderRadius(AppRadius.PILL)
      Text(`${this.recordType() === RecordType.EXPENSE ? '-' : this.recordType() === RecordType.INCOME ? '+' : ''}${NumberUtil.money(this.recordAmount())}`)
        .fontSize(42)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.INK)
        .width('100%')
        .textAlign(TextAlign.Center)
      Text(DateUtil.dayLabel(this.recordTime()) + ' ' + DateUtil.timeLabel(this.recordTime()))
        .fontSize(13)
        .fontColor(AppColors.MUTED)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .padding(18)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 22, color: AppColors.SHADOW, offsetY: 8 })
  }

  @Builder
  private InfoCard() {
    Column({ space: 12 }) {
      if (this.recordType() === RecordType.TRANSFER) {
        this.InfoRow('转出账户', this.displayAccountName())
        this.InfoRow('转入账户', this.displayTransferAccountName())
      } else {
        this.InfoRow('分类', this.displayCategoryName())
        this.InfoRow('账户', this.displayAccountName())
      }
      this.InfoRow('备注', this.recordRemark() || '无')
      this.InfoRow('创建时间', DateUtil.dayLabel(this.createTime()) + ' ' + DateUtil.timeLabel(this.createTime()))
    }
    .width('100%')
    .padding(16)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 18, color: AppColors.SHADOW, offsetY: 8 })
  }

  @Builder
  private WorkTimeCard() {
    if (this.recordType() === RecordType.EXPENSE && this.salarySettings.enabled && this.salaryInsight.hourlyIncome > 0) {
      Row({ space: 12 }) {
        Text('时')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.CHART_PURPLE)
          .width(42)
          .height(42)
          .textAlign(TextAlign.Center)
          .borderRadius(15)
          .backgroundColor(AppColors.softPurple())
        Column({ space: 4 }) {
          Text('工作时间折算')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.INK)
            .width('100%')
          Text(`这笔支出约等于 ${SalaryInsightService.workTimeText(this.recordAmount(), this.salaryInsight.hourlyIncome)} 工作收入`)
            .fontSize(13)
            .fontColor(AppColors.MUTED)
            .width('100%')
            .maxLines(2)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Text('调整')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.CHART_PURPLE)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor(AppColors.softPurple())
          .borderRadius(AppRadius.PILL)
          .onClick(() => router.pushUrl({ url: ROUTES.SALARY_MANAGE }))
      }
      .width('100%')
      .padding(16)
      .backgroundColor(AppColors.SURFACE)
      .borderRadius(AppRadius.CARD)
      .shadow({ radius: 18, color: AppColors.SHADOW, offsetY: 8 })
    }
  }

  @Builder
  private InfoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(13)
        .fontColor(AppColors.MUTED)
      Blank()
      Text(value)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.INK)
        .maxLines(2)
    }
    .width('100%')
  }

  @Builder
  private ActionCard() {
    Column({ space: 10 }) {
      Button('编辑账单')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.SURFACE)
        .height(52)
        .width('100%')
        .backgroundColor(AppColors.CHART_BLUE)
        .borderRadius(AppRadius.PILL)
        .onClick(() => this.editRecord())

      Row({ space: 10 }) {
        Button('删除账单')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.EXPENSE)
          .height(50)
          .layoutWeight(1)
          .backgroundColor(AppColors.softDanger())
          .borderRadius(AppRadius.PILL)
          .onClick(() => this.removeRecord())
        Button('返回')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.CHART_BLUE)
          .height(50)
          .layoutWeight(1)
          .backgroundColor(AppColors.SURFACE_TINT)
          .borderRadius(AppRadius.PILL)
          .onClick(() => router.back())
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  private EmptyState() {
    Column({ space: 8 }) {
      Text('未找到账单')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.INK)
      Text('可能已经被删除')
        .fontSize(13)
        .fontColor(AppColors.MUTED)
    }
    .width('100%')
    .height(132)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
  }

  private async loadRecord(): Promise<void> {
    if (this.recordId <= 0) {
      return;
    }
    try {
      await AppDatabase.getInstance().init(getContext(this));
      const latestRecord = await this.recordRepository.findById(this.recordId);
      if (!latestRecord) {
        this.record = null;
        return;
      }
      const category = await this.categoryRepository.findById(latestRecord.categoryId);
      const account = await this.accountRepository.findById(latestRecord.accountId);
      const salarySettings = await this.salaryRepository.load(getContext(this));
      const monthSummary = await this.recordRepository.monthSummary(DateUtil.startOfMonth(latestRecord.recordTime), DateUtil.startOfNextMonth(latestRecord.recordTime));
      this.record = latestRecord;
      this.categoryName = category ? category.name : '';
      this.accountName = account ? account.name : '';
      this.salarySettings = salarySettings;
      this.salaryInsight = SalaryInsightService.build(salarySettings, monthSummary.expense, latestRecord.recordTime);
      this.transferAccountName = latestRecord.transferAccountId
        ? (await this.accountRepository.findById(latestRecord.transferAccountId))?.name || ''
        : '';
    } catch (error) {
      ToastUtil.show('账单加载失败，请重试');
    }
  }

  private async removeRecord(): Promise<void> {
    const record = this.displayRecord();
    if (!record || !record.id) {
      return;
    }
    try {
      await AppDatabase.getInstance().init(getContext(this));
      await this.recordRepository.deleteById(record.id);
      await AppState.getInstance().refreshAll();
      await this.refreshSpendingCard();
      ToastUtil.show('账单已删除');
      router.back();
    } catch (error) {
      ToastUtil.show('删除失败，请重试');
    }
  }

  private editRecord(): void {
    const record = this.displayRecord();
    if (!record || !record.id) {
      return;
    }
    router.pushUrl({ url: ROUTES.RECORD_EDIT, params: { recordId: record.id } });
  }

  private async refreshSpendingCard(): Promise<void> {
    try {
      await SpendingCardService.refreshKnownForms(getContext(this));
    } catch (error) {
      // Card refresh is best-effort; the system scheduled update will retry later.
    }
  }

  private recordType(): RecordType {
    const record = this.displayRecord();
    return record ? record.type : RecordType.EXPENSE;
  }

  private recordAmount(): number {
    const record = this.displayRecord();
    return record ? record.amount : 0;
  }

  private recordTime(): number {
    const record = this.displayRecord();
    return record ? record.recordTime : Date.now();
  }

  private recordRemark(): string {
    const record = this.displayRecord();
    return record ? record.remark : '';
  }

  private createTime(): number {
    const record = this.displayRecord();
    return record ? record.createTime : Date.now();
  }

  private captureRecordId(): void {
    if (this.recordId > 0) {
      return;
    }
    const params = router.getParams() as DetailParams;
    this.recordId = Number(params?.recordId || 0);
  }

  private applyCachedRecord(): void {
    const cached = this.cachedRecord();
    if (!cached) {
      return;
    }
    this.record = cached;
    this.categoryName = cached.categoryName;
    this.accountName = cached.accountName;
    this.transferAccountName = cached.transferAccountName || '';
  }

  private cachedRecord(): RecordListItem | null {
    if (this.appState.lastUpdatedRecord && this.appState.lastUpdatedRecord.id === this.recordId) {
      return this.appState.lastUpdatedRecord;
    }
    return this.appState.recordList.find((item: RecordListItem) => item.id === this.recordId) || null;
  }

  private displayRecord(): RecordModel | null {
    return this.cachedRecord() || this.record;
  }

  private displayCategoryName(): string {
    const cached = this.cachedRecord();
    return cached ? cached.categoryName : this.categoryName || '未命名';
  }

  private displayAccountName(): string {
    const cached = this.cachedRecord();
    return cached ? cached.accountName : this.accountName || '默认账户';
  }

  private displayTransferAccountName(): string {
    const cached = this.cachedRecord();
    return cached ? cached.transferAccountName || '未设置账户' : this.transferAccountName || '未设置账户';
  }

  private typeLabel(): string {
    if (this.recordType() === RecordType.INCOME) {
      return '收入';
    }
    if (this.recordType() === RecordType.TRANSFER) {
      return '转账';
    }
    return '支出';
  }
}
