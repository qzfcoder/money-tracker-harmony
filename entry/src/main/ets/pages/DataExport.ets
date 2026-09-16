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
import { AppState } from '../viewmodel/AppState';
import { DataBackupService } from '../service/DataBackupService';
import { LedgerCsvImportService } from '../service/LedgerCsvImportService';
import { SpendingCardService } from '../widget/SpendingCardService';

enum ExportScope {
  MONTH = 'month',
  RECENT = 'recent',
  CUSTOM = 'custom'
}

interface DatePickerResult {
  year?: number;
  month?: number;
  day?: number;
}

interface XlsxZipEntry {
  name: string;
  content: string;
}

interface XlsxZipInfo {
  name: string;
  crc: number;
  size: number;
  offset: number;
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
  @State restoreConfirming: boolean = false;

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
          this.DataToolsCard()
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
        Text('导出、导入与备份账单数据')
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

      Row({ space: 10 }) {
        Button('保存 CSV')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.CHART_BLUE)
          .height(48)
          .layoutWeight(1)
          .backgroundColor(AppColors.SURFACE_TINT)
          .borderRadius(AppRadius.PILL)
          .onClick(() => this.saveCsv())
        Button('保存 XLSX')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.SURFACE)
          .height(48)
          .layoutWeight(1)
          .backgroundColor(AppColors.CHART_BLUE)
          .borderRadius(AppRadius.PILL)
          .onClick(() => this.saveExcelWorkbook())
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
  private DataToolsCard() {
    Column({ space: 12 }) {
      Text('数据工具')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.INK)
        .width('100%')
      Text('备份文件可在换机或重装后恢复，导入仅识别一页账导出的 CSV。')
        .fontSize(12)
        .fontColor(AppColors.MUTED)
        .lineHeight(18)
        .width('100%')
      Row({ space: 10 }) {
        Button('备份数据')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.CHART_BLUE)
          .height(44)
          .layoutWeight(1)
          .backgroundColor(AppColors.SURFACE_TINT)
          .borderRadius(AppRadius.PILL)
          .onClick(() => this.backupData())
        Button(this.restoreConfirming ? '再次确认恢复' : '恢复数据')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.EXPENSE)
          .height(44)
          .layoutWeight(1)
          .backgroundColor(AppColors.softDanger())
          .borderRadius(AppRadius.PILL)
          .onClick(() => this.confirmRestore())
      }
      .width('100%')
      Button('导入一页账 CSV')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.SURFACE)
        .height(44)
        .width('100%')
        .backgroundColor(AppColors.CHART_GREEN)
        .borderRadius(AppRadius.PILL)
        .onClick(() => this.importCsv())
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
      const file = fileIo.openSync(uris[0], fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC);
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

  private async saveExcelWorkbook(): Promise<void> {
    try {
      await AppDatabase.getInstance().init(getContext(this));
      this.records = await this.loadScopedRecords();
      this.csvText = this.buildCsv(this.records);
      this.refreshTotals();
      const context = getContext(this) as common.UIAbilityContext;
      const options = new picker.DocumentSaveOptions();
      options.newFileNames = [`一页账-${this.fileNameSuffix()}.xlsx`];
      options.fileSuffixChoices = ['Excel 工作簿|.xlsx'];
      const uris = await new picker.DocumentViewPicker(context).save(options);
      if (uris.length === 0) {
        ToastUtil.show('未保存 Excel 文件');
        return;
      }
      const file = fileIo.openSync(uris[0], fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC);
      try {
        fileIo.writeSync(file.fd, this.buildXlsxWorkbook(this.records));
      } finally {
        fileIo.closeSync(file);
      }
      ToastUtil.show(`Excel 已保存：${uris[0]}`);
    } catch (error) {
      ToastUtil.show(`Excel 未保存：${ToastUtil.error(error)}`);
    }
  }

  private async backupData(): Promise<void> {
    try {
      await AppDatabase.getInstance().init(getContext(this));
      const result = await DataBackupService.saveToFile(getContext(this) as common.UIAbilityContext);
      ToastUtil.show(`备份完成：${result.recordCount} 条账单`);
    } catch (error) {
      ToastUtil.show(`备份失败：${ToastUtil.error(error)}`);
    }
  }

  private async restoreData(): Promise<void> {
    try {
      await AppDatabase.getInstance().init(getContext(this));
      const result = await DataBackupService.restoreFromFile(getContext(this) as common.UIAbilityContext);
      await AppState.getInstance().refreshAll();
      await SpendingCardService.refreshAllForms(getContext(this));
      await this.loadRecords();
      ToastUtil.show(`恢复完成：${result.recordCount} 条账单`);
    } catch (error) {
      ToastUtil.show(`恢复失败：${ToastUtil.error(error)}`);
    }
  }

  private confirmRestore(): void {
    if (!this.restoreConfirming) {
      this.restoreConfirming = true;
      ToastUtil.show('恢复会覆盖当前账单、账户、分类和预算，再次点击确认');
      return;
    }
    this.restoreConfirming = false;
    this.restoreData();
  }

  private async importCsv(): Promise<void> {
    try {
      await AppDatabase.getInstance().init(getContext(this));
      const result = await new LedgerCsvImportService().pickAndImport(getContext(this) as common.UIAbilityContext);
      await AppState.getInstance().refreshAll();
      await SpendingCardService.refreshAllForms(getContext(this));
      await this.loadRecords();
      ToastUtil.show(`导入完成：${result.importedRows} 条，跳过 ${result.skippedRows} 条`);
    } catch (error) {
      ToastUtil.show(`导入失败：${ToastUtil.error(error)}`);
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

  private buildXlsxWorkbook(records: RecordListItem[]): ArrayBuffer {
    const entries: XlsxZipEntry[] = [
      { name: '[Content_Types].xml', content: this.xlsxContentTypes() },
      { name: '_rels/.rels', content: this.xlsxRootRels() },
      { name: 'xl/workbook.xml', content: this.xlsxWorkbook() },
      { name: 'xl/_rels/workbook.xml.rels', content: this.xlsxWorkbookRels() },
      { name: 'xl/styles.xml', content: this.xlsxStyles() },
      { name: 'xl/worksheets/sheet1.xml', content: this.xlsxSheet(records) }
    ];
    return this.zipStore(entries);
  }

  private xlsxSheet(records: RecordListItem[]): string {
    const rows: string[] = [this.xlsxRow(1, ['日期', '类型', '分类', '金额', '账户', '备注'])];
    records.forEach((item: RecordListItem, index: number) => {
      rows.push(this.xlsxRow(index + 2, [
        DateUtil.dayLabel(item.recordTime) + ' ' + DateUtil.timeLabel(item.recordTime),
        this.typeLabel(item.type),
        item.categoryName,
        `${item.type === RecordType.EXPENSE ? '-' : ''}${NumberUtil.plainMoney(item.amount)}`,
        item.accountName,
        item.remark
      ]));
    });
    const dimension = `A1:F${Math.max(1, records.length + 1)}`;
    return `<?xml version="1.0" encoding="UTF-8" standalone="yes"?><worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><dimension ref="${dimension}"/><cols><col min="1" max="1" width="22" customWidth="1"/><col min="2" max="3" width="12" customWidth="1"/><col min="4" max="4" width="14" customWidth="1"/><col min="5" max="6" width="18" customWidth="1"/></cols><sheetData>${rows.join('')}</sheetData></worksheet>`;
  }

  private xlsxRow(rowIndex: number, values: string[]): string {
    const cells = values.map((value: string, index: number) => {
      const ref = `${this.xlsxColumnName(index)}${rowIndex}`;
      return `<c r="${ref}" t="inlineStr"><is><t>${this.escapeXml(value)}</t></is></c>`;
    }).join('');
    return `<row r="${rowIndex}">${cells}</row>`;
  }

  private xlsxColumnName(index: number): string {
    return String.fromCharCode('A'.charCodeAt(0) + index);
  }

  private xlsxContentTypes(): string {
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/><Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/></Types>';
  }

  private xlsxRootRels(): string {
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>';
  }

  private xlsxWorkbook(): string {
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets><sheet name="账单" sheetId="1" r:id="rId1"/></sheets></workbook>';
  }

  private xlsxWorkbookRels(): string {
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/><Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/></Relationships>';
  }

  private xlsxStyles(): string {
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><fonts count="1"><font><sz val="11"/><name val="Arial"/></font></fonts><fills count="1"><fill><patternFill patternType="none"/></fill></fills><borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders><cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs><cellXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/></cellXfs></styleSheet>';
  }

  private zipStore(entries: XlsxZipEntry[]): ArrayBuffer {
    const bytes: number[] = [];
    const central: XlsxZipInfo[] = [];
    entries.forEach((entry: XlsxZipEntry) => {
      const nameBytes = this.utf8Bytes(entry.name);
      const contentBytes = this.utf8Bytes(entry.content);
      const crc = this.crc32(contentBytes);
      const offset = bytes.length;
      this.pushUInt32(bytes, 0x04034b50);
      this.pushUInt16(bytes, 20);
      this.pushUInt16(bytes, 2048);
      this.pushUInt16(bytes, 0);
      this.pushUInt16(bytes, 0);
      this.pushUInt16(bytes, 0);
      this.pushUInt32(bytes, crc);
      this.pushUInt32(bytes, contentBytes.length);
      this.pushUInt32(bytes, contentBytes.length);
      this.pushUInt16(bytes, nameBytes.length);
      this.pushUInt16(bytes, 0);
      this.pushBytes(bytes, nameBytes);
      this.pushBytes(bytes, contentBytes);
      central.push({ name: entry.name, crc, size: contentBytes.length, offset });
    });

    const centralOffset = bytes.length;
    central.forEach((info: XlsxZipInfo) => {
      const nameBytes = this.utf8Bytes(info.name);
      this.pushUInt32(bytes, 0x02014b50);
      this.pushUInt16(bytes, 20);
      this.pushUInt16(bytes, 20);
      this.pushUInt16(bytes, 2048);
      this.pushUInt16(bytes, 0);
      this.pushUInt16(bytes, 0);
      this.pushUInt16(bytes, 0);
      this.pushUInt32(bytes, info.crc);
      this.pushUInt32(bytes, info.size);
      this.pushUInt32(bytes, info.size);
      this.pushUInt16(bytes, nameBytes.length);
      this.pushUInt16(bytes, 0);
      this.pushUInt16(bytes, 0);
      this.pushUInt16(bytes, 0);
      this.pushUInt16(bytes, 0);
      this.pushUInt32(bytes, 0);
      this.pushUInt32(bytes, info.offset);
      this.pushBytes(bytes, nameBytes);
    });
    const centralSize = bytes.length - centralOffset;
    this.pushUInt32(bytes, 0x06054b50);
    this.pushUInt16(bytes, 0);
    this.pushUInt16(bytes, 0);
    this.pushUInt16(bytes, central.length);
    this.pushUInt16(bytes, central.length);
    this.pushUInt32(bytes, centralSize);
    this.pushUInt32(bytes, centralOffset);
    this.pushUInt16(bytes, 0);

    const buffer = new Uint8Array(bytes.length);
    bytes.forEach((value: number, index: number) => {
      buffer[index] = value;
    });
    return buffer.buffer;
  }

  private utf8Bytes(value: string): number[] {
    const bytes: number[] = [];
    for (let index = 0; index < value.length; index++) {
      let code = value.charCodeAt(index);
      if (code >= 0xD800 && code <= 0xDBFF && index + 1 < value.length) {
        const next = value.charCodeAt(index + 1);
        if (next >= 0xDC00 && next <= 0xDFFF) {
          code = 0x10000 + ((code - 0xD800) * 0x400) + (next - 0xDC00);
          index++;
        }
      }
      if (code < 0x80) {
        bytes.push(code);
      } else if (code < 0x800) {
        bytes.push(0xC0 | (code >> 6), 0x80 | (code & 0x3F));
      } else if (code < 0x10000) {
        bytes.push(0xE0 | (code >> 12), 0x80 | ((code >> 6) & 0x3F), 0x80 | (code & 0x3F));
      } else {
        bytes.push(0xF0 | (code >> 18), 0x80 | ((code >> 12) & 0x3F), 0x80 | ((code >> 6) & 0x3F), 0x80 | (code & 0x3F));
      }
    }
    return bytes;
  }

  private crc32(data: number[]): number {
    let crc = 0xFFFFFFFF;
    data.forEach((value: number) => {
      crc = crc ^ value;
      for (let bit = 0; bit < 8; bit++) {
        crc = (crc >>> 1) ^ ((crc & 1) > 0 ? 0xEDB88320 : 0);
      }
    });
    return (crc ^ 0xFFFFFFFF) >>> 0;
  }

  private pushBytes(target: number[], source: number[]): void {
    source.forEach((value: number) => {
      target.push(value & 0xFF);
    });
  }

  private pushUInt16(bytes: number[], value: number): void {
    bytes.push(value & 0xFF, (value >>> 8) & 0xFF);
  }

  private pushUInt32(bytes: number[], value: number): void {
    bytes.push(value & 0xFF, (value >>> 8) & 0xFF, (value >>> 16) & 0xFF, (value >>> 24) & 0xFF);
  }

  private escapeXml(value: string): string {
    return value.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&apos;');
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
