import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { fileIo, picker } from '@kit.CoreFileKit';
import { RecordListItem, RecordType } from '../model/Record';
import { RecordRepository } from '../repository/RecordRepository';
import { AppColors, AppRadius, AppSpace, LayoutSizes } from '../constants/DesignSystem';
import { DateUtil } from '../utils/DateUtil';
import { NumberUtil } from '../utils/NumberUtil';
import { ToastUtil } from '../utils/ToastUtil';
import { AppDatabase } from '../database/AppDatabase';

enum ExportScope {
  MONTH = 'month',
  RECENT = 'recent',
  CUSTOM = 'custom'
}

@Entry
@Component
struct DataExport {
  private repository: RecordRepository = new RecordRepository();

  @State exportScope: ExportScope = ExportScope.MONTH;
  @State records: RecordListItem[] = [];
  @State csvText: string = '';
  @State incomeTotal: number = 0;
  @State expenseTotal: number = 0;
  @State balanceTotal: number = 0;
  @State customStartTime: number = DateUtil.startOfMonth();
  @State customEndTime: number = DateUtil.addDays(DateUtil.startOfDay(), 1);
  @State draftCustomStartTime: number = DateUtil.startOfMonth();
  @State draftCustomEndTime: number = DateUtil.startOfDay();
  @State customEditorVisible: boolean = false;

  aboutToAppear(): void {
    this.loadRecords();
  }

