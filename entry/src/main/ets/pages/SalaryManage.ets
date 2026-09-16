import { router } from '@kit.ArkUI';
import { AppColors, AppRadius, AppSpace, Breakpoints, LayoutSizes } from '../constants/DesignSystem';
import { SalaryInsight, SalaryMode, SalarySettingsData } from '../model/Salary';
import { RecordRepository } from '../repository/RecordRepository';
import { SalaryRepository } from '../repository/SalaryRepository';
import { SalaryInsightService } from '../service/SalaryInsightService';
import { AppDatabase } from '../database/AppDatabase';
import { DateUtil } from '../utils/DateUtil';
import { NumberUtil } from '../utils/NumberUtil';
import { ToastUtil } from '../utils/ToastUtil';

@Entry
@Component
struct SalaryManage {
  private salaryRepository: SalaryRepository = new SalaryRepository();
  private recordRepository: RecordRepository = new RecordRepository();

  @State viewportWidth: number = 0;
  @State salaryEnabled: boolean = false;
  @State salaryMode: SalaryMode = SalaryMode.MONTHLY;
  @State baseAmountText: string = '';
  @State paydayText: string = '10';
  @State workDaysText: string = '5';
  @State dailyHoursText: string = '8';
  @State bonusText: string = '';
  @State allowanceText: string = '';
  @State deductionText: string = '';
  @State monthExpense: number = 0;
  @State insight: SalaryInsight = new SalaryInsight();
  @StorageLink('ledgerIsDarkMode') isDarkMode: boolean = false;

  aboutToAppear(): void {
    this.loadData();
  }

  onPageShow(): void {
    this.loadData();
  }

