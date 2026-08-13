import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { AppColors, AppRadius, AppSpace, LayoutSizes } from '../constants/DesignSystem';
import { ROUTES } from '../constants/RouteConstants';
import { SettingsRepository } from '../repository/SettingsRepository';
import { AlipayBillImportService, AlipayImportResult } from '../service/AlipayBillImportService';
import { AutoBookkeepingService } from '../service/AutoBookkeepingService';
import { AppState } from '../viewmodel/AppState';
import { ToastUtil } from '../utils/ToastUtil';
import { AppDatabase } from '../database/AppDatabase';

@Entry
@Component
struct AlipayImport {
  private settingsRepository: SettingsRepository = new SettingsRepository();

  @State importEnabled: boolean = false;
  @State importing: boolean = false;
  @State pendingCount: number = 0;
  @State lastSummary: string = '';

  aboutToAppear(): void {
    this.loadState();
  }

  build() {
    Column() {
      this.Header()
      Scroll() {
        Column({ space: 16 }) {
          this.StatusCard()
          this.ImportCard()
          this.GuideCard()
        }
        .width('100%')
        .constraintSize({ maxWidth: LayoutSizes.CONTENT_MAX })
        .alignSelf(ItemAlign.Center)
        .padding({ left: AppSpace.PAGE, right: AppSpace.PAGE, top: 10, bottom: 28 })
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
      Text('支付宝账单导入')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.INK)
        .width('100%')
      Text('选择支付宝导出的 CSV，识别后先进入待确认账单')
        .fontSize(13)
        .fontColor(AppColors.MUTED)
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ left: AppSpace.PAGE, right: AppSpace.PAGE, top: 22, bottom: 8 })
  }

  @Builder
  private StatusCard() {
    Column({ space: 14 }) {
      Row() {
        Column({ space: 4 }) {
          Text('导入功能')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.INK)
          Text('关闭后不会读取或解析任何账单文件')
            .fontSize(12)
            .fontColor(AppColors.MUTED)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Text(this.importEnabled ? '开' : '关')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.importEnabled ? AppColors.SURFACE : AppColors.MUTED)
          .width(54)
          .height(34)
          .textAlign(TextAlign.Center)
          .backgroundColor(this.importEnabled ? AppColors.CHART_BLUE : AppColors.SURFACE_SOFT)
          .borderRadius(AppRadius.PILL)
          .onClick(() => this.toggleImport())
      }
      .width('100%')

      Row() {
        Text('待确认账单')
          .fontSize(13)
          .fontColor(AppColors.MUTED)
        Blank()
        Text(`${this.pendingCount} 条`)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.CHART_BLUE)
      }
      .width('100%')
      .padding(14)
      .backgroundColor(AppColors.SURFACE_SOFT)
      .borderRadius(16)
    }
    .width('100%')
    .padding(18)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 20, color: AppColors.SHADOW, offsetY: 8 })
  }

  @Builder
  private ImportCard() {
    Column({ space: 14 }) {
      Row() {
        Text('导入账单')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
        Blank()
        Text('CSV')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.CHART_BLUE)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor(AppColors.SURFACE_TINT)
          .borderRadius(AppRadius.PILL)
      }
      .width('100%')

      Button(this.importing ? '正在导入...' : '选择支付宝账单文件')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.SURFACE)
        .height(50)
        .width('100%')
        .enabled(this.importEnabled && !this.importing)
        .opacity(this.importEnabled && !this.importing ? 1 : 0.45)
        .backgroundColor(AppColors.CHART_BLUE)
        .borderRadius(AppRadius.PILL)
        .onClick(() => this.importBill())

      Button('查看待确认账单')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.CHART_BLUE)
        .height(46)
        .width('100%')
        .backgroundColor(AppColors.SURFACE_TINT)
        .borderRadius(AppRadius.PILL)
        .onClick(() => router.pushUrl({ url: ROUTES.AUTO_BOOKKEEPING }))

      if (this.lastSummary.length > 0) {
        Text(this.lastSummary)
          .fontSize(13)
          .fontColor(AppColors.MUTED)
          .lineHeight(21)
          .width('100%')
          .padding(14)
          .backgroundColor(AppColors.SURFACE_SOFT)
          .borderRadius(16)
      }
    }
    .width('100%')
    .padding(18)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 20, color: AppColors.SHADOW, offsetY: 8 })
  }

  @Builder
  private GuideCard() {
    Column({ space: 12 }) {
      Text('使用说明')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.INK)
        .width('100%')
      this.GuideRow('1', '在支付宝账单中申请并下载 CSV 账单文件')
      this.GuideRow('2', '回到这里选择文件，系统会在设备内解析')
      this.GuideRow('3', '到待确认账单检查分类、金额和账户后再入账')
      Text('导入功能不连接支付宝账户，不读取密码、验证码或银行卡信息。文件内容不会上传。')
        .fontSize(12)
        .fontColor(AppColors.MUTED)
        .lineHeight(20)
        .width('100%')
    }
    .width('100%')
    .padding(18)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 20, color: AppColors.SHADOW, offsetY: 8 })
  }

  @Builder
  private GuideRow(index: string, text: string) {
    Row({ space: 12 }) {
      Text(index)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.CHART_BLUE)
        .width(32)
        .height(32)
        .textAlign(TextAlign.Center)
        .backgroundColor(AppColors.SURFACE_TINT)
        .borderRadius(16)
      Text(text)
        .fontSize(13)
        .fontColor(AppColors.INK)
        .layoutWeight(1)
        .maxLines(2)
    }
    .width('100%')
  }

  private async loadState(): Promise<void> {
    try {
      await AppDatabase.getInstance().init(getContext(this));
      const settings = await this.settingsRepository.load(getContext(this));
      this.importEnabled = settings.alipayBillImportEnabled;
      this.pendingCount = await AutoBookkeepingService.create(getContext(this)).countPending();
    } catch (error) {
      this.pendingCount = 0;
      ToastUtil.show('导入状态加载失败，请重试');
    }
  }

  private async toggleImport(): Promise<void> {
    const settings = await this.settingsRepository.load(getContext(this));
    settings.alipayBillImportEnabled = !this.importEnabled;
    await this.settingsRepository.save(getContext(this), settings);
    this.importEnabled = settings.alipayBillImportEnabled;
    ToastUtil.show(this.importEnabled ? '支付宝账单导入已开启' : '支付宝账单导入已关闭');
  }

  private async importBill(): Promise<void> {
    if (!this.importEnabled || this.importing) {
      return;
    }
    this.importing = true;
    try {
      await AppDatabase.getInstance().init(getContext(this));
      const result: AlipayImportResult = await AlipayBillImportService.pickAndImport(
        getContext(this) as common.UIAbilityContext
      );
      this.lastSummary = `${result.fileName}：读取 ${result.totalRows} 条，加入待确认 ${result.importedRows} 条，跳过 ${result.skippedRows} 条。`;
      await AppState.getInstance().refreshPendingAutoBills();
      await this.loadState();
      ToastUtil.show(`已加入 ${result.importedRows} 条待确认账单`);
    } catch (error) {
      ToastUtil.show(ToastUtil.error(error, '导入未完成，请确认文件为支付宝 CSV 账单'));
    } finally {
      this.importing = false;
    }
  }
}
