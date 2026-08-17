import { router } from '@kit.ArkUI';
import { AppColors, AppRadius, AppSpace, LayoutSizes } from '../constants/DesignSystem';
import { ROUTES } from '../constants/RouteConstants';
import { AppSettingsData, SettingsRepository, ThemeMode } from '../repository/SettingsRepository';
import { ThemeUtil } from '../utils/ThemeUtil';
import { ToastUtil } from '../utils/ToastUtil';

@Entry
@Component
struct Settings {
  private repository: SettingsRepository = new SettingsRepository();

  @State userName: string = '账本';
  @State themeMode: ThemeMode = ThemeMode.SYSTEM;
  @State currencySymbol: string = '¥';
  @State autoBookkeepingEnabled: boolean = false;
  @State autoReviewEnabled: boolean = true;
  @State autoDefaultAccountId: number = 0;
  @State alipayBillImportEnabled: boolean = false;
  @StorageLink('ledgerIsDarkMode') isDarkMode: boolean = false;

  aboutToAppear(): void {
    this.loadSettings();
  }

  build() {
    Column() {
      this.Header()

      Scroll() {
        Column({ space: 18 }) {
          this.ProfileCard()
          this.ThemeCard()
          this.CurrencyCard()
          this.DataCard()
          this.SaveBar()
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
  private ProfileCard() {
    Column({ space: 12 }) {
      this.CardTitle('称呼', this.userName.trim() || '未设置')
      TextInput({ text: this.userName, placeholder: '输入你的名字或昵称' })
        .height(50)
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .backgroundColor(AppColors.SURFACE_SOFT)
        .borderRadius(16)
        .padding({ left: 16, right: 16 })
        .onChange((value: string) => {
          this.userName = value;
        })
      Text('只保存在本机，用于首页问候和头像显示。')
        .fontSize(12)
        .fontColor(AppColors.MUTED)
        .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 20, color: AppColors.SHADOW, offsetY: 8 })
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
        Text('设置')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .width('100%')
        Text('主题、货币和偏好')
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
  private ThemeCard() {
    Column({ space: 14 }) {
      this.CardTitle('外观', this.themeLabel())
      Row({ space: 8 }) {
        this.ThemeButton('跟随系统', ThemeMode.SYSTEM)
        this.ThemeButton('浅色', ThemeMode.LIGHT)
        this.ThemeButton('深色', ThemeMode.DARK)
      }
      .width('100%')
      Text('已保存主题偏好，后续页面配色会按该偏好扩展。')
        .fontSize(12)
        .fontColor(AppColors.MUTED)
        .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 20, color: AppColors.SHADOW, offsetY: 8 })
  }

  @Builder
  private CurrencyCard() {
    Column({ space: 14 }) {
      this.CardTitle('货币', this.currencySymbol || '¥')
      TextInput({ text: this.currencySymbol, placeholder: '¥' })
        .height(50)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .backgroundColor(AppColors.SURFACE_SOFT)
        .borderRadius(16)
        .padding({ left: 16, right: 16 })
        .onChange((value: string) => {
          this.currencySymbol = value;
        })
      Text('例如 ¥、$、€，会保存在偏好设置中。')
        .fontSize(12)
        .fontColor(AppColors.MUTED)
        .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 20, color: AppColors.SHADOW, offsetY: 8 })
  }

  @Builder
  private DataCard() {
    Column({ space: 12 }) {
      this.CardTitle('数据与管理', '快捷入口')
      this.RouteRow('收支日历', '按日期查看每日收支', ROUTES.CALENDAR)
      this.RouteRow('分类管理', '调整常用分类和排序', ROUTES.CATEGORY_MANAGE)
      this.RouteRow('账户管理', '新增、编辑账户余额', ROUTES.ACCOUNT_MANAGE)
      this.RouteRow('预算管理', '设置月度预算', ROUTES.BUDGET_SETTING)
      this.RouteRow('数据导出', '导出 CSV 和备份文件', ROUTES.DATA_EXPORT)
      this.RouteRow('关于', '版本和说明', ROUTES.ABOUT)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 20, color: AppColors.SHADOW, offsetY: 8 })
  }

  @Builder
  private SaveBar() {
    Row({ space: 10 }) {
      Button('保存设置')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.SURFACE)
        .height(50)
        .layoutWeight(1)
        .backgroundColor(AppColors.CHART_BLUE)
        .borderRadius(AppRadius.PILL)
        .onClick(() => this.saveSettings())
      Button('恢复默认')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.EXPENSE)
        .height(50)
        .layoutWeight(1)
        .backgroundColor(AppColors.softDanger())
        .borderRadius(AppRadius.PILL)
        .onClick(() => this.resetSettings())
    }
    .width('100%')
  }

  @Builder
  private CardTitle(title: string, badge: string) {
    Row() {
      Text(title)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.INK)
      Blank()
      Text(badge)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.LEDGER)
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .backgroundColor(AppColors.SURFACE_TINT)
        .borderRadius(AppRadius.PILL)
    }
    .width('100%')
  }

  @Builder
  private ThemeButton(label: string, mode: ThemeMode) {
    Text(label)
      .fontSize(14)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.themeMode === mode ? AppColors.INK : AppColors.MUTED)
      .height(42)
      .layoutWeight(1)
      .textAlign(TextAlign.Center)
      .backgroundColor(this.themeMode === mode ? AppColors.SURFACE_TINT : AppColors.SURFACE_SOFT)
      .borderRadius(AppRadius.PILL)
      .onClick(() => {
        this.themeMode = mode;
        ThemeUtil.apply(mode, getContext(this));
        this.saveSettings(false);
      })
  }

  @Builder
  private RouteRow(title: string, subtitle: string, url: string) {
    Row({ space: 12 }) {
      Column({ space: 4 }) {
        Text(title)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .width('100%')
        Text(subtitle)
          .fontSize(12)
          .fontColor(AppColors.MUTED)
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Text('›')
        .fontSize(24)
        .fontColor(AppColors.FAINT)
    }
    .height(62)
    .width('100%')
    .padding({ left: 14, right: 14 })
    .backgroundColor(AppColors.SURFACE_SOFT)
    .borderRadius(18)
    .onClick(() => router.pushUrl({ url }))
  }

  private async loadSettings(): Promise<void> {
    try {
      this.userName = await this.repository.loadUserName(getContext(this));
      const settings = await this.repository.load(getContext(this));
      this.themeMode = settings.themeMode;
      ThemeUtil.apply(this.themeMode, getContext(this));
      this.currencySymbol = settings.currencySymbol;
      this.autoBookkeepingEnabled = settings.autoBookkeepingEnabled;
      this.autoReviewEnabled = settings.autoReviewEnabled;
      this.autoDefaultAccountId = settings.autoDefaultAccountId;
      this.alipayBillImportEnabled = settings.alipayBillImportEnabled;
    } catch (error) {
      ToastUtil.show(ToastUtil.error(error, '设置加载失败'));
    }
  }

  private async saveSettings(showToast: boolean = true): Promise<void> {
    const settings: AppSettingsData = {
      themeMode: this.themeMode,
      currencySymbol: this.currencySymbol.trim() || '¥',
      autoBookkeepingEnabled: false,
      autoReviewEnabled: true,
      autoDefaultAccountId: 0,
      alipayBillImportEnabled: false
    };
    try {
      await this.repository.saveUserName(getContext(this), this.userName);
      this.userName = this.userName.trim() || '账本';
      await this.repository.save(getContext(this), settings);
      if (showToast) {
        ToastUtil.show('设置已保存');
      }
    } catch (error) {
      ToastUtil.show(ToastUtil.error(error, '设置保存失败'));
    }
  }

  private async resetSettings(): Promise<void> {
    try {
      await this.repository.reset(getContext(this));
      await this.loadSettings();
      ThemeUtil.apply(this.themeMode, getContext(this));
      ToastUtil.show('已恢复默认设置');
    } catch (error) {
      ToastUtil.show(ToastUtil.error(error, '恢复默认失败'));
    }
  }

  private themeLabel(): string {
    if (this.themeMode === ThemeMode.LIGHT) {
      return '浅色';
    }
    if (this.themeMode === ThemeMode.DARK) {
      return '深色';
    }
    return '跟随系统';
  }

}
