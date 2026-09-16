import { router } from '@kit.ArkUI';
import { AppDatabase } from '../database/AppDatabase';
import { AccountModel, AccountType } from '../model/Account';
import { RecordListItem, RecordType } from '../model/Record';
import { RecordTemplateModel } from '../model/RecordTemplate';
import { AccountRepository } from '../repository/AccountRepository';
import { LedgerEnhancementData, LedgerEnhancementRepository } from '../repository/LedgerEnhancementRepository';
import { RecordRepository } from '../repository/RecordRepository';
import { RecordTemplateRepository } from '../repository/RecordTemplateRepository';
import { AppColors, AppRadius, AppSpace, Breakpoints, LayoutSizes } from '../constants/DesignSystem';
import { ROUTES } from '../constants/RouteConstants';
import { DateUtil } from '../utils/DateUtil';
import { NumberUtil } from '../utils/NumberUtil';
import { ToastUtil } from '../utils/ToastUtil';

class EnhanceMetric {
  label: string = '';
  value: string = '';
  color: string = AppColors.INK;
  bgColor: string = AppColors.SURFACE_SOFT;

  constructor(label: string, value: string, color: string, bgColor: string) {
    this.label = label;
    this.value = value;
    this.color = color;
    this.bgColor = bgColor;
  }
}

@Entry
@Component
struct LedgerEnhance {
  private repository: LedgerEnhancementRepository = new LedgerEnhancementRepository();
  private recordRepository: RecordRepository = new RecordRepository();
  private accountRepository: AccountRepository = new AccountRepository();
  private templateRepository: RecordTemplateRepository = new RecordTemplateRepository();

