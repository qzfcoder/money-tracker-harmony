import { router } from '@kit.ArkUI';
import { AppColors, AppRadius, AppSpace, Breakpoints, LayoutSizes } from '../constants/DesignSystem';
import { FeatureFlags } from '../constants/FeatureFlags';
import { PlaceholderPage } from '../components/PlaceholderPage';
import { CategoryModel } from '../model/Category';
import { AccountModel } from '../model/Account';
import { AutoBillModel, AutoRuleModel, AutoRuleType } from '../model/AutoBookkeeping';
import { RecordType } from '../model/Record';
import { AccountRepository } from '../repository/AccountRepository';
import { CategoryRepository } from '../repository/CategoryRepository';
import { AppSettingsData, SettingsRepository, ThemeMode } from '../repository/SettingsRepository';
import { AutoBookkeepingService } from '../service/AutoBookkeepingService';
import { OcrBookkeepingService } from '../service/OcrBookkeepingService';
import { AppState } from '../viewmodel/AppState';
import { DateUtil } from '../utils/DateUtil';
import { NumberUtil } from '../utils/NumberUtil';
import { ToastUtil } from '../utils/ToastUtil';
import { AppDatabase } from '../database/AppDatabase';

enum AutoPageTab {
  OCR = 'ocr',
  PENDING = 'pending',
  RULES = 'rules',
  SETTINGS = 'settings'
}

interface AutoBookkeepingParams {
  launchAction?: string;
  recordTime?: number;
}

@Entry
@Component
struct AutoBookkeeping {
  private settingsRepository: SettingsRepository = new SettingsRepository();
  private categoryRepository: CategoryRepository = new CategoryRepository();
  private accountRepository: AccountRepository = new AccountRepository();

  @State viewportWidth: number = 0;
  @State activeTab: AutoPageTab = AutoPageTab.OCR;
  @State pendingBills: AutoBillModel[] = [];
  @State rules: AutoRuleModel[] = [];
  @State categories: CategoryModel[] = [];
  @State accounts: AccountModel[] = [];

  @State themeMode: ThemeMode = ThemeMode.SYSTEM;
  @State currencySymbol: string = '¥';
  @State autoEnabled: boolean = false;
  @State reviewEnabled: boolean = true;
  @State defaultAccountId: number = 0;
  @State alipayBillImportEnabled: boolean = false;

  @State ruleType: AutoRuleType = AutoRuleType.CATEGORY;
  @State ruleKeyword: string = '';
  @State ruleRecordType: RecordType.EXPENSE | RecordType.INCOME = RecordType.EXPENSE;
  @State selectedCategoryId: number = 0;
  @State testText: string = '';
  @State previewSummary: string = '';
  @State ocrRecognizing: boolean = false;
  @State ocrText: string = '';
  @State ocrSummary: string = '';
  @State ocrRecordTime: number = 0;
  @State launchPromptVisible: boolean = false;
  @State editingBillId: number = 0;
  @State editingAmountText: string = '';
  @State editingType: RecordType.EXPENSE | RecordType.INCOME = RecordType.EXPENSE;
  @State editingCategoryId: number = 0;
  @State editingAccountId: number = 0;
  @State editingRemark: string = '';
  private pendingLaunchAction: string = '';
  private pendingLaunchRecordTime: number = 0;
  private launchActionHandled: boolean = false;

  aboutToAppear(): void {
    if (!FeatureFlags.AUTO_BOOKKEEPING_VISIBLE) {
      return;
    }
    this.readLaunchParams();
    this.loadAll().then(() => {
      this.handleLaunchAction();
    });
  }