  build() {
    Column() {
      this.Header()

      Scroll() {
        Column({ space: 16 }) {
          this.OverviewCard()
          this.ModeCard()
          this.WorkCard()
          this.ExtraCard()
          this.SaveCard()
        }
        .width('100%')
        .constraintSize({ maxWidth: this.contentMaxWidth() })
        .alignSelf(ItemAlign.Center)
        .padding({ left: AppSpace.PAGE, right: AppSpace.PAGE, top: 8, bottom: 24 })
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
        Text('工资管理')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .width('100%')
        Text('收入节奏、发薪日和消费换算')
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
  private OverviewCard() {
    Column({ space: this.isPhone() ? 12 : 16 }) {
      Row() {
        Row({ space: 12 }) {
          Text('薪')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.CHART_PURPLE)
            .width(46)
            .height(46)
            .textAlign(TextAlign.Center)
            .borderRadius(16)
            .backgroundColor(AppColors.softPurple())
          Column({ space: 3 }) {
            Text(this.salaryEnabled ? '本月工资进度' : '开启工资看板')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.INK)
              .width('100%')
            Text(this.salaryEnabled ? `发薪日 ${this.paydayValue()} 号 · ${SalaryInsightService.paydayStatusText(this.insight.paydayCountdown)}` : '设置收入后，账单会自动折算成工作时间')
              .fontSize(13)
              .fontColor(AppColors.MUTED)
              .width('100%')
              .maxLines(2)
            Text(this.salaryEnabled ? `本月进度 ${this.insight.monthProgress}%` : '补充工资后可查看进度与折算内容')
              .fontSize(12)
              .fontColor(AppColors.MUTED)
              .width('100%')
              .maxLines(1)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .layoutWeight(1)
        Text(this.salaryEnabled ? (this.insight.monthlyIncome > 0 ? '已开启' : '待配置') : '未开启')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.salaryEnabled ? AppColors.CHART_GREEN : AppColors.WARNING)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor(this.salaryEnabled ? AppColors.softGreen() : AppColors.softYellow())
          .borderRadius(AppRadius.PILL)
      }
      .width('100%')

      Row({ space: 10 }) {
        this.MetricChip('预计到手', () => NumberUtil.compactMoney(this.insight.monthlyIncome), AppColors.CHART_BLUE, this.metricBg(2))
        this.MetricChip('本月已赚', () => NumberUtil.compactMoney(this.insight.earnedToDate), AppColors.CHART_GREEN, this.metricBg(0))
        this.MetricChip('花费占比', () => `${this.insight.expenseRate}%`, this.pressureColor(), this.metricBg(1))
      }
      .width('100%')

      Stack({ alignContent: Alignment.Start }) {
        Column()
          .height(10)
          .width('100%')
          .backgroundColor(AppColors.TRACK)
          .borderRadius(5)
        Column()
          .height(10)
          .width(`${this.insight.monthProgress}%`)
          .backgroundColor(AppColors.CHART_PURPLE)
          .borderRadius(5)
      }
      .width('100%')
      .height(10)

      if (this.salaryEnabled && this.insight.monthlyIncome <= 0) {
        Text('工资已开启，但当前未算出有效工资值，请补充月薪/日薪/时薪与工作日参数。')
          .fontSize(12)
          .fontColor(AppColors.WARNING)
          .lineHeight(18)
          .width('100%')
          .maxLines(2)
      }

      Text(this.salaryAdvice())
        .fontSize(13)
        .fontColor(AppColors.MUTED)
        .lineHeight(20)
        .width('100%')
        .maxLines(2)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 22, color: AppColors.SHADOW, offsetY: 9 })
  }

  @Builder
  private ModeCard() {
    Column({ space: 14 }) {
      this.CardTitle('工资方式', () => this.modeLabel())
      Row({ space: 8 }) {
        this.ModeButton('月薪', SalaryMode.MONTHLY)
        this.ModeButton('日薪', SalaryMode.DAILY)
        this.ModeButton('时薪', SalaryMode.HOURLY)
      }
      .height(48)
      .padding(4)
      .backgroundColor(AppColors.TRACK)
      .borderRadius(AppRadius.PILL)

      this.BaseAmountInput()
    }
    .width('100%')
    .padding(16)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 20, color: AppColors.SHADOW, offsetY: 8 })
  }

  @Builder
  private WorkCard() {
    Column({ space: 14 }) {
      this.CardTitle('工作节奏', () => `发薪日 ${this.paydayValue()} 号`)
      Row({ space: 10 }) {
        this.PaydayInput()
        this.WorkDaysInput()
        this.DailyHoursInput()
      }
      .width('100%')

      Row({ space: 10 }) {
        this.MetricChip('自然日均', () => NumberUtil.compactMoney(this.insight.naturalDailyIncome), AppColors.CHART_BLUE, this.metricBg(2))
        this.MetricChip('工作日均', () => NumberUtil.compactMoney(this.insight.workDailyIncome), AppColors.CHART_CYAN, this.metricBg(3))
        this.MetricChip('小时工资', () => NumberUtil.compactMoney(this.insight.hourlyIncome), AppColors.CHART_PURPLE, this.metricBg(4))
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
  private ExtraCard() {
    Column({ space: 14 }) {
      this.CardTitle('本月调整', () => '可选')
      Row({ space: 10 }) {
        this.BonusInput()
        this.AllowanceInput()
        this.DeductionInput()
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
  private SaveCard() {
    Row({ space: 10 }) {
      Button(this.salaryEnabled ? '关闭工资看板' : '开启工资看板')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.salaryEnabled ? AppColors.WARNING : AppColors.CHART_BLUE)
        .height(50)
        .layoutWeight(1)
        .backgroundColor(this.salaryEnabled ? AppColors.softYellow() : AppColors.SURFACE_TINT)
        .borderRadius(AppRadius.PILL)
        .onClick(() => {
          this.salaryEnabled = !this.salaryEnabled;
          this.recalculate();
        })
      Button('保存')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.SURFACE)
        .height(50)
        .layoutWeight(1)
        .backgroundColor(AppColors.CHART_BLUE)
        .borderRadius(AppRadius.PILL)
        .onClick(() => this.save())
    }
    .width('100%')
  }

  @Builder
  private CardTitle(title: string, badge: () => string) {
    Row() {
      Text(title)
        .fontSize(19)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.INK)
        .maxLines(1)
      Blank()
      Text(badge())
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.LEDGER)
        .padding({ left: 12, right: 12, top: 5, bottom: 5 })
        .backgroundColor(AppColors.SURFACE_TINT)
        .borderRadius(AppRadius.PILL)
        .maxLines(1)
    }
    .width('100%')
  }

  @Builder
  private ModeButton(label: string, mode: SalaryMode) {
    Text(label)
      .fontSize(14)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.salaryMode === mode ? AppColors.INK : AppColors.MUTED)
      .height(40)
      .layoutWeight(1)
      .textAlign(TextAlign.Center)
      .backgroundColor(this.salaryMode === mode ? AppColors.SURFACE : '#00000000')
      .borderRadius(AppRadius.PILL)
      .onClick(() => {
        this.salaryMode = mode;
        this.recalculate();
      })
  }

  @Builder
  private BaseAmountInput() {
    Column({ space: 6 }) {
      Text(this.baseAmountLabel())
        .fontSize(12)
        .fontColor(AppColors.MUTED)
        .width('100%')
      TextInput({ text: this.baseAmountText, placeholder: '0.00' })
        .type(InputType.NUMBER_DECIMAL)
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.INK)
        .height(54)
        .backgroundColor(AppColors.SURFACE_SOFT)
        .borderRadius(16)
        .padding({ left: 14, right: 14 })
        .onChange((value: string) => {
          this.baseAmountText = this.normalizeAmount(value);
          this.recalculate();
        })
    }
    .width('100%')
  }

  @Builder
  private PaydayInput() {
    Column({ space: 5 }) {
      Text('发薪日')
        .fontSize(11)
        .fontColor(AppColors.MUTED)
        .maxLines(1)
      TextInput({ text: this.paydayText, placeholder: '10' })
        .type(InputType.NUMBER_DECIMAL)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.INK)
        .textAlign(TextAlign.Center)
        .height(44)
        .backgroundColor(AppColors.SURFACE_SOFT)
        .borderRadius(15)
        .padding({ left: 8, right: 8 })
        .onChange((value: string) => {
          this.paydayText = this.normalizeInteger(value, 2);
          this.recalculate();
        })
    }
    .layoutWeight(1)
  }

  @Builder
  private WorkDaysInput() {
    Column({ space: 5 }) {
      Text('每周工作')
        .fontSize(11)
        .fontColor(AppColors.MUTED)
        .maxLines(1)
      TextInput({ text: this.workDaysText, placeholder: '5' })
        .type(InputType.NUMBER_DECIMAL)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.INK)
        .textAlign(TextAlign.Center)
        .height(44)
        .backgroundColor(AppColors.SURFACE_SOFT)
        .borderRadius(15)
        .padding({ left: 8, right: 8 })
        .onChange((value: string) => {
          this.workDaysText = this.normalizeInteger(value, 1);
          this.recalculate();
        })
    }
    .layoutWeight(1)
  }

  @Builder
  private DailyHoursInput() {
    Column({ space: 5 }) {
      Text('每日小时')
        .fontSize(11)
        .fontColor(AppColors.MUTED)
        .maxLines(1)
      TextInput({ text: this.dailyHoursText, placeholder: '8' })
        .type(InputType.NUMBER_DECIMAL)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.INK)
        .textAlign(TextAlign.Center)
        .height(44)
        .backgroundColor(AppColors.SURFACE_SOFT)
        .borderRadius(15)
        .padding({ left: 8, right: 8 })
        .onChange((value: string) => {
          this.dailyHoursText = this.normalizeAmount(value);
          this.recalculate();
        })
    }
    .layoutWeight(1)
  }

  @Builder
  private BonusInput() {
    Column({ space: 5 }) {
      Text('奖金')
        .fontSize(11)
        .fontColor(AppColors.MUTED)
        .maxLines(1)
      TextInput({ text: this.bonusText, placeholder: '0' })
        .type(InputType.NUMBER_DECIMAL)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.INK)
        .textAlign(TextAlign.Center)
        .height(44)
        .backgroundColor(AppColors.SURFACE_SOFT)
        .borderRadius(15)
        .padding({ left: 8, right: 8 })
        .onChange((value: string) => {
          this.bonusText = this.normalizeAmount(value);
          this.recalculate();
        })
    }
    .layoutWeight(1)
  }

  @Builder
  private AllowanceInput() {
    Column({ space: 5 }) {
      Text('补贴')
        .fontSize(11)
        .fontColor(AppColors.MUTED)
        .maxLines(1)
      TextInput({ text: this.allowanceText, placeholder: '0' })
        .type(InputType.NUMBER_DECIMAL)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.INK)
        .textAlign(TextAlign.Center)
        .height(44)
        .backgroundColor(AppColors.SURFACE_SOFT)
        .borderRadius(15)
        .padding({ left: 8, right: 8 })
        .onChange((value: string) => {
          this.allowanceText = this.normalizeAmount(value);
          this.recalculate();
        })
    }
    .layoutWeight(1)
  }

  @Builder
  private DeductionInput() {
    Column({ space: 5 }) {
      Text('扣款')
        .fontSize(11)
        .fontColor(AppColors.MUTED)
        .maxLines(1)
      TextInput({ text: this.deductionText, placeholder: '0' })
        .type(InputType.NUMBER_DECIMAL)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.INK)
        .textAlign(TextAlign.Center)
        .height(44)
        .backgroundColor(AppColors.SURFACE_SOFT)
        .borderRadius(15)
        .padding({ left: 8, right: 8 })
        .onChange((value: string) => {
          this.deductionText = this.normalizeAmount(value);
          this.recalculate();
        })
    }
    .layoutWeight(1)
  }

  @Builder
  private MetricChip(label: string, value: () => string, color: string, bgColor: string) {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        Column()
          .width('100%')
          .height(4)
          .backgroundColor(color)
          .borderRadius(2)
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8 })

      Column({ space: 4 }) {
        Text(label)
          .fontSize(11)
          .fontColor(AppColors.MUTED)
          .maxLines(1)
        Text(value())
          .fontSize(this.metricFontSize(value()))
          .fontWeight(FontWeight.Bold)
          .fontColor(color)
          .width('100%')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .padding({ left: 8, right: 8, top: 10 })
    }
    .layoutWeight(1)
    .height(66)
    .backgroundColor(bgColor)
    .borderRadius(16)
    .border({ width: 1, color: AppColors.LINE })
  }

  private async loadData(): Promise<void> {
    try {
      await AppDatabase.getInstance().init(getContext(this));
      const settings = await this.salaryRepository.load(getContext(this));
      this.applySettings(settings);
      const monthSummary = await this.recordRepository.monthSummary(DateUtil.startOfMonth(), DateUtil.startOfNextMonth());
      this.monthExpense = monthSummary.expense;
      this.recalculate();
    } catch (error) {
      ToastUtil.show('工资数据加载失败');
    }
  }

  private async save(): Promise<void> {
    try {
      await this.salaryRepository.save(getContext(this), this.currentSettings());
      const savedSettings = await this.salaryRepository.load(getContext(this));
      this.applySettings(savedSettings);
      this.recalculate();
      ToastUtil.show('工资设置已保存');
    } catch (error) {
      ToastUtil.show(ToastUtil.error(error, '工资设置保存失败'));
    }
  }

  private applySettings(settings: SalarySettingsData): void {
    this.salaryEnabled = settings.enabled;
    this.salaryMode = settings.salaryMode;
    this.baseAmountText = this.formatInput(settings.baseAmount);
    this.paydayText = `${settings.payday}`;
    this.workDaysText = `${settings.workDaysPerWeek}`;
    this.dailyHoursText = this.formatInput(settings.dailyHours);
    this.bonusText = this.formatInput(settings.bonusAmount);
    this.allowanceText = this.formatInput(settings.allowanceAmount);
    this.deductionText = this.formatInput(settings.deductionAmount);
  }

  private currentSettings(): SalarySettingsData {
    return {
      enabled: this.salaryEnabled,
      salaryMode: this.salaryMode,
      baseAmount: NumberUtil.toCentSafe(this.baseAmountText),
      payday: this.paydayValue(),
      workDaysPerWeek: this.workDaysValue(),
      dailyHours: Math.max(1, NumberUtil.toCentSafe(this.dailyHoursText)),
      bonusAmount: NumberUtil.toCentSafe(this.bonusText),
      allowanceAmount: NumberUtil.toCentSafe(this.allowanceText),
      deductionAmount: NumberUtil.toCentSafe(this.deductionText)
    };
  }

  private recalculate(): void {
    this.insight = SalaryInsightService.build(this.currentSettings(), this.monthExpense);
  }

  private salaryAdvice(): string {
    if (!this.salaryEnabled || this.insight.monthlyIncome <= 0) {
      return '填写工资后，首页和账单详情会显示收入进度与工作时间折算。';
    }
    const pressure = SalaryInsightService.pressureLabel(this.insight.expenseRate);
    return `本月进度 ${this.insight.monthProgress}% · 已花 ${NumberUtil.compactMoney(this.monthExpense)}，约占已赚工资 ${this.insight.expenseRate}%，当前状态：${pressure}。`;
  }

  private modeLabel(): string {
    if (this.salaryMode === SalaryMode.DAILY) {
      return '按日薪';
    }
    if (this.salaryMode === SalaryMode.HOURLY) {
      return '按时薪';
    }
    return '按月薪';
  }

  private baseAmountLabel(): string {
    if (this.salaryMode === SalaryMode.DAILY) {
      return '日薪金额';
    }
    if (this.salaryMode === SalaryMode.HOURLY) {
      return '时薪金额';
    }
    return '月到手工资';
  }

  private pressureColor(): string {
    if (this.insight.expenseRate <= 50) {
      return AppColors.CHART_GREEN;
    }
    if (this.insight.expenseRate <= 80) {
      return AppColors.CHART_BLUE;
    }
    if (this.insight.expenseRate <= 100) {
      return AppColors.WARNING;
    }
    return AppColors.EXPENSE;
  }

  private pressureBgColor(): string {
    if (this.insight.expenseRate <= 50) {
      return AppColors.softGreen();
    }
    if (this.insight.expenseRate <= 80) {
      return AppColors.softBlue();
    }
    if (this.insight.expenseRate <= 100) {
      return AppColors.softYellow();
    }
    return AppColors.softPink();
  }

  private paydayValue(): number {
    return SalaryInsightService.normalizePayday(Number(this.paydayText || '10'));
  }

  private workDaysValue(): number {
    return Math.max(1, Math.min(7, Math.round(Number(this.workDaysText || '5'))));
  }

  private normalizeAmount(value: string): string {
    return NumberUtil.normalizeAmountInput(value);
  }

  private normalizeInteger(value: string, maxLength: number): string {
    return value.replace(/[^0-9]/g, '').substring(0, maxLength);
  }

  private formatInput(value: number): string {
    return value > 0 ? `${value}` : '';
  }

  private metricFontSize(value: string): number {
    if (value.length <= 8) {
      return 16;
    }
    if (value.length <= 10) {
      return 14;
    }
    return 12;
  }

  private metricBg(index: number): string {
    const light: string[] = ['#F2FBF7', '#FFF4F7', '#F3F8FF', '#F0FBFA', '#F6F3FF'];
    const dark: string[] = ['#172B25', '#321F29', '#1B2A40', '#173032', '#272343'];
    const palette = AppColors.IS_DARK ? dark : light;
    return palette[index % palette.length];
  }

  private isPhone(): boolean {
    return this.viewportWidth < Breakpoints.TABLET;
  }

  private contentMaxWidth(): number {
    return this.viewportWidth >= Breakpoints.DESKTOP ? LayoutSizes.CONTENT_MAX : LayoutSizes.CONTENT_COMPACT;
  }
}