  @State viewportWidth: number = 0;
  @State data: LedgerEnhancementData = new LedgerEnhancementData();
  @State activeLedger: string = '日常账本';
  @State ledgerText: string = '日常账本,家庭账本,旅行账本,装修账本';
  @State tagText: string = '报销,旅行,装修,家庭,宝宝';
  @State defaultTagText: string = '';
  @State savingNameText: string = '存钱目标';
  @State savingTargetText: string = '';
  @State savingSavedText: string = '';
  @State reimburseKeywordText: string = '报销';
  @State anomalyThresholdText: string = '500';
  @State creditBillDayText: string = '1';
  @State creditRepayDayText: string = '20';
  @State monthRecords: RecordListItem[] = [];
  @State recentRecords: RecordListItem[] = [];
  @State accounts: AccountModel[] = [];
  @State templates: RecordTemplateModel[] = [];
  @State templateCount: number = 0;
  @State ledgerEditorVisible: boolean = false;
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
          this.HeroCard()
          this.RecentBillsCard()
          this.LedgerCard()
          this.TagCard()
          this.SavingCard()
          this.ReimburseCard()
          this.CreditCard()
          this.AnomalyCard()
          this.TemplateCard()
          this.ImportCard()
        }
        .width('100%')
        .constraintSize({ maxWidth: this.contentMaxWidth() })
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
        Text('账本增强')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .width('100%')
        Text('账本、标签、目标和账单检查')
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
  private HeroCard() {
    Column({ space: 16 }) {
      Row() {
        Text('增')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.CHART_BLUE)
          .width(50)
          .height(50)
          .textAlign(TextAlign.Center)
          .borderRadius(18)
          .backgroundColor(AppColors.softBlue())
        Blank()
        Text(this.activeLedger)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.LEDGER)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor(AppColors.SURFACE_TINT)
          .borderRadius(AppRadius.PILL)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .constraintSize({ maxWidth: 180 })
      }
      .width('100%')

      Text('让账单更好查、更好复盘')
        .fontSize(this.isPhone() ? 28 : 34)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.INK)
        .width('100%')
        .maxLines(2)
      Text('把日常、家庭、旅行等收支分开记录，查看时只保留当前账本的数据。')
        .fontSize(13)
        .fontColor(AppColors.MUTED)
        .lineHeight(21)
        .width('100%')

      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
        ForEach(this.heroMetrics(), (item: EnhanceMetric) => {
          this.MetricBox(item)
        }, (item: EnhanceMetric) => item.label)
      }
      .width('100%')
    }
    .width('100%')
    .padding(18)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 24, color: AppColors.SHADOW, offsetY: 10 })
  }

  @Builder
  private RecentBillsCard() {
    Column({ space: 12 }) {
      this.CardTitle('最近账单', `${this.activeLedger} · ${this.recentRecords.length} 笔`)
      if (this.recentRecords.length === 0) {
        this.EmptyText('还没有账单，点击“记一笔”记录第一笔收支。')
      } else {
        ForEach(this.recentRecords.slice(0, 8), (item: RecordListItem) => {
          this.RecentBillRow(item)
        }, (item: RecordListItem) => `recent-${item.id}`)
      }
      this.PrimaryButton('去记一笔', () => router.pushUrl({ url: ROUTES.RECORD_EDIT }))
    }
    .width('100%')
    .padding(16)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 20, color: AppColors.SHADOW, offsetY: 8 })
  }

  @Builder
  private LedgerCard() {
    Column({ space: 12 }) {
      this.CardTitle('多账本', `${this.data.ledgers.length} 个账本`)
      Text('首页顶部可查看全部账本或切换单个账本。这里选择的账本会作为记一笔时的默认归属。')
        .fontSize(12)
        .fontColor(AppColors.MUTED)
        .lineHeight(19)
        .width('100%')

      Column({ space: 8 }) {
        ForEach(this.data.ledgers, (item: string) => {
          this.LedgerOption(item, this.activeLedger === item)
        }, (item: string) => `${item}-${this.activeLedger === item ? 'selected' : 'idle'}`)
      }
      .width('100%')

      if (this.ledgerEditorVisible) {
        Column({ space: 10 }) {
          TextInput({ text: this.ledgerText, placeholder: '用逗号分隔，如 日常账本,家庭账本' })
            .height(46)
            .fontSize(14)
            .fontColor(AppColors.INK)
            .backgroundColor(AppColors.SURFACE_SOFT)
            .border({ width: 1, color: AppColors.LINE })
            .borderRadius(14)
            .padding({ left: 14, right: 14 })
            .onChange((value: string) => {
              this.ledgerText = value;
            })
          Row({ space: 8 }) {
            Button('取消')
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.MUTED)
              .height(38)
              .width(78)
              .backgroundColor(AppColors.SURFACE_SOFT)
              .borderRadius(AppRadius.PILL)
              .onClick(() => {
                this.ledgerEditorVisible = false;
                this.ledgerText = this.data.ledgers.join(',');
              })
            Button('保存账本列表')
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
              .height(38)
              .layoutWeight(1)
              .backgroundColor(AppColors.CHART_BLUE)
              .borderRadius(AppRadius.PILL)
              .onClick(() => this.saveLedgers())
          }
          .width('100%')
        }
        .width('100%')
        .padding(12)
        .backgroundColor(AppColors.PANEL)
        .border({ width: 1, color: AppColors.LINE })
        .borderRadius(16)
      } else {
        Button('编辑账本列表')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.CHART_BLUE)
          .height(40)
          .width('100%')
          .backgroundColor(AppColors.softBlue())
          .border({ width: 1, color: AppColors.LINE })
          .borderRadius(AppRadius.PILL)
          .onClick(() => {
            this.ledgerText = this.data.ledgers.join(',');
            this.ledgerEditorVisible = true;
          })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 20, color: AppColors.SHADOW, offsetY: 8 })
  }

  @Builder
  private TagCard() {
    Column({ space: 12 }) {
      this.CardTitle('标签 / 项目', '备注中会追加默认标签')
      TextInput({ text: this.tagText, placeholder: '报销,旅行,装修,宝宝' })
        .height(48)
        .fontSize(14)
        .fontColor(AppColors.INK)
        .backgroundColor(AppColors.SURFACE_SOFT)
        .borderRadius(16)
        .padding({ left: 14, right: 14 })
        .onChange((value: string) => {
          this.tagText = value;
        })
      TextInput({ text: this.defaultTagText, placeholder: '默认标签，可留空，如 报销,旅行' })
        .height(48)
        .fontSize(14)
        .fontColor(AppColors.INK)
        .backgroundColor(AppColors.SURFACE_SOFT)
        .borderRadius(16)
        .padding({ left: 14, right: 14 })
        .onChange((value: string) => {
          this.defaultTagText = value;
        })
      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
        ForEach(this.data.tags, (item: string) => {
          this.TagChip(item)
        }, (item: string) => item)
      }
      .width('100%')
      this.PrimaryButton('保存标签设置', () => this.saveTags())
    }
    .width('100%')
    .padding(16)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 20, color: AppColors.SHADOW, offsetY: 8 })
  }

  @Builder
  private SavingCard() {
    Column({ space: 12 }) {
      this.CardTitle('存钱目标', `${this.savingProgress()}%`)
      Row({ space: 10 }) {
        TextInput({ text: this.savingNameText, placeholder: '目标名称' })
          .height(48)
          .fontSize(14)
          .fontColor(AppColors.INK)
          .layoutWeight(1)
          .backgroundColor(AppColors.SURFACE_SOFT)
          .borderRadius(16)
          .padding({ left: 14, right: 14 })
          .onChange((value: string) => {
            this.savingNameText = value;
          })
      }
      Row({ space: 10 }) {
        TextInput({ text: this.savingTargetText, placeholder: '目标金额' })
          .type(InputType.NUMBER_DECIMAL)
          .height(48)
          .fontSize(15)
          .fontColor(AppColors.INK)
          .layoutWeight(1)
          .backgroundColor(AppColors.SURFACE_SOFT)
          .borderRadius(16)
          .padding({ left: 14, right: 14 })
          .onChange((value: string) => {
            this.savingTargetText = NumberUtil.normalizeAmountInput(value);
          })
        TextInput({ text: this.savingSavedText, placeholder: '已存' })
          .type(InputType.NUMBER_DECIMAL)
          .height(48)
          .fontSize(15)
          .fontColor(AppColors.INK)
          .layoutWeight(1)
          .backgroundColor(AppColors.SURFACE_SOFT)
          .borderRadius(16)
          .padding({ left: 14, right: 14 })
          .onChange((value: string) => {
            this.savingSavedText = NumberUtil.normalizeAmountInput(value);
          })
      }
      .width('100%')
      Progress({ value: this.savingProgress(), total: 100, type: ProgressType.Linear })
        .height(8)
        .color(AppColors.CHART_GREEN)
        .backgroundColor(AppColors.TRACK)
        .borderRadius(4)
      Text(this.savingHint())
        .fontSize(13)
        .fontColor(AppColors.MUTED)
        .lineHeight(20)
        .width('100%')
      this.PrimaryButton('保存目标', () => this.saveSaving())
    }
    .width('100%')
    .padding(16)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 20, color: AppColors.SHADOW, offsetY: 8 })
  }

  @Builder
  private ReimburseCard() {
    Column({ space: 12 }) {
      this.CardTitle('退款 / 报销追踪', this.reimburseStatus())
      TextInput({ text: this.reimburseKeywordText, placeholder: '关键词，如 报销、退款、垫付' })
        .height(48)
        .fontSize(14)
        .fontColor(AppColors.INK)
        .backgroundColor(AppColors.SURFACE_SOFT)
        .borderRadius(16)
        .padding({ left: 14, right: 14 })
        .onChange((value: string) => {
          this.reimburseKeywordText = value;
        })
      Row({ space: 10 }) {
        this.SmallMetric('待回收', NumberUtil.compactMoney(this.pendingReimburse()), AppColors.EXPENSE, AppColors.softDanger())
        this.SmallMetric('已收到', NumberUtil.compactMoney(this.receivedReimburse()), AppColors.INCOME, AppColors.softGreen())
      }
      .width('100%')
      this.PrimaryButton('保存关键词', () => this.saveReimburse())
    }
    .width('100%')
    .padding(16)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 20, color: AppColors.SHADOW, offsetY: 8 })
  }

  @Builder
  private CreditCard() {
    Column({ space: 12 }) {
      this.CardTitle('信用卡账单日', `${this.creditAccounts().length} 张负债卡`)
      Row({ space: 10 }) {
        TextInput({ text: this.creditBillDayText, placeholder: '账单日' })
          .type(InputType.NUMBER_DECIMAL)
          .height(48)
          .fontSize(15)
          .fontColor(AppColors.INK)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .backgroundColor(AppColors.SURFACE_SOFT)
          .borderRadius(16)
          .onChange((value: string) => {
            this.creditBillDayText = value.replace(/[^0-9]/g, '');
          })
        TextInput({ text: this.creditRepayDayText, placeholder: '还款日' })
          .type(InputType.NUMBER_DECIMAL)
          .height(48)
          .fontSize(15)
          .fontColor(AppColors.INK)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .backgroundColor(AppColors.SURFACE_SOFT)
          .borderRadius(16)
          .onChange((value: string) => {
            this.creditRepayDayText = value.replace(/[^0-9]/g, '');
          })
      }
      .width('100%')
      if (this.creditAccounts().length === 0) {
        this.EmptyText('在账户管理里把信用卡设置为负债账户后，这里会展示还款提醒。')
      } else {
        ForEach(this.creditAccounts(), (item: AccountModel) => {
          this.CreditAccountRow(item)
        }, (item: AccountModel) => `${item.id}`)
      }
      this.PrimaryButton('保存还款日期', () => this.saveCredit())
    }
    .width('100%')
    .padding(16)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 20, color: AppColors.SHADOW, offsetY: 8 })
  }

  @Builder
  private AnomalyCard() {
    Column({ space: 12 }) {
      this.CardTitle('异常账单检查', `${this.anomalyRecords().length} 条`)
      Row({ space: 10 }) {
        TextInput({ text: this.anomalyThresholdText, placeholder: '大额阈值' })
          .type(InputType.NUMBER_DECIMAL)
          .height(48)
          .fontSize(15)
          .fontColor(AppColors.INK)
          .layoutWeight(1)
          .backgroundColor(AppColors.SURFACE_SOFT)
          .borderRadius(16)
          .padding({ left: 14, right: 14 })
          .onChange((value: string) => {
            this.anomalyThresholdText = NumberUtil.normalizeAmountInput(value);
          })
        Button('保存')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.SURFACE)
          .height(48)
          .width(92)
          .backgroundColor(AppColors.CHART_BLUE)
          .borderRadius(AppRadius.PILL)
          .onClick(() => this.saveAnomaly())
      }
      .width('100%')
      if (this.anomalyRecords().length === 0) {
        this.EmptyText('本月没有发现大额、无备注或疑似重复账单。')
      } else {
        ForEach(this.anomalyRecords().slice(0, 6), (item: RecordListItem) => {
          this.AnomalyRow(item)
        }, (item: RecordListItem) => `${item.id}`)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 20, color: AppColors.SHADOW, offsetY: 8 })
  }

  @Builder
  private TemplateCard() {
    Column({ space: 12 }) {
      this.CardTitle('快捷模板', `全部账本通用 · 共 ${this.templateCount} 个`)
      if (this.templates.length === 0) {
        this.EmptyText('在记一笔页面保存常用账单，就能一键套用早餐、地铁、房租、工资等模板。')
      } else {
        ForEach(this.templates.slice(0, 6), (item: RecordTemplateModel) => {
          this.TemplateRow(item)
        }, (item: RecordTemplateModel) => `${item.id}`)
      }
      this.PrimaryButton('去记一笔并保存模板', () => router.pushUrl({ url: ROUTES.RECORD_EDIT }))
    }
    .width('100%')
    .padding(16)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 20, color: AppColors.SHADOW, offsetY: 8 })
  }

  @Builder
  private ImportCard() {
    Column({ space: 12 }) {
      this.CardTitle('账单导入模板', '手动选择文件')
      Text('支持一页账 CSV，也兼容常见微信、支付宝导出表头：交易时间、收支、交易金额、商品说明、交易对方等字段。导入仍由用户手动选择文件，不做后台抓取。')
        .fontSize(13)
        .fontColor(AppColors.MUTED)
        .lineHeight(21)
        .width('100%')
      this.PrimaryButton('去数据导入 / 导出', () => router.pushUrl({ url: ROUTES.DATA_EXPORT }))
    }
    .width('100%')
    .padding(16)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 20, color: AppColors.SHADOW, offsetY: 8 })
  }

  @Builder
  private CardTitle(title: string, badge: string) {
    Row() {
      Text(title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.INK)
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(badge)
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.LEDGER)
        .padding({ left: 10, right: 10, top: 5, bottom: 5 })
        .backgroundColor(AppColors.SURFACE_TINT)
        .borderRadius(AppRadius.PILL)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .constraintSize({ maxWidth: this.isPhone() ? 138 : 220 })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  private MetricBox(item: EnhanceMetric) {
    Column({ space: 4 }) {
      Text(item.label)
        .fontSize(12)
        .fontColor(AppColors.MUTED)
        .maxLines(1)
      Text(item.value)
        .fontSize(this.metricFontSize(item.value))
        .fontWeight(FontWeight.Bold)
        .fontColor(item.color)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width(this.isPhone() ? '48%' : '23%')
    .height(68)
    .padding(12)
    .margin({ bottom: 8 })
    .backgroundColor(item.bgColor)
    .borderRadius(16)
  }

  @Builder
  private SmallMetric(label: string, value: string, color: string, bgColor: string) {
    Column({ space: 4 }) {
      Text(label)
        .fontSize(12)
        .fontColor(AppColors.MUTED)
      Text(value)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .layoutWeight(1)
    .height(72)
    .padding(12)
    .backgroundColor(bgColor)
    .borderRadius(16)
  }

  @Builder
  private LedgerOption(label: string, selected: boolean) {
    Row({ space: 10 }) {
      Text(selected ? '✓' : label.substring(0, 1))
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(selected ? '#FFFFFF' : AppColors.CHART_BLUE)
        .width(32)
        .height(32)
        .textAlign(TextAlign.Center)
        .backgroundColor(selected ? AppColors.CHART_BLUE : AppColors.softBlue())
        .borderRadius(16)
      Column({ space: 2 }) {
        Text(label)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        Text(selected ? '首页、统计和新账单正在使用' : '点击切换到这个账本')
          .fontSize(11)
          .fontColor(selected ? AppColors.CHART_BLUE : AppColors.MUTED)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Text(selected ? '当前' : '切换')
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor(selected ? AppColors.CHART_BLUE : AppColors.MUTED)
        .padding({ left: 10, right: 10, top: 5, bottom: 5 })
        .backgroundColor(selected ? AppColors.softBlue() : AppColors.SURFACE_SOFT)
        .borderRadius(AppRadius.PILL)
    }
    .width('100%')
    .height(58)
    .padding({ left: 12, right: 12 })
    .backgroundColor(selected ? AppColors.SURFACE_TINT : AppColors.SURFACE_SOFT)
    .border({ width: selected ? 2 : 1, color: selected ? AppColors.CHART_BLUE : AppColors.LINE })
    .borderRadius(16)
    .onClick(() => this.switchLedger(label))
  }

  @Builder
  private TagChip(label: string) {
    Text(`#${label}`)
      .fontSize(13)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.data.defaultTags.indexOf(label) >= 0 ? AppColors.SURFACE : AppColors.LEDGER)
      .padding({ left: 12, right: 12, top: 7, bottom: 7 })
      .backgroundColor(this.data.defaultTags.indexOf(label) >= 0 ? AppColors.CHART_BLUE : AppColors.SURFACE_TINT)
      .borderRadius(AppRadius.PILL)
      .margin({ right: 8, bottom: 8 })
      .onClick(() => this.toggleDefaultTag(label))
  }

  @Builder
  private CreditAccountRow(item: AccountModel) {
    Row({ space: 10 }) {
      Text(item.name.substring(0, 1))
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.EXPENSE)
        .width(38)
        .height(38)
        .textAlign(TextAlign.Center)
        .borderRadius(19)
        .backgroundColor(AppColors.softDanger())
      Column({ space: 3 }) {
        Text(item.name)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        Text(`账单日 ${this.data.creditBillDay} 日，还款日 ${this.data.creditRepayDay} 日`)
          .fontSize(12)
          .fontColor(AppColors.MUTED)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Text(NumberUtil.compactMoney(item.balance))
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.EXPENSE)
        .constraintSize({ maxWidth: 110 })
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding(12)
    .backgroundColor(AppColors.SURFACE_SOFT)
    .borderRadius(16)
  }

  @Builder
  private AnomalyRow(item: RecordListItem) {
    Row({ space: 10 }) {
      Text('!')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.WARNING)
        .width(34)
        .height(34)
        .textAlign(TextAlign.Center)
        .borderRadius(17)
        .backgroundColor(AppColors.softYellow())
      Column({ space: 3 }) {
        Text(`${item.categoryName} · ${DateUtil.shortDay(item.recordTime)}`)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        Text(this.anomalyReason(item))
          .fontSize(12)
          .fontColor(AppColors.MUTED)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Text(NumberUtil.compactMoney(item.amount))
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.EXPENSE)
        .constraintSize({ maxWidth: 96 })
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding(12)
    .backgroundColor(AppColors.SURFACE_SOFT)
    .borderRadius(16)
    .onClick(() => router.pushUrl({ url: ROUTES.RECORD_DETAIL, params: { recordId: item.id || 0 } }))
  }

  @Builder
  private TemplateRow(item: RecordTemplateModel) {
    Row({ space: 10 }) {
      Text(item.name.substring(0, 1))
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(item.type === RecordType.EXPENSE ? AppColors.EXPENSE : AppColors.INCOME)
        .width(36)
        .height(36)
        .textAlign(TextAlign.Center)
        .borderRadius(18)
        .backgroundColor(item.type === RecordType.EXPENSE ? AppColors.softDanger() : AppColors.softGreen())
      Column({ space: 3 }) {
        Text(item.name)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        Text(`${item.categoryName || '分类'} · ${item.accountName || '账户'} · 使用 ${item.useCount} 次`)
          .fontSize(12)
          .fontColor(AppColors.MUTED)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Text(NumberUtil.compactMoney(item.amount))
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.INK)
        .constraintSize({ maxWidth: 96 })
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Button('使用模板')
        .fontSize(11)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .height(34)
        .width(76)
        .backgroundColor(AppColors.CHART_BLUE)
        .borderRadius(AppRadius.PILL)
        .onClick(() => this.openTemplate(item))
    }
    .width('100%')
    .padding(12)
    .backgroundColor(AppColors.SURFACE_SOFT)
    .borderRadius(16)
    .onClick(() => this.openTemplate(item))
  }

  @Builder
  private RecentBillRow(item: RecordListItem) {
    Row({ space: 10 }) {
      Text(item.type === RecordType.EXPENSE ? '支' : item.type === RecordType.INCOME ? '收' : '转')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(item.type === RecordType.EXPENSE ? AppColors.EXPENSE : item.type === RecordType.INCOME ? AppColors.INCOME : AppColors.CHART_BLUE)
        .width(36)
        .height(36)
        .textAlign(TextAlign.Center)
        .borderRadius(18)
        .backgroundColor(item.type === RecordType.EXPENSE ? AppColors.softDanger() : item.type === RecordType.INCOME ? AppColors.softGreen() : AppColors.softBlue())
      Column({ space: 3 }) {
        Text(`${item.categoryName || '账单'} · ${DateUtil.shortDay(item.recordTime)}`)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        Text(`${item.accountName || '账户'}${item.remark.trim().length > 0 ? ` · ${item.remark}` : ''}`)
          .fontSize(12)
          .fontColor(AppColors.MUTED)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Text(`${item.type === RecordType.INCOME ? '+' : item.type === RecordType.EXPENSE ? '-' : ''}${NumberUtil.compactMoney(item.amount)}`)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(item.type === RecordType.EXPENSE ? AppColors.EXPENSE : item.type === RecordType.INCOME ? AppColors.INCOME : AppColors.INK)
        .constraintSize({ maxWidth: 112 })
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding(12)
    .backgroundColor(AppColors.SURFACE_SOFT)
    .borderRadius(16)
    .onClick(() => router.pushUrl({ url: ROUTES.RECORD_DETAIL, params: { recordId: item.id || 0 } }))
  }

  @Builder
  private EmptyText(text: string) {
    Text(text)
      .fontSize(13)
      .fontColor(AppColors.MUTED)
      .lineHeight(20)
      .width('100%')
      .padding(12)
      .backgroundColor(AppColors.SURFACE_SOFT)
      .borderRadius(16)
  }

  @Builder
  private PrimaryButton(label: string, action: () => void) {
    Button(label)
      .fontSize(15)
      .fontWeight(FontWeight.Bold)
      .fontColor(AppColors.SURFACE)
      .height(46)
      .width('100%')
      .backgroundColor(AppColors.CHART_BLUE)
      .borderRadius(AppRadius.PILL)
      .onClick(action)
  }

  private async loadAll(): Promise<void> {
    try {
      await AppDatabase.getInstance().init(getContext(this));
    } catch (error) {
      ToastUtil.show('数据库初始化失败，请重新进入');
      return;
    }
    try {
      this.data = await this.repository.load(getContext(this));
      this.activeLedger = this.data.activeLedger.trim() || '日常账本';
      this.syncInputs();
    } catch (error) {
      ToastUtil.show('账本设置加载失败');
    }
    const activeLedger = this.activeLedger;
    try {
      const start = DateUtil.startOfMonth(Date.now());
      const end = DateUtil.startOfNextMonth(Date.now());
      this.monthRecords = await this.recordRepository.listByRangeAndLedger(start, end, activeLedger, 500, 0);
    } catch (error) {
      this.monthRecords = [];
      ToastUtil.show('本月账单加载失败');
    }
    try {
      this.recentRecords = await this.recordRepository.listRecentByLedger(activeLedger, 8, 0);
    } catch (error) {
      this.recentRecords = [];
      ToastUtil.show('最近账单加载失败');
    }
    try {
      this.accounts = await this.accountRepository.list();
    } catch (error) {
      this.accounts = [];
      ToastUtil.show('账户加载失败');
    }
    try {
      this.templateCount = await this.templateRepository.countAll();
      this.templates = await this.templateRepository.listAll(12);
    } catch (error) {
      this.templates = [];
      this.templateCount = 0;
      ToastUtil.show('账单模板加载失败');
    }
  }

  private async switchLedger(ledgerName: string): Promise<void> {
    if (this.activeLedger === ledgerName) {
      return;
    }
    this.activeLedger = ledgerName;
    this.data.activeLedger = ledgerName;
    this.data.homeLedgerFilter = ledgerName;
    await this.saveData(`已将“${ledgerName}”设为当前账本`);
  }

  private openTemplate(item: RecordTemplateModel): void {
    if (!item.id) {
      ToastUtil.show('模板无效');
      return;
    }
    router.pushUrl({ url: ROUTES.RECORD_EDIT, params: { templateId: item.id } });
  }

  private syncInputs(): void {
    this.ledgerText = this.data.ledgers.join(',');
    this.tagText = this.data.tags.join(',');
    this.defaultTagText = this.data.defaultTags.join(',');
    this.savingNameText = this.data.savingName;
    this.savingTargetText = this.data.savingTarget > 0 ? `${this.data.savingTarget}` : '';
    this.savingSavedText = this.data.savingSaved > 0 ? `${this.data.savingSaved}` : '';
    this.reimburseKeywordText = this.data.reimburseKeyword;
    this.anomalyThresholdText = `${this.data.anomalyThreshold}`;
    this.creditBillDayText = `${this.data.creditBillDay}`;
    this.creditRepayDayText = `${this.data.creditRepayDay}`;
  }

  private async saveData(message: string): Promise<void> {
    try {
      await this.repository.save(getContext(this), this.data);
      ToastUtil.show(message);
      await this.loadAll();
    } catch (error) {
      ToastUtil.show('保存失败，请重试');
    }
  }

  private saveLedgers(): void {
    this.data.ledgers = this.parseList(this.ledgerText, ['日常账本']);
    if (this.data.ledgers.indexOf(this.activeLedger) < 0) {
      this.data.activeLedger = this.data.ledgers[0];
      this.activeLedger = this.data.activeLedger;
    }
    if (this.data.homeLedgerFilter.length > 0 && this.data.ledgers.indexOf(this.data.homeLedgerFilter) < 0) {
      this.data.homeLedgerFilter = '';
    }
    this.ledgerEditorVisible = false;
    this.saveData('账本列表已保存');
  }

  private saveTags(): void {
    this.data.tags = this.parseList(this.tagText, []);
    this.data.defaultTags = this.parseList(this.defaultTagText, []);
    this.saveData('标签已保存');
  }

  private saveSaving(): void {
    this.data.savingName = this.savingNameText.trim() || '存钱目标';
    this.data.savingTarget = NumberUtil.toCentSafe(this.savingTargetText);
    this.data.savingSaved = NumberUtil.toCentSafe(this.savingSavedText);
    this.saveData('存钱目标已保存');
  }

  private saveReimburse(): void {
    this.data.reimburseKeyword = this.reimburseKeywordText.trim() || '报销';
    this.saveData('报销关键词已保存');
  }

  private saveCredit(): void {
    this.data.creditBillDay = this.parseDay(this.creditBillDayText, 1);
    this.data.creditRepayDay = this.parseDay(this.creditRepayDayText, 20);
    this.saveData('信用卡日期已保存');
  }

  private saveAnomaly(): void {
    this.data.anomalyThreshold = NumberUtil.toCentSafe(this.anomalyThresholdText) || 500;
    this.saveData('异常检查阈值已保存');
  }

  private toggleDefaultTag(label: string): void {
    const index = this.data.defaultTags.indexOf(label);
    if (index >= 0) {
      this.data.defaultTags.splice(index, 1);
    } else {
      this.data.defaultTags.push(label);
    }
    this.defaultTagText = this.data.defaultTags.join(',');
    this.saveData('默认标签已更新');
  }

  private heroMetrics(): EnhanceMetric[] {
    return [
      new EnhanceMetric('账本', `${this.data.ledgers.length} 个`, AppColors.CHART_BLUE, AppColors.softBlue()),
      new EnhanceMetric('标签', `${this.data.tags.length} 个`, AppColors.CHART_PURPLE, AppColors.softPurple()),
      new EnhanceMetric('本月支出', NumberUtil.compactMoney(this.monthExpense()), AppColors.EXPENSE, AppColors.softDanger()),
      new EnhanceMetric('异常', `${this.anomalyRecords().length} 条`, AppColors.WARNING, AppColors.softYellow())
    ];
  }

  private monthExpense(): number {
    return this.monthRecords
      .filter((item: RecordListItem) => item.type === RecordType.EXPENSE)
      .reduce((sum: number, item: RecordListItem) => sum + item.amount, 0);
  }

  private pendingReimburse(): number {
    const keyword = this.data.reimburseKeyword || '报销';
    return this.monthRecords
      .filter((item: RecordListItem) => item.type === RecordType.EXPENSE && this.containsAny(item, keyword))
      .reduce((sum: number, item: RecordListItem) => sum + item.amount, 0);
  }

  private receivedReimburse(): number {
    const keyword = this.data.reimburseKeyword || '报销';
    return this.monthRecords
      .filter((item: RecordListItem) => item.type === RecordType.INCOME && this.containsAny(item, `${keyword},退款`))
      .reduce((sum: number, item: RecordListItem) => sum + item.amount, 0);
  }

  private reimburseStatus(): string {
    const rest = Math.max(0, this.pendingReimburse() - this.receivedReimburse());
    return rest > 0 ? `待收 ${NumberUtil.compactMoney(rest)}` : '已平衡';
  }

  private creditAccounts(): AccountModel[] {
    return this.accounts.filter((item: AccountModel) => item.type === AccountType.CREDIT_CARD || item.isLiability);
  }

  private anomalyRecords(): RecordListItem[] {
    return this.monthRecords.filter((item: RecordListItem) => {
      return item.type === RecordType.EXPENSE &&
        (item.amount >= this.data.anomalyThreshold || item.remark.trim().length === 0 || this.hasSameDayDuplicate(item));
    });
  }

  private hasSameDayDuplicate(target: RecordListItem): boolean {
    return this.monthRecords.some((item: RecordListItem) => {
      return item.id !== target.id && item.type === target.type && item.categoryId === target.categoryId &&
        Math.abs(item.amount - target.amount) < 0.001 && DateUtil.dayKey(item.recordTime) === DateUtil.dayKey(target.recordTime);
    });
  }

  private anomalyReason(item: RecordListItem): string {
    if (item.amount >= this.data.anomalyThreshold) {
      return `超过 ${NumberUtil.compactMoney(this.data.anomalyThreshold)} 阈值`;
    }
    if (item.remark.trim().length === 0) {
      return '没有备注，可检查是否需要补充';
    }
    if (this.hasSameDayDuplicate(item)) {
      return '同日同分类同金额，疑似重复';
    }
    return '建议检查';
  }

  private containsAny(item: RecordListItem, keywords: string): boolean {
    const text = `${item.remark} ${item.categoryName}`;
    return this.parseList(keywords, []).some((keyword: string) => text.includes(keyword));
  }

  private savingProgress(): number {
    if (this.data.savingTarget <= 0) {
      return 0;
    }
    return Math.min(100, Math.round(this.data.savingSaved / this.data.savingTarget * 100));
  }

  private savingHint(): string {
    if (this.data.savingTarget <= 0) {
      return '设置目标金额后，可以按月检查结余是否在靠近目标。';
    }
    const rest = Math.max(0, this.data.savingTarget - this.data.savingSaved);
    return `${this.data.savingName} 还差 ${NumberUtil.compactMoney(rest)}，当前完成 ${this.savingProgress()}%。`;
  }

  private parseList(value: string, fallback: string[]): string[] {
    const result: string[] = [];
    value.split(/[，,]/).forEach((item: string) => {
      const normalized = item.replace(/#/g, '').trim();
      if (normalized.length > 0 && result.indexOf(normalized) < 0) {
        result.push(normalized);
      }
    });
    return result.length > 0 ? result : fallback;
  }

  private parseDay(value: string, fallback: number): number {
    const parsed = Number(value);
    if (Number.isNaN(parsed)) {
      return fallback;
    }
    return Math.min(31, Math.max(1, Math.round(parsed)));
  }

  private metricFontSize(value: string): number {
    if (value.length <= 6) {
      return 18;
    }
    if (value.length <= 9) {
      return 16;
    }
    return 14;
  }

  private isPhone(): boolean {
    return this.viewportWidth < Breakpoints.TABLET;
  }

  private contentMaxWidth(): number {
    return this.viewportWidth >= Breakpoints.DESKTOP ? LayoutSizes.CONTENT_MAX : LayoutSizes.CONTENT_COMPACT;
  }
}
