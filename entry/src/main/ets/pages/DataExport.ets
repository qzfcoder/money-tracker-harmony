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

@Entry
@Component
struct DataExport {
  private repository: RecordRepository = new RecordRepository();

  @State records: RecordListItem[] = [];
  @State csvText: string = '';

  aboutToAppear(): void {
    this.loadRecords();
  }

  build() {
    Column() {
      this.Header()
      Scroll() {
        Column({ space: 16 }) {
          this.SummaryCard()
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
          Text('可导出账单')
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
      Text('可导出最近 1000 条流水。点击保存后选择文件位置，可直接使用表格应用打开。')
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
      this.records = await this.repository.listRecent(1000, 0);
      this.csvText = this.buildCsv(this.records);
    } catch (error) {
      ToastUtil.show('账单数据加载失败，请重试');
    }
  }

  private async saveCsv(): Promise<void> {
    try {
      await AppDatabase.getInstance().init(getContext(this));
      this.records = await this.repository.listRecent(1000, 0);
      this.csvText = this.buildCsv(this.records);
      const context = getContext(this) as common.UIAbilityContext;
      const options = new picker.DocumentSaveOptions();
      options.newFileNames = [`一页账-${DateUtil.dayKey(Date.now())}.csv`];
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