  build() {
    Column() {
      this.Header()
      Scroll() {
        Column({ space: 16 }) {
          this.SummaryCard()
          this.ScopeCard()
          this.PreviewCard()
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
        Text('数据导出')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .width('100%')
        Text('保存 CSV 账单文件')
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
        Column({ space: 4 }) {
          Text(this.scopeTitle())
            .fontSize(13)
            .fontColor(AppColors.MUTED)
          Text(`${this.records.length} 条`)
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.INK)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Button('重新生成')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.CHART_BLUE)
          .height(42)
          .backgroundColor(AppColors.SURFACE_TINT)
          .borderRadius(AppRadius.PILL)
          .onClick(() => this.loadRecords())
      }
      .width('100%')
      Row({ space: 10 }) {
        this.InfoChip('收入', NumberUtil.compactMoney(this.incomeTotal), AppColors.CHART_GREEN, AppColors.softGreen())
        this.InfoChip('支出', NumberUtil.compactMoney(this.expenseTotal), AppColors.CHART_PINK, AppColors.softPink())
        this.InfoChip('结余', NumberUtil.compactMoney(this.balanceTotal), this.balanceTotal >= 0 ? AppColors.CHART_BLUE : AppColors.EXPENSE, AppColors.SURFACE_TINT)
      }
      .width('100%')

      Text(`${this.scopeHint()}。点击保存后选择文件位置，可直接使用表格应用打开。`)
        .fontSize(12)
        .fontColor(AppColors.MUTED)
        .lineHeight(20)
        .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 20, color: AppColors.SHADOW, offsetY: 8 })
  }

  @Builder
  private ScopeCard() {
    Column({ space: 12 }) {
      Text('导出范围')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.INK)
        .width('100%')

      Row({ space: 10 }) {
        this.ScopeButton('本月账单', ExportScope.MONTH)
        this.ScopeButton('最近 1000 条', ExportScope.RECENT)
        this.ScopeButton('自定义', ExportScope.CUSTOM)
      }
      .width('100%')

      if (this.customEditorVisible) {
        Column({ space: 10 }) {
          Row({ space: 8 }) {
            this.DateField('开始日期', this.draftCustomStartTime, true)
            this.DateField('结束日期', this.draftCustomEndTime, false)
          }
          .width('100%')
          Row({ space: 8 }) {
            Button('取消')
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.MUTED)
              .width(76)
              .height(38)
              .backgroundColor(AppColors.SURFACE_SOFT)
              .borderRadius(AppRadius.PILL)
              .onClick(() => {
                this.customEditorVisible = false;
              })
            Button('应用范围')
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.SURFACE)
              .layoutWeight(1)
              .height(38)
              .backgroundColor(AppColors.CHART_BLUE)
              .borderRadius(AppRadius.PILL)
              .onClick(() => this.applyCustomRange())
          }
          .width('100%')
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 20, color: AppColors.SHADOW, offsetY: 8 })
  }

  @Builder
  private ScopeButton(label: string, scope: ExportScope) {
    Text(label)
      .fontSize(14)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.exportScope === scope ? AppColors.SURFACE : AppColors.INK)
      .height(44)
      .layoutWeight(1)
      .textAlign(TextAlign.Center)
      .backgroundColor(this.exportScope === scope ? AppColors.CHART_BLUE : AppColors.SURFACE_SOFT)
      .borderRadius(AppRadius.PILL)
      .onClick(() => {
        this.exportScope = scope;
        if (scope === ExportScope.CUSTOM) {
          this.openCustomEditor();
        } else {
          this.customEditorVisible = false;
          this.loadRecords();
        }
      })
  }

  @Builder
  private DateField(label: string, timestamp: number, isStart: boolean) {
    Column({ space: 8 }) {
      Text(label)
        .fontSize(11)
        .fontColor(AppColors.MUTED)
        .width('100%')
      Row() {
        Text(this.fullDateLabel(timestamp))
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .layoutWeight(1)
          .maxLines(1)
        Text('›')
          .fontSize(20)
          .fontColor(AppColors.CHART_BLUE)
      }
      .width('100%')
      .height(26)
    }
    .layoutWeight(1)
    .height(62)
    .padding({ left: 12, right: 10, top: 8, bottom: 8 })
    .backgroundColor(AppColors.SURFACE_SOFT)
    .border({ width: 1, color: AppColors.LINE })
    .borderRadius(14)
    .onClick(() => this.showCustomDatePicker(isStart))
  }

  @Builder
  private InfoChip(label: string, value: string, color: string, bgColor: string) {
    Column({ space: 4 }) {
      Text(label)
        .fontSize(12)
        .fontColor(AppColors.MUTED)
        .maxLines(1)
      Text(value)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .textAlign(TextAlign.Center)
    }
    .layoutWeight(1)
    .height(66)
    .justifyContent(FlexAlign.Center)
    .padding(10)
    .backgroundColor(bgColor)
    .borderRadius(16)
  }

  @Builder
  private PreviewCard() {
    Column({ space: 12 }) {
      Row() {
        Text('CSV 预览')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
        Blank()
        Text(`${this.csvText.length} 字符`)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.LEDGER)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor(AppColors.SURFACE_TINT)
          .borderRadius(AppRadius.PILL)
      }
      .width('100%')

      Text(this.previewText())
        .fontSize(12)
        .fontColor(AppColors.MUTED)
        .lineHeight(19)
        .width('100%')
        .padding(14)
        .backgroundColor(AppColors.SURFACE_SOFT)
        .borderRadius(18)

      Button('保存 CSV 文件')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.SURFACE)
        .height(48)
        .width('100%')
        .backgroundColor(AppColors.CHART_BLUE)
        .borderRadius(AppRadius.PILL)
        .onClick(() => this.saveCsv())
    }
    .width('100%')
    .padding(16)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 20, color: AppColors.SHADOW, offsetY: 8 })
  }

  private async loadRecords(): Promise<void> {
    try {
      await AppDatabase.getInstance().init(getContext(this));
      this.records = await this.loadScopedRecords();
      this.csvText = this.buildCsv(this.records);
      this.refreshTotals();
    } catch (error) {
      ToastUtil.show('账单数据加载失败，请重试');
    }
  }

  private async saveCsv(): Promise<void> {
    try {
      await AppDatabase.getInstance().init(getContext(this));
      this.records = await this.loadScopedRecords();
      this.csvText = this.buildCsv(this.records);
      this.refreshTotals();
      const context = getContext(this) as common.UIAbilityContext;
      const options = new picker.DocumentSaveOptions();
      options.newFileNames = [`一页账-${this.fileNameSuffix()}.csv`];
      options.fileSuffixChoices = ['CSV 文件|.csv'];
      const uris = await new picker.DocumentViewPicker(context).save(options);
      if (uris.length === 0) {
        ToastUtil.show('未保存 CSV 文件');
        return;
      }
      const file = fileIo.openSync(uris[0], fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);
      try {
        fileIo.writeSync(file.fd, `\uFEFF${this.csvText}`);
      } finally {
        fileIo.closeSync(file);
      }
      ToastUtil.show(`CSV 已保存：${uris[0]}`);
    } catch (error) {
      ToastUtil.show(`CSV 未保存：${ToastUtil.error(error)}`);
    }
  }

  private async loadScopedRecords(): Promise<RecordListItem[]> {
    if (this.exportScope === ExportScope.MONTH) {
      return await this.repository.listByRange(DateUtil.startOfMonth(), DateUtil.startOfNextMonth(), 1000, 0);
    }
    if (this.exportScope === ExportScope.CUSTOM) {
      return await this.repository.listByRange(this.customStartTime, this.customEndTime, 1000, 0);
    }
    return await this.repository.listRecent(1000, 0);
  }

  private refreshTotals(): void {
    this.incomeTotal = this.records.reduce((total: number, item: RecordListItem) => {
      return item.type === RecordType.INCOME ? total + item.amount : total;
    }, 0);
    this.expenseTotal = this.records.reduce((total: number, item: RecordListItem) => {
      return item.type === RecordType.EXPENSE ? total + item.amount : total;
    }, 0);
    this.balanceTotal = this.incomeTotal - this.expenseTotal;
  }

  private buildCsv(records: RecordListItem[]): string {
    const rows: string[] = ['日期,类型,分类,金额,账户,备注'];
    records.forEach((item: RecordListItem) => {
      rows.push([
        DateUtil.dayLabel(item.recordTime) + ' ' + DateUtil.timeLabel(item.recordTime),
        this.typeLabel(item.type),
        item.categoryName,
        `${item.type === RecordType.EXPENSE ? '-' : ''}${NumberUtil.plainMoney(item.amount)}`,
        item.accountName,
        item.remark
      ].map((value: string) => this.escapeCsv(value)).join(','));
    });
    return rows.join('\n');
  }

  private escapeCsv(value: string): string {
    const safeValue = value.replace(/"/g, '""');
    if (safeValue.indexOf(',') >= 0 || safeValue.indexOf('\n') >= 0 || safeValue.indexOf('"') >= 0) {
      return `"${safeValue}"`;
    }
    return safeValue;
  }

  private previewText(): string {
    if (this.csvText.length === 0) {
      return '暂无内容';
    }
    if (this.csvText.length <= 1200) {
      return this.csvText;
    }
    return this.csvText.substring(0, 1200) + '\n...';
  }

  private scopeTitle(): string {
    if (this.exportScope === ExportScope.MONTH) {
      return '本月可导出账单';
    }
    if (this.exportScope === ExportScope.CUSTOM) {
      return '自定义范围账单';
    }
    return '可导出账单';
  }

  private scopeHint(): string {
    if (this.exportScope === ExportScope.MONTH) {
      return '当前导出本月流水，最多 1000 条';
    }
    if (this.exportScope === ExportScope.CUSTOM) {
      return `当前导出 ${DateUtil.rangeLabel(this.customStartTime, this.customEndTime)} 流水，最多 1000 条`;
    }
    return '当前导出最近 1000 条流水';
  }

  private fileNameSuffix(): string {
    if (this.exportScope === ExportScope.MONTH) {
      return DateUtil.monthKey(Date.now());
    }
    if (this.exportScope === ExportScope.CUSTOM) {
      return `${DateUtil.dayKey(this.customStartTime)}-${DateUtil.dayKey(this.customEndTime - 1)}`;
    }
    return DateUtil.dayKey(Date.now());
  }

  private openCustomEditor(): void {
    this.exportScope = ExportScope.CUSTOM;
    this.draftCustomStartTime = this.customStartTime;
    this.draftCustomEndTime = this.customEndTime - 1;
    this.customEditorVisible = true;
    this.loadRecords();
  }

  private showCustomDatePicker(isStart: boolean): void {
    const current = new Date(isStart ? this.draftCustomStartTime : this.draftCustomEndTime);
    DatePickerDialog.show({
      selected: current,
      start: new Date(2000, 0, 1),
      end: new Date(2100, 11, 31),
      onAccept: (value: DatePickerResult) => {
        const timestamp = new Date(
          value.year ?? current.getFullYear(),
          value.month ?? current.getMonth(),
          value.day ?? current.getDate()
        ).getTime();
        if (isStart) {
          this.draftCustomStartTime = timestamp;
          if (timestamp > this.draftCustomEndTime) {
            this.draftCustomEndTime = timestamp;
          }
        } else {
          this.draftCustomEndTime = timestamp;
          if (timestamp < this.draftCustomStartTime) {
            this.draftCustomStartTime = timestamp;
          }
        }
      }
    });
  }

  private async applyCustomRange(): Promise<void> {
    this.customStartTime = DateUtil.startOfDay(this.draftCustomStartTime);
    this.customEndTime = DateUtil.addDays(DateUtil.startOfDay(this.draftCustomEndTime), 1);
    this.customEditorVisible = false;
    await this.loadRecords();
  }

  private fullDateLabel(timestamp: number): string {
    const date = new Date(timestamp);
    const month = `${date.getMonth() + 1}`.padStart(2, '0');
    const day = `${date.getDate()}`.padStart(2, '0');
    return `${date.getFullYear()}/${month}/${day}`;
  }

  private typeLabel(type: RecordType): string {
    if (type === RecordType.INCOME) {
      return '收入';
    }
    if (type === RecordType.TRANSFER) {
      return '转账';
    }
    return '支出';
  }
}