  build() {
    if (!FeatureFlags.AUTO_BOOKKEEPING_VISIBLE) {
      PlaceholderPage({
        title: '当前版本未开放',
        description: '发布版暂不开放主动识别入口，请使用手动记账、搜索、预算和数据导出功能。'
      })
    } else {
      Column() {
        this.Header()

        Scroll() {
          Column({ space: 18 }) {
            this.SummaryCard()
            this.TabSwitch()
            if (this.activeTab === AutoPageTab.OCR) {
              if (this.launchPromptVisible) {
                this.LaunchActionCard()
              }
              this.OcrCaptureCard()
              this.OcrResultCard()
            } else if (this.activeTab === AutoPageTab.PENDING) {
              this.TestCard()
              this.PendingCard()
            } else if (this.activeTab === AutoPageTab.RULES) {
              this.RuleFormCard()
              this.RuleListCard()
            } else {
              this.SourceSettingsCard()
              this.DataCacheCard()
            }
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
      .onAreaChange((oldValue, newValue) => {
        this.viewportWidth = parseFloat(`${newValue.width}`);
      })
    }
  }

  @Builder
  private Header() {
    Column({ space: 6 }) {
      Button('‹')
        .fontSize(28)
        .fontColor(AppColors.CHART_BLUE)
        .width(46)
        .height(46)
        .backgroundColor(AppColors.SURFACE)
        .borderRadius(23)
        .shadow({ radius: 14, color: AppColors.SHADOW, offsetY: 6 })
        .alignSelf(ItemAlign.Start)
        .onClick(() => router.back())
      Column({ space: 4 }) {
        Text('自动记账')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .width('100%')
        Text('截图 OCR、规则识别和待确认账单')
          .fontSize(13)
          .fontColor(AppColors.MUTED)
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
    }
    .width('100%')
    .padding({ left: AppSpace.PAGE, right: AppSpace.PAGE, top: 34, bottom: 10 })
  }

  @Builder
  private SummaryCard() {
    Column({ space: 16 }) {
      Row() {
        Text('识')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.CHART_BLUE)
          .width(52)
          .height(52)
          .textAlign(TextAlign.Center)
          .borderRadius(18)
          .backgroundColor(AppColors.SURFACE_TINT)
        Column({ space: 4 }) {
          Text(this.autoEnabled ? '主动识别已开启' : '主动识别未开启')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.INK)
          Text(this.autoEnabled ? '选择账单截图识别，结果先进入待确认。' : '开启后可使用截图 OCR 辅助识别账单。')
            .fontSize(13)
            .fontColor(AppColors.MUTED)
            .maxLines(2)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')

      if (this.isWide()) {
        Row({ space: 10 }) {
          this.StatChip('待确认', `${this.pendingBills.length} 条`, AppColors.CHART_BLUE, AppColors.SURFACE_TINT)
          this.StatChip('规则', `${this.rules.length} 条`, AppColors.CHART_GREEN, '#E6F7EF')
          this.StatChip('来源', this.sourceSummary(), AppColors.WARNING, '#FFF4DE')
        }
        .width('100%')
      } else {
        Column({ space: 10 }) {
          Row({ space: 10 }) {
            this.StatChip('待确认', `${this.pendingBills.length} 条`, AppColors.CHART_BLUE, AppColors.SURFACE_TINT)
            this.StatChip('规则', `${this.rules.length} 条`, AppColors.CHART_GREEN, '#E6F7EF')
          }
          Row({ space: 10 }) {
            this.StatChip('来源', this.sourceSummary(), AppColors.WARNING, '#FFF4DE')
            this.StatChip('校验', this.reviewEnabled ? '先确认' : '手动入队', AppColors.CHART_PINK, '#FFEAF0')
          }
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(22)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 24, color: AppColors.SHADOW, offsetY: 10 })
  }

  @Builder
  private StatChip(label: string, value: string, color: string, bgColor: string) {
    Column({ space: 4 }) {
      Text(label)
        .fontSize(12)
        .fontColor(AppColors.MUTED)
      Text(value)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
        .maxLines(1)
    }
    .layoutWeight(1)
    .padding(12)
    .backgroundColor(bgColor)
    .borderRadius(18)
  }

  @Builder
  private TabSwitch() {
    Row({ space: 6 }) {
      this.TabButton('截图识别', AutoPageTab.OCR)
      this.TabButton('待确认', AutoPageTab.PENDING)
      this.TabButton('规则', AutoPageTab.RULES)
      this.TabButton('设置', AutoPageTab.SETTINGS)
    }
    .height(50)
    .padding(4)
    .backgroundColor('#E7EAEE')
    .borderRadius(AppRadius.PILL)
  }

  @Builder
  private TabButton(label: string, tab: AutoPageTab) {
    Text(label)
      .fontSize(14)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.activeTab === tab ? AppColors.INK : AppColors.MUTED)
      .height(42)
      .layoutWeight(1)
      .textAlign(TextAlign.Center)
      .backgroundColor(this.activeTab === tab ? AppColors.SURFACE : '#00000000')
      .borderRadius(AppRadius.PILL)
      .shadow(this.activeTab === tab ? { radius: 10, color: AppColors.SHADOW, offsetY: 4 } : { radius: 0, color: '#00000000', offsetY: 0 })
      .onClick(() => {
        this.activeTab = tab;
      })
  }

  @Builder
  private TestCard() {
    Column({ space: 12 }) {
      this.CardTitle('测试识别', '不上传内容')
      if (this.ocrSummary.length > 0 && this.ocrText.length === 0) {
        Text(this.ocrSummary)
          .fontSize(13)
          .fontColor(AppColors.WARNING)
          .lineHeight(21)
          .width('100%')
          .padding(12)
          .backgroundColor('#FFF6DF')
          .borderRadius(16)
      }
      TextArea({ text: this.testText, placeholder: '粘贴单笔交易内容，如：支付宝付款28.50元，奶茶店，餐饮' })
        .height(96)
        .fontSize(14)
        .backgroundColor(AppColors.SURFACE_SOFT)
        .borderRadius(18)
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .onChange((value: string) => {
          this.testText = value;
        })
      Text('每次建议粘贴一笔交易；多笔交易请分开加入待确认，避免金额串到一起。')
        .fontSize(12)
        .fontColor(AppColors.MUTED)
        .lineHeight(19)
        .width('100%')
      Row({ space: 10 }) {
        this.ActionButton('预览识别', AppColors.CHART_BLUE, AppColors.SURFACE_TINT, () => this.previewText())
        this.ActionButton('加入待确认', AppColors.SURFACE, AppColors.CHART_BLUE, () => this.captureText())
      }
      .width('100%')
      if (this.previewSummary.length > 0) {
        Text(this.previewSummary)
          .fontSize(13)
          .fontColor(AppColors.MUTED)
          .lineHeight(21)
          .width('100%')
      }
    }
    .width('100%')
    .padding(20)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 20, color: AppColors.SHADOW, offsetY: 8 })
  }

  @Builder
  private PendingCard() {
    Column({ space: 12 }) {
      Row() {
        Text('待确认账单')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
        Blank()
        Button('清空缓存')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.EXPENSE)
          .height(34)
          .padding({ left: 12, right: 12 })
          .backgroundColor('#FCE9E4')
          .borderRadius(AppRadius.PILL)
          .onClick(() => this.clearCache())
      }
      .width('100%')

      if (this.pendingBills.length === 0) {
        this.EmptyState('暂无待确认账单', '截图识别或导入账单后会先放在这里')
      } else {
        ForEach(this.pendingBills, (item: AutoBillModel) => {
          this.PendingRow(item)
        }, (item: AutoBillModel) => `${item.id}`)
      }
    }
    .width('100%')
  }

  @Builder
  private LaunchActionCard() {
    Column({ space: 12 }) {
      this.CardTitle('日历识别待开始', this.launchRecordDateLabel())
      Text('已带入日历选中的日期。若系统没有自动弹出识别窗口，请点下面按钮开始。')
        .fontSize(13)
        .fontColor(AppColors.MUTED)
        .lineHeight(21)
        .width('100%')
      Row({ space: 10 }) {
        this.ActionButton('开始识别账单', AppColors.SURFACE, AppColors.CHART_BLUE, () => this.startPendingLaunchAction())
        this.ActionButton('稍后再识别', AppColors.CHART_BLUE, AppColors.SURFACE_TINT, () => {
          this.launchPromptVisible = false;
          this.pendingLaunchAction = '';
          this.pendingLaunchRecordTime = 0;
        })
      }
      .width('100%')
    }
    .width('100%')
    .padding(18)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 20, color: AppColors.SHADOW, offsetY: 8 })
  }

  @Builder
  private OcrCaptureCard() {
    Column({ space: 14 }) {
      this.CardTitle('截图识别', this.ocrRecognizing ? '识别中' : '手动选择')
      Column({ space: 8 }) {
        this.StepRow('1', '在支付宝、微信或银行账单页手动截图')
        this.StepRow('2', '回到应用选择截图，本机 OCR 识别文字')
        this.StepRow('3', '本机 OCR 识别后先进入待确认账单')
      }
      .width('100%')
      this.ActionButton('从相册选择截图', AppColors.CHART_BLUE, AppColors.SURFACE_TINT, () => this.pickAndRecognize())
      Text('不会自动截屏，也不会读取支付宝数据；只有你主动选择截图后，才会在本机 OCR 识别。')
        .fontSize(12)
        .fontColor(AppColors.MUTED)
        .lineHeight(20)
        .width('100%')
    }
    .width('100%')
    .padding(20)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 20, color: AppColors.SHADOW, offsetY: 8 })
  }

  @Builder
  private OcrResultCard() {
    Column({ space: 12 }) {
      this.CardTitle('OCR 结果', this.ocrText.length > 0 ? '已识别' : '待选择')
      if (this.ocrText.length === 0) {
        this.EmptyState('暂无识别文本', '选择账单截图后会显示 OCR 识别结果')
      } else {
        Text(this.ocrSummary.length > 0 ? this.ocrSummary : '已识别文字，可加入待确认账单')
          .fontSize(13)
          .fontColor(AppColors.CHART_BLUE)
          .lineHeight(21)
          .width('100%')
          .padding(12)
          .backgroundColor(AppColors.SURFACE_TINT)
          .borderRadius(16)
        Text(this.ocrText)
          .fontSize(13)
          .fontColor(AppColors.MUTED)
          .lineHeight(21)
          .maxLines(6)
          .width('100%')
          .padding(12)
          .backgroundColor(AppColors.SURFACE_SOFT)
          .borderRadius(16)
        Row({ space: 10 }) {
          this.ActionButton('加入待确认', AppColors.SURFACE, AppColors.CHART_GREEN, () => this.captureOcrText())
          this.ActionButton('清空结果', AppColors.EXPENSE, '#FCE9E4', () => {
            this.ocrText = '';
            this.ocrSummary = '';
          })
        }
        .width('100%')
      }
    }
    .width('100%')
  }

  @Builder
  private StepRow(mark: string, text: string) {
    Row({ space: 10 }) {
      Text(mark)
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.SURFACE)
        .width(26)
        .height(26)
        .textAlign(TextAlign.Center)
        .backgroundColor(AppColors.CHART_BLUE)
        .borderRadius(13)
      Text(text)
        .fontSize(13)
        .fontColor(AppColors.INK)
        .layoutWeight(1)
        .maxLines(2)
    }
    .width('100%')
  }

  @Builder
  private PendingRow(item: AutoBillModel) {
    Column({ space: 12 }) {
      Row() {
        Row({ space: 10 }) {
          Text(this.typeMark(item.type))
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(item.type === RecordType.INCOME ? AppColors.CHART_GREEN : AppColors.CHART_PINK)
            .width(42)
            .height(42)
            .textAlign(TextAlign.Center)
            .backgroundColor(item.type === RecordType.INCOME ? '#E6F7EF' : '#FFEAF0')
            .borderRadius(16)
          Column({ space: 4 }) {
            Text(NumberUtil.money(item.amount))
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.INK)
            Text(`${item.categoryName || '未分类'} · ${item.accountName || '默认账户'} · ${DateUtil.timeLabel(item.recordTime)}`)
              .fontSize(12)
              .fontColor(AppColors.MUTED)
              .maxLines(1)
          }
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)

        Text(`${Math.round(item.confidence * 100)}%`)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.CHART_BLUE)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor(AppColors.SURFACE_TINT)
          .borderRadius(AppRadius.PILL)
      }
      .width('100%')

      Text(`${item.appName || this.sourceLabel(item.source)}：${item.title || item.content || item.rawText}`)
        .fontSize(12)
        .fontColor(AppColors.MUTED)
        .lineHeight(20)
        .maxLines(2)
        .width('100%')

      Row({ space: 10 }) {
        this.ActionButton('确认入账', AppColors.SURFACE, AppColors.CHART_GREEN, () => this.confirm(item))
        this.ActionButton(this.editingBillId === item.id ? '收起修改' : '修改', AppColors.CHART_BLUE, AppColors.SURFACE_TINT, () => this.toggleEditBill(item))
        this.ActionButton('忽略', AppColors.EXPENSE, '#FCE9E4', () => this.discard(item))
      }
      .width('100%')

      if (this.editingBillId === item.id) {
        this.PendingEditPanel(item)
      }
    }
    .width('100%')
    .padding(18)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 18, color: AppColors.SHADOW, offsetY: 8 })
  }

  @Builder
  private PendingEditPanel(item: AutoBillModel) {
    Column({ space: 12 }) {
      Row({ space: 8 }) {
        this.PendingTypeButton('支出', RecordType.EXPENSE)
        this.PendingTypeButton('收入', RecordType.INCOME)
      }
      .height(42)
      .padding(4)
      .backgroundColor(AppColors.SURFACE_SOFT)
      .borderRadius(AppRadius.PILL)

      TextInput({ text: this.editingAmountText, placeholder: '金额' })
        .type(InputType.NUMBER_DECIMAL)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.INK)
        .height(48)
        .backgroundColor(AppColors.SURFACE_SOFT)
        .borderRadius(16)
        .padding({ left: 14, right: 14 })
        .onChange((value: string) => {
          this.editingAmountText = this.normalizeAmount(value);
        })

      this.PendingOptionScroller('分类', this.editingCategories())
      this.PendingAccountScroller()

      TextInput({ text: this.editingRemark, placeholder: '备注' })
        .fontSize(14)
        .fontColor(AppColors.INK)
        .height(44)
        .backgroundColor(AppColors.SURFACE_SOFT)
        .borderRadius(16)
        .padding({ left: 14, right: 14 })
        .onChange((value: string) => {
          this.editingRemark = value;
        })

      Row({ space: 10 }) {
        this.ActionButton('保存修改', AppColors.SURFACE, AppColors.CHART_BLUE, () => this.savePendingEdit(item))
        this.ActionButton('取消', AppColors.MUTED, AppColors.SURFACE_SOFT, () => this.cancelPendingEdit())
      }
      .width('100%')
    }
    .width('100%')
    .padding(14)
    .backgroundColor(AppColors.SURFACE_SOFT)
    .borderRadius(18)
  }

  @Builder
  private PendingTypeButton(label: string, type: RecordType.EXPENSE | RecordType.INCOME) {
    Text(label)
      .fontSize(13)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.editingType === type ? AppColors.SURFACE : AppColors.INK)
      .height(34)
      .layoutWeight(1)
      .textAlign(TextAlign.Center)
      .backgroundColor(this.editingType === type ? AppColors.CHART_BLUE : '#00000000')
      .borderRadius(AppRadius.PILL)
      .onClick(() => {
        this.editingType = type;
        this.ensureEditingCategory();
      })
  }

  @Builder
  private PendingOptionScroller(title: string, list: CategoryModel[]) {
    Column({ space: 8 }) {
      Text(title)
        .fontSize(12)
        .fontColor(AppColors.MUTED)
        .width('100%')
      Scroll() {
        Row({ space: 8 }) {
          ForEach(list, (item: CategoryModel) => {
            Text(item.name)
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.editingCategoryId === item.id ? AppColors.SURFACE : AppColors.INK)
              .height(36)
              .padding({ left: 12, right: 12 })
              .backgroundColor(this.editingCategoryId === item.id ? item.color : AppColors.SURFACE)
              .borderRadius(AppRadius.PILL)
              .onClick(() => {
                this.editingCategoryId = item.id || 0;
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
  private PendingAccountScroller() {
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
              .fontColor(this.editingAccountId === item.id ? AppColors.SURFACE : AppColors.INK)
              .height(36)
              .padding({ left: 12, right: 12 })
              .backgroundColor(this.editingAccountId === item.id ? item.color : AppColors.SURFACE)
              .borderRadius(AppRadius.PILL)
              .onClick(() => {
                this.editingAccountId = item.id || 0;
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
  private SourceSettingsCard() {
    Column({ space: 14 }) {
      this.CardTitle('识别设置', this.autoEnabled ? '已开启' : '未开启')
      this.ToggleRow('自动记账总开关', '关闭后不进行截图识别和待确认缓存。', this.autoEnabled, () => {
        this.autoEnabled = !this.autoEnabled;
        this.saveSettings();
      })
      this.ToggleRow('自动记账校验开关', '开启后所有识别结果先进入待确认账单。', this.reviewEnabled, () => {
        this.reviewEnabled = !this.reviewEnabled;
        this.saveSettings();
      })
      Text('发布版采用用户主动触发：手动选择账单截图后，本机 OCR 识别结果先进入待确认。')
        .fontSize(12)
        .fontColor(AppColors.MUTED)
        .lineHeight(20)
        .width('100%')
    }
    .width('100%')
    .padding(20)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 20, color: AppColors.SHADOW, offsetY: 8 })
  }

  @Builder
  private DataCacheCard() {
    Column({ space: 12 }) {
      this.CardTitle('数据缓存', '本机处理')
      Text('截图 OCR 和粘贴文本只用于本机规则匹配和待确认账单生成，不上传服务器。确认入账后会清除该条待确认缓存；你也可以一键清空全部自动识别缓存。')
        .fontSize(13)
        .fontColor(AppColors.MUTED)
        .lineHeight(22)
        .width('100%')
      Row({ space: 10 }) {
        this.ActionButton('清空识别缓存', AppColors.EXPENSE, '#FCE9E4', () => this.clearCache())
        this.ActionButton('刷新状态', AppColors.CHART_BLUE, AppColors.SURFACE_TINT, () => this.loadAll())
      }
      .width('100%')
    }
    .width('100%')
    .padding(20)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 20, color: AppColors.SHADOW, offsetY: 8 })
  }

  @Builder
  private ToggleRow(title: string, subtitle: string, enabled: boolean, onClick: () => void) {
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
          .maxLines(2)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Text(enabled ? '开' : '关')
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(enabled ? AppColors.SURFACE : AppColors.MUTED)
        .width(52)
        .height(32)
        .textAlign(TextAlign.Center)
        .backgroundColor(enabled ? AppColors.CHART_BLUE : AppColors.SURFACE_SOFT)
        .borderRadius(AppRadius.PILL)
        .onClick(onClick)
    }
    .width('100%')
    .padding(14)
    .backgroundColor(AppColors.SURFACE_SOFT)
    .borderRadius(18)
  }

  @Builder
  private RuleFormCard() {
    Column({ space: 14 }) {
      this.CardTitle('新增规则', this.ruleType === AutoRuleType.BLACKLIST ? '黑名单' : '分类')
      Row({ space: 8 }) {
        this.RuleTypeButton('分类规则', AutoRuleType.CATEGORY)
        this.RuleTypeButton('黑名单', AutoRuleType.BLACKLIST)
      }
      .height(46)
      .padding(4)
      .backgroundColor('#E7EAEE')
      .borderRadius(AppRadius.PILL)

      TextInput({ text: this.ruleKeyword, placeholder: this.ruleType === AutoRuleType.BLACKLIST ? '如：验证码|广告|还款提醒' : '如：餐饮|奶茶|外卖' })
        .height(50)
        .fontSize(15)
        .backgroundColor(AppColors.SURFACE_SOFT)
        .borderRadius(18)
        .padding({ left: 16, right: 16 })
        .onChange((value: string) => {
          this.ruleKeyword = value;
        })

      if (this.ruleType === AutoRuleType.CATEGORY) {
        Row({ space: 8 }) {
          this.RecordTypeButton('支出', RecordType.EXPENSE)
          this.RecordTypeButton('收入', RecordType.INCOME)
        }
        .height(42)
        .width('100%')

        Scroll() {
          Row({ space: 8 }) {
            ForEach(this.filteredCategories(), (item: CategoryModel) => {
              this.CategoryChip(item)
            }, (item: CategoryModel) => `${item.id}`)
          }
          .height(42)
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .height(46)
      }

      Button('保存规则')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.SURFACE)
        .height(48)
        .width('100%')
        .backgroundColor(AppColors.CHART_BLUE)
        .borderRadius(AppRadius.PILL)
        .onClick(() => this.saveRule())
    }
    .width('100%')
    .padding(20)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 20, color: AppColors.SHADOW, offsetY: 8 })
  }

  @Builder
  private RuleListCard() {
    Column({ space: 12 }) {
      this.CardTitle('识别规则', `${this.rules.length} 条`)
      if (this.rules.length === 0) {
        this.EmptyState('暂无规则', '新增关键词后会自动归类或过滤')
      } else {
        ForEach(this.rules, (item: AutoRuleModel) => {
          this.RuleRow(item)
        }, (item: AutoRuleModel) => `${item.id}`)
      }
    }
    .width('100%')
  }

  @Builder
  private RuleRow(item: AutoRuleModel) {
    Row({ space: 12 }) {
      Text(item.ruleType === AutoRuleType.BLACKLIST ? '屏' : '归')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(item.ruleType === AutoRuleType.BLACKLIST ? AppColors.EXPENSE : AppColors.CHART_GREEN)
        .width(42)
        .height(42)
        .textAlign(TextAlign.Center)
        .backgroundColor(item.ruleType === AutoRuleType.BLACKLIST ? '#FCE9E4' : '#E6F7EF')
        .borderRadius(16)
      Column({ space: 4 }) {
        Text(item.keyword)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .maxLines(1)
        Text(item.ruleType === AutoRuleType.BLACKLIST ? '黑名单过滤' : `${this.typeMark(item.recordType)} · ${item.categoryName || '未分类'}`)
          .fontSize(12)
          .fontColor(AppColors.MUTED)
          .maxLines(1)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Button('删')
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.EXPENSE)
        .width(42)
        .height(36)
        .backgroundColor('#FCE9E4')
        .borderRadius(18)
        .onClick(() => this.deleteRule(item))
    }
    .width('100%')
    .height(72)
    .padding({ left: 16, right: 14 })
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 16, color: AppColors.SHADOW, offsetY: 6 })
  }

  @Builder
  private RuleTypeButton(label: string, type: AutoRuleType) {
    Text(label)
      .fontSize(13)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.ruleType === type ? AppColors.INK : AppColors.MUTED)
      .height(38)
      .layoutWeight(1)
      .textAlign(TextAlign.Center)
      .backgroundColor(this.ruleType === type ? AppColors.SURFACE : '#00000000')
      .borderRadius(AppRadius.PILL)
      .onClick(() => {
        this.ruleType = type;
      })
  }

  @Builder
  private RecordTypeButton(label: string, type: RecordType.EXPENSE | RecordType.INCOME) {
    Text(label)
      .fontSize(13)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.ruleRecordType === type ? AppColors.SURFACE : AppColors.INK)
      .height(38)
      .layoutWeight(1)
      .textAlign(TextAlign.Center)
      .backgroundColor(this.ruleRecordType === type ? AppColors.CHART_BLUE : AppColors.SURFACE_SOFT)
      .borderRadius(AppRadius.PILL)
      .onClick(() => {
        this.ruleRecordType = type;
        this.pickFirstCategory();
      })
  }

  @Builder
  private CategoryChip(item: CategoryModel) {
    Text(item.name)
      .fontSize(13)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.selectedCategoryId === item.id ? AppColors.SURFACE : AppColors.INK)
      .height(38)
      .padding({ left: 14, right: 14 })
      .backgroundColor(this.selectedCategoryId === item.id ? item.color : AppColors.SURFACE_SOFT)
      .borderRadius(AppRadius.PILL)
      .onClick(() => {
        this.selectedCategoryId = item.id || 0;
      })
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
  private EmptyState(title: string, subtitle: string) {
    Column({ space: 8 }) {
      Text(title)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.INK)
      Text(subtitle)
        .fontSize(13)
        .fontColor(AppColors.MUTED)
    }
    .width('100%')
    .height(138)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 18, color: AppColors.SHADOW, offsetY: 8 })
  }

  @Builder
  private ActionButton(label: string, color: string, bgColor: string, onClick: () => void) {
    Button(label)
      .fontSize(14)
      .fontWeight(FontWeight.Bold)
      .fontColor(color)
      .height(42)
      .layoutWeight(1)
      .backgroundColor(bgColor)
      .borderRadius(AppRadius.PILL)
      .onClick(onClick)
  }

  private async loadAll(): Promise<void> {
    try {
      await AppDatabase.getInstance().init(getContext(this));
      const service = AutoBookkeepingService.create(getContext(this));
      const settings = await this.settingsRepository.load(getContext(this));
      this.syncSettings(settings);
      this.categories = await this.categoryRepository.listAll();
      this.accounts = await this.accountRepository.list();
      this.rules = await service.listRules();
      this.pendingBills = await service.listPending(50, 0);
      this.pickFirstCategory();
      await AppState.getInstance().refreshPendingAutoBills();
    } catch (error) {
      ToastUtil.show('自动记账数据加载失败，请重试');
    }
  }

  private syncSettings(settings: AppSettingsData): void {
    this.themeMode = settings.themeMode;
    this.currencySymbol = settings.currencySymbol;
    this.autoEnabled = settings.autoBookkeepingEnabled;
    this.reviewEnabled = settings.autoReviewEnabled;
    this.defaultAccountId = settings.autoDefaultAccountId;
    this.alipayBillImportEnabled = settings.alipayBillImportEnabled;
  }

  private async saveSettings(): Promise<void> {
    const settings: AppSettingsData = {
      themeMode: this.themeMode,
      currencySymbol: this.currencySymbol,
      autoBookkeepingEnabled: this.autoEnabled,
      autoReviewEnabled: this.reviewEnabled,
      autoDefaultAccountId: this.defaultAccountId,
      alipayBillImportEnabled: this.alipayBillImportEnabled
    };
    await this.settingsRepository.save(getContext(this), settings);
    ToastUtil.show('自动记账设置已保存');
  }

  private async previewText(): Promise<void> {
    if (this.testText.trim().length === 0) {
      ToastUtil.show('先粘贴一条账单文字');
      return;
    }
    const result = await AutoBookkeepingService.create(getContext(this)).preview(this.testText);
    if (result.matched && result.bill) {
      this.previewSummary = `识别结果：${this.typeMark(result.bill.type)} ${NumberUtil.money(result.bill.amount)} · ${result.bill.categoryName || '未分类'} · ${result.bill.accountName || '默认账户'}`;
    } else {
      this.previewSummary = '未识别到账单，可能命中黑名单或缺少金额。';
    }
  }

  private async captureText(): Promise<void> {
    if (this.testText.trim().length === 0) {
      ToastUtil.show('先粘贴一条账单文字');
      return;
    }
    const result = await AutoBookkeepingService.create(getContext(this)).captureManualText(this.testText);
    if (result.matched) {
      ToastUtil.show('已加入待确认');
      this.testText = '';
      this.previewSummary = '';
      await this.loadAll();
    } else {
      ToastUtil.show('未识别到账单');
    }
  }

  private async pickAndRecognize(recordTime: number = 0): Promise<void> {
    if (this.ocrRecognizing) {
      return;
    }
    try {
      this.ocrRecognizing = true;
      const result = await OcrBookkeepingService.pickScreenshotAndRecognize();
      if (!result) {
        ToastUtil.show('未选择截图');
        return;
      }
      this.ocrText = result.text.trim();
      if (this.ocrText.length === 0) {
        this.ocrSummary = '未识别到文字，请换一张更清晰的账单截图';
        ToastUtil.show('未识别到文字');
        return;
      }
      const preview = await AutoBookkeepingService.create(getContext(this)).preview(this.ocrText);
      if (preview.matched && preview.bill) {
        this.ocrSummary = `识别结果：${this.typeMark(preview.bill.type)} ${NumberUtil.money(preview.bill.amount)} · ${preview.bill.categoryName || '未分类'} · ${preview.bill.accountName || '默认账户'}`;
      } else {
        this.ocrSummary = '已识别文字，但未解析到账单金额，可检查截图或补充规则';
      }
      ToastUtil.show('OCR 识别完成');
      if (recordTime > 0) {
        this.ocrRecordTime = recordTime;
      }
    } catch (error) {
      this.ocrText = '';
      this.ocrSummary = `${ToastUtil.error(error, 'OCR 识别失败')}。当前设备可能未开放本机 OCR 能力，可在“待确认”页粘贴账单文字继续识别。`;
      if (this.testText.trim().length === 0) {
        this.testText = '支付宝付款28.50元，商户奶茶店，商品说明奶茶，支付方式支付宝';
      }
      this.activeTab = AutoPageTab.PENDING;
      ToastUtil.show('OCR 不可用，已切到粘贴识别');
    } finally {
      this.ocrRecognizing = false;
    }
  }

  private async captureOcrText(): Promise<void> {
    if (this.ocrText.trim().length === 0) {
      ToastUtil.show('请先完成屏幕区域或截图识别');
      return;
    }
    const eventTime = this.ocrRecordTime > 0 ? this.ocrRecordTime : Date.now();
    const result = await AutoBookkeepingService.create(getContext(this)).captureOcrText(this.ocrText, eventTime);
    if (result.matched) {
      this.ocrText = '';
      this.ocrSummary = '';
      this.ocrRecordTime = 0;
      await this.loadAll();
      this.activeTab = AutoPageTab.PENDING;
      ToastUtil.show('已加入待确认');
    } else {
      ToastUtil.show('未识别到账单');
    }
  }

  private async confirm(item: AutoBillModel): Promise<void> {
    if (!item.id) {
      return;
    }
    await AutoBookkeepingService.create(getContext(this)).confirmPending(item.id);
    await AppState.getInstance().refreshAll();
    await this.loadAll();
    ToastUtil.show('已确认入账');
  }

  private toggleEditBill(item: AutoBillModel): void {
    if (!item.id) {
      return;
    }
    if (this.editingBillId === item.id) {
      this.cancelPendingEdit();
      return;
    }
    this.editingBillId = item.id;
    this.editingAmountText = `${item.amount}`;
    this.editingType = item.type;
    this.editingCategoryId = item.categoryId;
    this.editingAccountId = item.accountId;
    this.editingRemark = item.remark || '';
    this.ensureEditingCategory();
    this.ensureEditingAccount();
  }

  private cancelPendingEdit(): void {
    this.editingBillId = 0;
    this.editingAmountText = '';
    this.editingType = RecordType.EXPENSE;
    this.editingCategoryId = 0;
    this.editingAccountId = 0;
    this.editingRemark = '';
  }

  private async savePendingEdit(item: AutoBillModel): Promise<void> {
    if (!item.id) {
      return;
    }
    const amount = NumberUtil.toCentSafe(this.editingAmountText);
    if (!amount || amount <= 0) {
      ToastUtil.show('请填写正确金额');
      return;
    }
    this.ensureEditingCategory();
    this.ensureEditingAccount();
    if (this.editingCategoryId <= 0 || this.editingAccountId <= 0) {
      ToastUtil.show('请选择分类和账户');
      return;
    }
    const updated: AutoBillModel = {
      id: item.id,
      source: item.source,
      bundleName: item.bundleName,
      appName: item.appName,
      title: item.title,
      content: item.content,
      rawText: item.rawText,
      amount,
      type: this.editingType,
      categoryId: this.editingCategoryId,
      accountId: this.editingAccountId,
      recordTime: item.recordTime,
      remark: this.editingRemark.trim(),
      confidence: item.confidence,
      matchedRule: item.matchedRule,
      status: item.status,
      createTime: item.createTime,
      updateTime: Date.now()
    };
    await AutoBookkeepingService.create(getContext(this)).updatePending(updated);
    this.cancelPendingEdit();
    await this.loadAll();
    ToastUtil.show('待确认账单已修改');
  }

  private async discard(item: AutoBillModel): Promise<void> {
    if (!item.id) {
      return;
    }
    await AutoBookkeepingService.create(getContext(this)).discardPending(item.id);
    if (this.editingBillId === item.id) {
      this.cancelPendingEdit();
    }
    await this.loadAll();
    ToastUtil.show('已忽略');
  }

  private async clearCache(): Promise<void> {
    await AutoBookkeepingService.create(getContext(this)).clearCache();
    await this.loadAll();
    ToastUtil.show('识别缓存已清空');
  }

  private async saveRule(): Promise<void> {
    if (this.ruleKeyword.trim().length === 0) {
      ToastUtil.show('请输入关键词');
      return;
    }
    if (this.ruleType === AutoRuleType.CATEGORY && this.selectedCategoryId <= 0) {
      ToastUtil.show('请选择分类');
      return;
    }
    const rule: AutoRuleModel = {
      ruleType: this.ruleType,
      keyword: this.ruleKeyword.trim(),
      recordType: this.ruleRecordType,
      categoryId: this.ruleType === AutoRuleType.BLACKLIST ? 0 : this.selectedCategoryId,
      enabled: true,
      sortOrder: this.rules.length + 1,
      createTime: Date.now(),
      updateTime: Date.now()
    };
    await AutoBookkeepingService.create(getContext(this)).saveRule(rule);
    this.ruleKeyword = '';
    await this.loadAll();
    ToastUtil.show('规则已保存');
  }

  private async deleteRule(item: AutoRuleModel): Promise<void> {
    if (!item.id) {
      return;
    }
    await AutoBookkeepingService.create(getContext(this)).deleteRule(item.id);
    await this.loadAll();
    ToastUtil.show('规则已删除');
  }

  private readLaunchParams(): void {
    const params = router.getParams() as AutoBookkeepingParams;
    const action = `${params?.launchAction || ''}`;
    const recordTime = Number(params?.recordTime || 0);
    if (action !== 'screenOcr' && action !== 'galleryOcr') {
      return;
    }
    this.pendingLaunchAction = 'galleryOcr';
    this.pendingLaunchRecordTime = recordTime;
    this.ocrRecordTime = recordTime > 0 ? recordTime : 0;
    this.activeTab = AutoPageTab.OCR;
    this.launchPromptVisible = true;
  }

  private handleLaunchAction(): void {
    if (this.launchActionHandled) {
      return;
    }
    if (this.pendingLaunchAction !== 'galleryOcr') {
      return;
    }
    this.launchActionHandled = true;
    this.activeTab = AutoPageTab.OCR;
    ToastUtil.show('已进入日历识别，可点击开始识别账单');
    setTimeout(() => {
      this.startPendingLaunchAction();
    }, 600);
  }

  private async startPendingLaunchAction(): Promise<void> {
    const action = this.pendingLaunchAction;
    const recordTime = this.pendingLaunchRecordTime;
    if (action !== 'galleryOcr') {
      ToastUtil.show('请先从日历进入识别账单');
      return;
    }
    await this.pickAndRecognize(recordTime);
  }

  private launchRecordDateLabel(): string {
    const date = new Date(this.pendingLaunchRecordTime > 0 ? this.pendingLaunchRecordTime : Date.now());
    return `${date.getMonth() + 1}月${date.getDate()}日`;
  }

  private filteredCategories(): CategoryModel[] {
    return this.categories.filter((item: CategoryModel) => item.type === this.ruleRecordType);
  }

  private pickFirstCategory(): void {
    if (this.selectedCategoryId > 0 && this.filteredCategories().some((item: CategoryModel) => item.id === this.selectedCategoryId)) {
      return;
    }
    const first = this.filteredCategories()[0];
    this.selectedCategoryId = first ? first.id || 0 : 0;
  }

  private editingCategories(): CategoryModel[] {
    return this.categories.filter((item: CategoryModel) => item.type === this.editingType);
  }

  private ensureEditingCategory(): void {
    const list = this.editingCategories();
    if (this.editingCategoryId > 0 && list.some((item: CategoryModel) => item.id === this.editingCategoryId)) {
      return;
    }
    const first = list[0];
    this.editingCategoryId = first ? first.id || 0 : 0;
  }

  private ensureEditingAccount(): void {
    if (this.editingAccountId > 0 && this.accounts.some((item: AccountModel) => item.id === this.editingAccountId)) {
      return;
    }
    const first = this.accounts[0];
    this.editingAccountId = first ? first.id || 0 : 0;
  }

  private normalizeAmount(value: string): string {
    return NumberUtil.normalizeAmountInput(value);
  }

  private typeMark(type: RecordType.EXPENSE | RecordType.INCOME): string {
    return type === RecordType.INCOME ? '收入' : '支出';
  }

  private sourceLabel(source: string): string {
    return '手动';
  }

  private sourceSummary(): string {
    return '截图 OCR';
  }

  private isWide(): boolean {
    return this.viewportWidth >= Breakpoints.WIDE;
  }
}
