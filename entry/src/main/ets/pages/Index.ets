import { router } from '@kit.ArkUI';
import { AppState } from '../viewmodel/AppState';
import { AccountModel } from '../model/Account';
import { BudgetModel } from '../model/Budget';
import { RecordListItem } from '../model/Record';
import { AutoBookkeepingRepository } from '../repository/AutoBookkeepingRepository';
import { BudgetRepository } from '../repository/BudgetRepository';
import { RecordRepository } from '../repository/RecordRepository';
import { AppColors, AppRadius, AppSpace, Breakpoints, LayoutSizes } from '../constants/DesignSystem';
import { FeatureFlags } from '../constants/FeatureFlags';
import { ROUTES } from '../constants/RouteConstants';
import { DateUtil } from '../utils/DateUtil';
import { NumberUtil } from '../utils/NumberUtil';
import { RecordItem } from '../components/RecordItem';
import { StatisticsDashboard } from '../components/StatisticsDashboard';
import { SettingsRepository } from '../repository/SettingsRepository';
import { AppDatabase } from '../database/AppDatabase';
import { ThemeUtil } from '../utils/ThemeUtil';

@Entry
@Component
struct Index {
  private homeRecordRepository: RecordRepository = new RecordRepository();
  private homeBudgetRepository: BudgetRepository = new BudgetRepository();
  private settingsRepository: SettingsRepository = new SettingsRepository();

  @State currentTab: number = 0;
  @State statisticsRefreshKey: number = 0;
  @State appState: AppState = AppState.getInstance();
  @State viewportWidth: number = 0;
  @State userName: string = '账本';
  @State nowTime: number = Date.now();
  @State monthIncome: number = 0;
  @State monthExpense: number = 0;
  @State monthBalance: number = 0;
  @State todayIncome: number = 0;
  @State todayExpense: number = 0;
  @State todayBalance: number = 0;
  @State todayRecordCount: number = 0;
  @State monthBudget: number = 0;
  @State monthBudgetRemaining: number = 0;
  @State monthBudgetProgress: number = 0;
  @State pendingAutoBillCount: number = 0;
  @StorageLink('ledgerIsDarkMode') isDarkMode: boolean = false;
  private clockTimer: number = -1;

  aboutToAppear(): void {
    this.nowTime = Date.now();
    if (this.clockTimer >= 0) {
      clearInterval(this.clockTimer);
    }
    this.clockTimer = setInterval(() => {
      this.nowTime = Date.now();
    }, 60000);
    this.refresh();
  }

  onPageShow(): void {
    this.statisticsRefreshKey++;
    this.refresh();
  }

  aboutToDisappear(): void {
    if (this.clockTimer >= 0) {
      clearInterval(this.clockTimer);
      this.clockTimer = -1;
    }
  }

  build() {
    Tabs({ barPosition: BarPosition.End }) {
      TabContent() {
        this.HomeTab()
      }
      .tabBar(this.TabBarItem('明细', 0))

      TabContent() {
        this.StatisticsTab()
      }
      .tabBar(this.TabBarItem('统计', 1))

      TabContent() {
        this.AssetsTab()
      }
      .tabBar(this.TabBarItem('资产', 2))

      TabContent() {
        this.ProfileTab()
      }
      .tabBar(this.TabBarItem('我的', 3))
    }
    .barHeight(62)
    .backgroundColor(AppColors.CANVAS)
    .onChange((index: number) => {
      this.currentTab = index;
      if (index === 1) {
        this.statisticsRefreshKey++;
      }
      this.refresh();
    })
    .onAreaChange((oldValue, newValue) => {
      this.viewportWidth = parseFloat(`${newValue.width}`);
    })
  }

  @Builder
  private TabBarItem(label: string, index: number) {
    Column({ space: 4 }) {
      Text(this.tabMark(index))
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.currentTab === index ? AppColors.SURFACE : AppColors.MUTED)
        .width(28)
        .height(28)
        .textAlign(TextAlign.Center)
        .borderRadius(14)
        .backgroundColor(this.currentTab === index ? AppColors.LEDGER : AppColors.SURFACE_SOFT)
      Text(label)
        .fontSize(11)
        .fontColor(this.currentTab === index ? AppColors.LEDGER_DARK : AppColors.MUTED)
    }
    .width('100%')
    .height(54)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  private HomeTab() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Scroll() {
        Column({ space: this.isDesktop() ? 22 : 14 }) {
          this.HomeHeader()
          this.StatusCard()
          this.SpendCard()
          this.ActionPanel()
          this.RecordSection()
        }
        .width('100%')
        .constraintSize({ maxWidth: this.contentMaxWidth() })
        .alignSelf(ItemAlign.Center)
        .padding({ left: AppSpace.PAGE, right: AppSpace.PAGE, top: this.isPhone() ? 16 : 30, bottom: 94 })
      }
      .backgroundColor(AppColors.CANVAS)

      Button('+')
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.SURFACE)
        .width(this.isPhone() ? 52 : 60)
        .height(this.isPhone() ? 52 : 60)
        .borderRadius(this.isPhone() ? 26 : 30)
        .backgroundColor(AppColors.LEDGER_DARK)
        .shadow({ radius: 22, color: '#17364E36', offsetY: 10 })
        .margin({ right: 18, bottom: 20 })
        .onClick(() => router.pushUrl({ url: ROUTES.RECORD_EDIT }))
    }
  }

  @Builder
  private HomeHeader() {
    Row() {
      Column({ space: 6 }) {
        Text(`${this.greetingText()}，${this.displayName()}`)
          .fontSize(this.isPhone() ? 24 : this.isDesktop() ? 30 : 27)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          Text(`${DateUtil.dayLabel(this.nowTime)} ${DateUtil.timeLabel(this.nowTime)} 账本概览`)
            .fontSize(13)
            .fontColor(AppColors.MUTED)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text(this.avatarText())
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.CHART_BLUE)
        .width(this.isPhone() ? 44 : 52)
        .height(this.isPhone() ? 44 : 52)
        .textAlign(TextAlign.Center)
        .borderRadius(this.isPhone() ? 22 : 26)
        .backgroundColor(AppColors.softBlue())
        .border({ width: 5, color: AppColors.SURFACE })
        .shadow({ radius: 18, color: AppColors.SHADOW, offsetY: 8 })
        .onClick(() => router.pushUrl({ url: ROUTES.SEARCH }))
    }
    .width('100%')
  }

  @Builder
  private StatusCard() {
    Column({ space: this.isDesktop() ? 24 : 12 }) {
      Row() {
        Row({ space: 12 }) {
          Text('¥')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.CHART_PINK)
            .width(this.isPhone() ? 40 : 50)
            .height(this.isPhone() ? 40 : 50)
            .textAlign(TextAlign.Center)
            .borderRadius(this.isPhone() ? 20 : 25)
            .backgroundColor(AppColors.softPink())
      Text('今日账本')
            .fontSize(this.isPhone() ? 18 : 21)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.INK)
        }
        Blank()
        Text(`${this.todayRecordCount} 笔`)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.CHART_BLUE)
          .padding({ left: 18, right: 18, top: 8, bottom: 8 })
          .backgroundColor(AppColors.SURFACE_TINT)
          .borderRadius(AppRadius.PILL)
      }
      .width('100%')

      if (this.isDesktop()) {
        Row({ space: 28 }) {
          this.TodayBalancePanel()
          this.StatusMetricGrid()
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      } else if (this.isPhone()) {
        Row({ space: 8 }) {
          this.TodayBalancePanel()
          this.StatusMetricGrid()
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      } else {
        Column({ space: 16 }) {
          this.TodayBalancePanel()
          this.StatusMetricGrid()
        }
        .width('100%')
      }

      this.TodaySupportStrip()
    }
    .width('100%')
    .padding({ left: this.isDesktop() ? 28 : 14, right: this.isDesktop() ? 28 : 14,
      top: this.isPhone() ? 14 : 22, bottom: this.isPhone() ? 14 : 22 })
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .border({ width: 1, color: AppColors.LINE })
    .shadow({ radius: 34, color: AppColors.SHADOW, offsetY: 14 })
  }

  @Builder
  private TodayBalancePanel() {
    Column({ space: this.isPhone() ? 6 : 12 }) {
      Row({ space: 5 }) {
        Text('今日现金流')
          .fontSize(this.isPhone() ? 11 : 12)
          .fontColor(AppColors.MUTED)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.todayStateText())
          .fontSize(this.isPhone() ? 10 : 12)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.todayBalance >= 0 ? AppColors.CHART_GREEN : AppColors.CHART_PINK)
          .width(this.isPhone() ? 36 : 42)
          .height(this.isPhone() ? 26 : 30)
          .textAlign(TextAlign.Center)
          .borderRadius(this.isPhone() ? 13 : 15)
          .backgroundColor(this.todayBalance >= 0 ? AppColors.softGreen() : AppColors.softPink())
      }
      .width('100%')

      Text(NumberUtil.compactMoney(this.todayBalance))
        .fontSize(this.todayBalanceFontSize())
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.INK)
        .width('100%')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Stack({ alignContent: Alignment.Start }) {
        Column()
          .height(10)
          .width('100%')
          .backgroundColor(AppColors.TRACK)
          .borderRadius(5)
        Column()
          .height(10)
          .width(`${this.todayExpenseShare()}%`)
          .backgroundColor(this.todayBalance >= 0 ? AppColors.CHART_GREEN : AppColors.CHART_PINK)
          .borderRadius(5)
      }
      .width('100%')
      .height(10)

      Text(this.todayFlowHint())
        .fontSize(this.isPhone() ? 11 : 12)
        .fontColor(AppColors.MUTED)
        .width('100%')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width(this.isDesktop() ? 180 : this.isPhone() ? 134 : '100%')
    .height(this.isDesktop() ? 146 : this.isPhone() ? 122 : 126)
    .padding(this.isPhone() ? 10 : 16)
    .backgroundColor(AppColors.PANEL)
    .borderRadius(28)
  }

  @Builder
  private TodaySupportStrip() {
    if (this.isPhone()) {
      Row({ space: 8 }) {
        this.SupportPill('预算', () => this.budgetMiniText(), AppColors.WARNING, AppColors.softYellow(), ROUTES.BUDGET_SETTING)
        if (FeatureFlags.AUTO_BOOKKEEPING_VISIBLE) {
          this.SupportPill('待确认', () => `${this.pendingAutoBillCount} 条`, AppColors.CHART_BLUE, AppColors.SURFACE_TINT, ROUTES.AUTO_BOOKKEEPING)
        } else {
          this.SupportPill('本月支出', () => NumberUtil.compactMoney(this.monthExpense), AppColors.CHART_PINK, AppColors.softPink(), ROUTES.STATISTICS)
        }
        this.SupportPill('搜索', () => '查流水', AppColors.CHART_GREEN, AppColors.softGreen(), ROUTES.SEARCH)
      }
      .width('100%')
    } else if (this.isDesktop()) {
      Row({ space: 12 }) {
        this.SupportPill('预算', () => this.budgetMiniText(), AppColors.WARNING, AppColors.softYellow(), ROUTES.BUDGET_SETTING)
        if (FeatureFlags.AUTO_BOOKKEEPING_VISIBLE) {
          this.SupportPill('待确认', () => `${this.pendingAutoBillCount} 条`, AppColors.CHART_BLUE, AppColors.SURFACE_TINT, ROUTES.AUTO_BOOKKEEPING)
        } else {
          this.SupportPill('本月支出', () => NumberUtil.compactMoney(this.monthExpense), AppColors.CHART_PINK, AppColors.softPink(), ROUTES.STATISTICS)
        }
        this.SupportPill('搜索', () => '查流水', AppColors.CHART_GREEN, AppColors.softGreen(), ROUTES.SEARCH)
      }
      .width('100%')
    } else {
      Column({ space: 10 }) {
        Row({ space: 10 }) {
          this.SupportPill('预算', () => this.budgetMiniText(), AppColors.WARNING, AppColors.softYellow(), ROUTES.BUDGET_SETTING)
          if (FeatureFlags.AUTO_BOOKKEEPING_VISIBLE) {
            this.SupportPill('待确认', () => `${this.pendingAutoBillCount} 条`, AppColors.CHART_BLUE, AppColors.SURFACE_TINT, ROUTES.AUTO_BOOKKEEPING)
          } else {
            this.SupportPill('结余', () => NumberUtil.compactMoney(this.monthBalance), AppColors.CHART_BLUE, AppColors.SURFACE_TINT, ROUTES.STATISTICS)
          }
        }
        Row({ space: 10 }) {
          this.SupportPill('本月支出', () => NumberUtil.compactMoney(this.monthExpense), AppColors.CHART_PINK, AppColors.softPink(), ROUTES.STATISTICS)
          this.SupportPill('搜索', () => '查流水', AppColors.CHART_GREEN, AppColors.softGreen(), ROUTES.SEARCH)
        }
      }
      .width('100%')
    }
  }

  @Builder
  private SupportPill(label: string, value: () => string, color: string, bgColor: string, url: string) {
    if (this.isPhone()) {
      Column({ space: 2 }) {
        Text(label)
          .fontSize(10)
          .fontColor(AppColors.MUTED)
          .maxLines(1)
        Text(value())
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor(color)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .textAlign(TextAlign.Center)
      }
      .layoutWeight(1)
      .height(44)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(bgColor)
      .borderRadius(14)
      .onClick(() => router.pushUrl({ url }))
    } else {
      Row({ space: 8 }) {
        Text(label)
          .fontSize(12)
          .fontColor(AppColors.MUTED)
        Text(value())
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(color)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .height(42)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(bgColor)
      .borderRadius(AppRadius.PILL)
      .onClick(() => router.pushUrl({ url }))
    }
  }

  @Builder
  private StatusMetricGrid() {
    if (this.isDesktop()) {
      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
        this.StatusMetric('收入', () => NumberUtil.compactMoney(this.todayIncome), '收', AppColors.CHART_GREEN, AppColors.softGreen())
        this.StatusMetric('支出', () => NumberUtil.compactMoney(this.todayExpense), '支', AppColors.CHART_PINK, AppColors.softPink())
        this.StatusMetric('结余', () => NumberUtil.compactMoney(this.todayBalance), '余', AppColors.CHART_BLUE, AppColors.softBlue())
        this.StatusMetric('记录', () => `${this.todayRecordCount} 笔`, '笔', AppColors.CHART_CYAN, AppColors.softCyan())
      }
      .width('100%')
      .layoutWeight(1)
    } else {
      Column({ space: 8 }) {
        Row({ space: 8 }) {
          this.StatusMetric('收入', () => NumberUtil.compactMoney(this.todayIncome), '收', AppColors.CHART_GREEN, AppColors.softGreen())
          this.StatusMetric('支出', () => NumberUtil.compactMoney(this.todayExpense), '支', AppColors.CHART_PINK, AppColors.softPink())
        }
        .width('100%')
        Row({ space: 8 }) {
          this.StatusMetric('结余', () => NumberUtil.compactMoney(this.todayBalance), '余', AppColors.CHART_BLUE, AppColors.softBlue())
          this.StatusMetric('记录', () => `${this.todayRecordCount} 笔`, '笔', AppColors.CHART_CYAN, AppColors.softCyan())
        }
        .width('100%')
      }
      .width(this.isPhone() ? 0 : '100%')
      .layoutWeight(this.isPhone() ? 1 : 0)
    }
  }

  @Builder
  private StatusMetric(label: string, value: () => string, mark: string, color: string, bgColor: string) {
    if (this.isPhone()) {
      Column({ space: 3 }) {
        Row({ space: 4 }) {
          Text(mark)
            .fontSize(10)
            .fontWeight(FontWeight.Bold)
            .fontColor(color)
            .width(20)
            .height(20)
            .textAlign(TextAlign.Center)
            .borderRadius(10)
            .backgroundColor(bgColor)
          Text(label)
            .fontSize(11)
            .fontColor(AppColors.MUTED)
            .layoutWeight(1)
            .maxLines(1)
        }
        .width('100%')

        Text(value())
          .fontSize(this.metricValueFontSize(value()))
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .width('100%')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .height(48)
      .justifyContent(FlexAlign.Center)
      .padding({ left: 8, right: 6 })
      .backgroundColor(AppColors.SURFACE_SOFT)
      .borderRadius(14)
      .margin({ bottom: 2 })
    } else {
      Row({ space: 9 }) {
        Text(mark)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(color)
          .width(30)
          .height(30)
          .textAlign(TextAlign.Center)
          .borderRadius(15)
          .backgroundColor(bgColor)
        Column({ space: 2 }) {
          Text(label)
            .fontSize(12)
            .fontColor(AppColors.MUTED)
            .width('100%')
          Text(value())
            .fontSize(this.isDesktop() ? 16 : 15)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.INK)
            .width('100%')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('48%')
      .height(this.isDesktop() ? 58 : 56)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .padding({ left: 8, right: 8 })
      .backgroundColor(AppColors.SURFACE_SOFT)
      .borderRadius(16)
      .margin({ bottom: 8 })
    }
  }

  @Builder
  private SpendCard() {
    Column({ space: this.isPhone() ? 14 : 22 }) {
      Row() {
        Row({ space: 12 }) {
          Text('支')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.CHART_ORANGE)
            .width(this.isPhone() ? 42 : 50)
            .height(this.isPhone() ? 42 : 50)
            .textAlign(TextAlign.Center)
            .borderRadius(this.isPhone() ? 21 : 25)
            .backgroundColor(AppColors.softYellow())
          Text(this.monthBudget > 0 ? '本月预算' : '本月支出')
            .fontSize(this.isPhone() ? 18 : 22)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.INK)
        }
        Blank()
        Text(this.budgetStatusText())
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.budgetStatusColor())
          .padding({ left: 18, right: 18, top: 8, bottom: 8 })
          .backgroundColor(this.budgetStatusBgColor())
          .borderRadius(AppRadius.PILL)
          .onClick(() => router.pushUrl({ url: ROUTES.BUDGET_SETTING }))
      }
      .width('100%')

      Row() {
        Column({ space: 8 }) {
          Text(this.monthBudget > 0 ? '已用预算' : '本月已花')
            .fontSize(13)
            .fontColor(AppColors.MUTED)
          Text(NumberUtil.compactMoney(this.monthExpense))
            .fontSize(this.isPhone() ? 30 : this.isWide() ? 38 : 34)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.INK)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.budgetHintText())
            .fontSize(13)
            .fontColor(AppColors.MUTED)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Column({ space: 10 }) {
          Text(this.monthBudget > 0 ? '预算剩余' : '本月结余')
            .fontSize(13)
            .fontColor(AppColors.MUTED)
          Text(this.monthBudget > 0 ? NumberUtil.compactMoney(this.monthBudgetRemaining) : NumberUtil.compactMoney(this.monthBalance))
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.monthBudget > 0 ? this.budgetStatusColor() : this.monthBalance >= 0 ? AppColors.CHART_GREEN : AppColors.EXPENSE)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
          Text(`${this.homeProgress()}%`)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.WARNING)
        }
        .alignItems(HorizontalAlign.Start)
        .width(this.isWide() ? 180 : 118)
      }
      .width('100%')

      Stack({ alignContent: Alignment.Start }) {
        Column()
          .height(8)
          .width('100%')
          .backgroundColor(AppColors.TRACK)
          .borderRadius(4)
        Column()
          .height(8)
          .width(`${this.homeProgress()}%`)
          .backgroundColor(this.monthBudget > 0 && this.monthBudgetProgress >= 100 ? AppColors.EXPENSE : AppColors.CHART_ORANGE)
          .borderRadius(4)
      }
      .width('100%')
      .height(8)

      if (!this.isPhone()) {
        Button(this.monthBudget > 0 ? '调整预算' : '设置预算')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.WARNING)
          .height(42)
          .width('100%')
          .backgroundColor(AppColors.softYellow())
          .borderRadius(AppRadius.PILL)
          .onClick(() => router.pushUrl({ url: ROUTES.BUDGET_SETTING }))
      }
    }
    .width('100%')
    .padding(this.isPhone() ? 16 : 24)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 28, color: AppColors.SHADOW, offsetY: 12 })
  }

  @Builder
  private ActionPanel() {
    Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
      this.QuickAction('记一笔', '新增收支', '＋', AppColors.CHART_BLUE, AppColors.softBlue(), ROUTES.RECORD_EDIT)
      this.QuickAction('日历', '每日收支', '日', AppColors.LILAC, AppColors.softPurple(), ROUTES.CALENDAR)
      this.QuickAction('预算', '月度进度', '％', AppColors.WARNING, AppColors.softYellow(), ROUTES.BUDGET_SETTING)
      this.QuickAction('导出', '生成报表', '↓', AppColors.CHART_GREEN, AppColors.softGreen(), ROUTES.DATA_EXPORT)
    }
    .width('100%')
  }

  @Builder
  private QuickAction(title: string, subtitle: string, mark: string, color: string, bgColor: string, url: string) {
    if (this.isNarrowPhone()) {
      Column({ space: 8 }) {
        Text(mark)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(color)
          .width(36)
          .height(36)
          .textAlign(TextAlign.Center)
          .borderRadius(18)
          .backgroundColor(bgColor)
        Text(title)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .maxLines(1)
      }
      .justifyContent(FlexAlign.Center)
      .height(78)
      .width(this.actionCardWidth())
      .backgroundColor(AppColors.SURFACE)
      .borderRadius(AppRadius.CARD)
      .shadow({ radius: 18, color: AppColors.SHADOW, offsetY: 8 })
      .margin({ bottom: 10 })
      .onClick(() => router.pushUrl({ url }))
    } else {
      Row({ space: 10 }) {
        Text(mark)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(color)
          .width(42)
          .height(42)
          .textAlign(TextAlign.Center)
          .borderRadius(21)
          .backgroundColor(bgColor)
        Column({ space: 3 }) {
          Text(title)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.INK)
            .width('100%')
          Text(subtitle)
            .fontSize(11)
            .fontColor(AppColors.MUTED)
            .width('100%')
            .maxLines(1)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .height(70)
      .width(this.actionCardWidth())
      .padding({ left: 14, right: 14 })
      .backgroundColor(AppColors.SURFACE)
      .borderRadius(AppRadius.CARD)
      .shadow({ radius: 18, color: AppColors.SHADOW, offsetY: 8 })
      .margin({ bottom: 10 })
      .onClick(() => router.pushUrl({ url }))
    }
  }

  @Builder
  private RecordSection() {
    Column({ space: 12 }) {
      this.SectionTitle('最近流水', `${this.appState.recordList.length} 笔`)

      if (this.appState.recordList.length === 0) {
        Column({ space: 10 }) {
          Text('暂无账单')
            .fontSize(19)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.INK)
          Text('点右下角按钮记第一笔')
            .fontSize(13)
            .fontColor(AppColors.MUTED)
        }
        .width('100%')
        .height(this.isPhone() ? 118 : 168)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(AppColors.SURFACE)
        .borderRadius(AppRadius.CARD)
        .shadow({ radius: 20, color: AppColors.SHADOW, offsetY: 8 })
      } else {
        ForEach(this.appState.recordList, (item: RecordListItem) => {
          Column() {
            RecordItem({ item })
          }
          .onClick(() => {
            if (item.id) {
              router.pushUrl({ url: ROUTES.RECORD_DETAIL, params: { recordId: item.id } });
            }
          })
        }, (item: RecordListItem) => `${item.id}-${item.updateTime}`)
      }
    }
    .width('100%')
  }

  @Builder
  private StatisticsTab() {
    Column() {
      StatisticsDashboard({ active: this.currentTab === 1, refreshKey: this.statisticsRefreshKey })
        .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.CANVAS)
  }

  @Builder
  private AssetsTab() {
    Scroll() {
      Column({ space: 18 }) {
        this.PageHeader('资产', '账户与余额')
        this.AssetSummary()
        this.SectionTitle('账户列表', `${this.appState.accountList.length} 个`)
        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
          ForEach(this.appState.accountList, (account: AccountModel) => {
            this.AssetCard(account)
          }, (account: AccountModel) => `${account.id}`)
        }
        .width('100%')
      }
      .width('100%')
      .constraintSize({ maxWidth: this.contentMaxWidth() })
      .alignSelf(ItemAlign.Center)
      .padding({ left: AppSpace.PAGE, right: AppSpace.PAGE, top: 26, bottom: 96 })
    }
    .backgroundColor(AppColors.CANVAS)
  }

  @Builder
  private AssetSummary() {
    Column({ space: 18 }) {
      Row() {
        Row({ space: 12 }) {
          Text('卡')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.LEDGER)
            .width(46)
            .height(46)
            .textAlign(TextAlign.Center)
            .borderRadius(15)
            .backgroundColor(AppColors.SURFACE_TINT)
          Column({ space: 4 }) {
            Text('净资产')
              .fontSize(13)
              .fontColor(AppColors.MUTED)
            Text(NumberUtil.compactMoney(this.appState.totalAssets))
              .fontSize(34)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.INK)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)
      }
      .width('100%')

      Row() {
        Text('账户余额一目了然')
          .fontSize(13)
          .fontColor(AppColors.MUTED)
        Blank()
        Text('管理')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.CHART_BLUE)
          .padding({ left: 14, right: 14, top: 6, bottom: 6 })
          .backgroundColor(AppColors.SURFACE_TINT)
          .borderRadius(AppRadius.PILL)
          .onClick(() => router.pushUrl({ url: ROUTES.ACCOUNT_MANAGE }))
      }
      .width('100%')
    }
    .width('100%')
    .padding(22)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 24, color: AppColors.SHADOW, offsetY: 10 })
  }

  @Builder
  private AssetCard(account: AccountModel) {
    Row({ space: 12 }) {
      Text(account.name.substring(0, 1))
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(account.color)
        .width(42)
        .height(42)
        .textAlign(TextAlign.Center)
        .borderRadius(14)
        .backgroundColor(AppColors.SURFACE_TINT)
      Column({ space: 4 }) {
        Text(account.name)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .maxLines(1)
        Text(account.isLiability ? '负债账户' : '资产账户')
          .fontSize(12)
          .fontColor(AppColors.MUTED)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Text(NumberUtil.compactMoney(account.balance))
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(account.isLiability ? AppColors.EXPENSE : AppColors.INK)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .constraintSize({ maxWidth: 118 })
    }
    .height(this.isPhone() ? 70 : 78)
    .width(this.isWide() ? '48%' : '100%')
    .padding({ left: 16, right: 16 })
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 18, color: AppColors.SHADOW, offsetY: 8 })
    .margin({ bottom: 12 })
  }

  @Builder
  private ProfileTab() {
    Scroll() {
      Column({ space: 18 }) {
        this.PageHeader('我的', '设置与数据')
        this.ProfileIntro()
        this.SectionTitle('常用功能', '快捷管理')
        this.ProfileGrid()
      }
      .width('100%')
      .constraintSize({ maxWidth: this.contentMaxWidth() })
      .alignSelf(ItemAlign.Center)
      .padding({ left: AppSpace.PAGE, right: AppSpace.PAGE, top: 26, bottom: 96 })
    }
    .backgroundColor(AppColors.CANVAS)
  }

  @Builder
  private ProfileIntro() {
    Column({ space: 14 }) {
      Row() {
        Text('账')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.LEDGER)
          .width(52)
          .height(52)
          .textAlign(TextAlign.Center)
          .borderRadius(18)
          .backgroundColor(AppColors.SURFACE_TINT)
        Blank()
        Text('轻量好用')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.LEDGER)
          .padding({ left: 14, right: 14, top: 6, bottom: 6 })
          .backgroundColor(AppColors.SURFACE_TINT)
          .borderRadius(AppRadius.PILL)
      }
      .width('100%')

      Text('我的账本')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.INK)
        .width('100%')
      Text('管理分类、预算、导出和偏好设置。')
        .fontSize(14)
        .fontColor(AppColors.MUTED)
        .lineHeight(22)
        .width('100%')
    }
    .width('100%')
    .padding(22)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 24, color: AppColors.SHADOW, offsetY: 10 })
  }

  @Builder
  private ProfileGrid() {
    Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
      this.ProfileShortcut('分类管理', '调整常用分类', '类', AppColors.LEDGER, AppColors.SURFACE_TINT, ROUTES.CATEGORY_MANAGE)
      this.ProfileShortcut('账户管理', '维护账户余额', '户', AppColors.CHART_CYAN, AppColors.softCyan(), ROUTES.ACCOUNT_MANAGE)
      this.ProfileShortcut('预算管理', '控制月度支出', '预', AppColors.WARNING, AppColors.softYellow(), ROUTES.BUDGET_SETTING)
      if (FeatureFlags.AUTO_BOOKKEEPING_VISIBLE) {
        this.ProfileShortcut('自动记账', this.pendingAutoBillCount > 0 ? `${this.pendingAutoBillCount} 条待确认` : '审核识别账单', '识', AppColors.CHART_BLUE, AppColors.softBlue(), ROUTES.AUTO_BOOKKEEPING)
      }
      this.ProfileShortcut('数据导出与备份', '导出账单和恢复备份', '备', AppColors.INCOME, AppColors.softGreen(), ROUTES.DATA_EXPORT)
      this.ProfileShortcut('设置', '主题与偏好', '设', AppColors.LILAC, AppColors.softPurple(), ROUTES.SETTINGS)
      this.ProfileShortcut('关于', '版本与说明', '关', AppColors.MUTED, AppColors.SURFACE_SOFT, ROUTES.ABOUT)
    }
    .width('100%')
  }

  @Builder
  private ProfileShortcut(label: string, subtitle: string, mark: string, color: string, bgColor: string, url: string) {
    Row({ space: 12 }) {
      Text(mark)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
        .width(40)
        .height(40)
        .textAlign(TextAlign.Center)
        .borderRadius(14)
        .backgroundColor(bgColor)
      Column({ space: 4 }) {
        Text(label)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .width('100%')
          .maxLines(1)
        Text(subtitle)
          .fontSize(12)
          .fontColor(AppColors.MUTED)
          .width('100%')
          .maxLines(1)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Text('›')
        .fontSize(22)
        .fontColor(AppColors.FAINT)
    }
    .width(this.isWide() ? '48%' : '100%')
    .height(this.isPhone() ? 70 : 76)
    .padding({ left: 16, right: 16 })
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 18, color: AppColors.SHADOW, offsetY: 8 })
    .margin({ bottom: 12 })
    .onClick(() => router.pushUrl({ url }))
  }

  @Builder
  private PageHeader(title: string, subtitle: string) {
    Column({ space: 5 }) {
      Text(title)
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.INK)
        .width('100%')
      Text(subtitle)
        .fontSize(13)
        .fontColor(AppColors.MUTED)
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  @Builder
  private SectionTitle(title: string, badge: string) {
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
        .padding({ left: 12, right: 12, top: 5, bottom: 5 })
        .backgroundColor(AppColors.SURFACE_TINT)
        .borderRadius(AppRadius.PILL)
    }
    .width('100%')
  }

  private tabMark(index: number): string {
    const marks: string[] = ['明', '统', '资', '我'];
    return marks[index];
  }

  private todayFlowHint(): string {
    if (this.todayBalance > 0) {
      return `收入 ${NumberUtil.compactMoney(this.todayIncome)}，支出 ${NumberUtil.compactMoney(this.todayExpense)}`;
    }
    if (this.todayBalance < 0) {
      return `支出 ${NumberUtil.compactMoney(this.todayExpense)} 高于收入`;
    }
    return this.todayRecordCount > 0 ? '今日收支持平' : '今日还没有记录';
  }

  private todayBalanceFontSize(): number {
    if (!this.isPhone()) {
      return this.isDesktop() ? 50 : 42;
    }
    const length = NumberUtil.compactMoney(this.todayBalance).length;
    if (length <= 8) {
      return 24;
    }
    if (length <= 10) {
      return 21;
    }
    return 18;
  }

  private metricValueFontSize(value: string): number {
    if (value.length <= 9) {
      return 13;
    }
    return 12;
  }

  private expensePercent(): number {
    if (this.monthIncome <= 0) {
      return this.monthExpense > 0 ? 100 : 0;
    }
    return Math.min(100, Math.round(this.monthExpense / this.monthIncome * 100));
  }

  private homeProgress(): number {
    if (this.monthBudget > 0) {
      return this.monthBudgetProgress;
    }
    return this.expensePercent();
  }

  private budgetMiniText(): string {
    if (this.monthBudget <= 0) {
      return '未设置';
    }
    return `${this.monthBudgetProgress}%`;
  }

  private budgetHintText(): string {
    if (this.monthBudget <= 0) {
      return `收入 ${NumberUtil.compactMoney(this.monthIncome)}`;
    }
    return `预算 ${NumberUtil.compactMoney(this.monthBudget)} · 已用 ${this.monthBudgetProgress}%`;
  }

  private budgetStatusText(): string {
    if (this.monthBudget <= 0) {
      return '去设置';
    }
    if (this.monthBudgetProgress >= 100) {
      return '已超支';
    }
    if (this.monthBudgetProgress >= 80) {
      return '快用完';
    }
    return '可控';
  }

  private budgetStatusColor(): string {
    if (this.monthBudget <= 0) {
      return AppColors.WARNING;
    }
    if (this.monthBudgetProgress >= 100) {
      return AppColors.EXPENSE;
    }
    if (this.monthBudgetProgress >= 80) {
      return AppColors.WARNING;
    }
    return AppColors.CHART_GREEN;
  }

  private budgetStatusBgColor(): string {
    if (this.monthBudget <= 0 || this.monthBudgetProgress >= 80) {
      return AppColors.softYellow();
    }
    return AppColors.softGreen();
  }

  private todayExpenseShare(): number {
    const total = this.todayIncome + this.todayExpense;
    if (total <= 0) {
      return 0;
    }
    return Math.max(6, Math.min(100, Math.round(this.todayExpense / total * 100)));
  }

  private todayStateText(): string {
    if (this.todayRecordCount === 0) {
      return '待记';
    }
    return this.todayBalance >= 0 ? '平稳' : '关注';
  }

  private actionCardWidth(): string {
    if (this.isDesktop()) {
      return '24%';
    }
    if (this.isPhone()) {
      return '48.5%';
    }
    if (this.isTablet()) {
      return '48%';
    }
    return '100%';
  }

  private greetingText(): string {
    const hour = new Date(this.nowTime).getHours();
    if (hour < 6) {
      return '夜深了';
    }
    if (hour < 11) {
      return '上午好';
    }
    if (hour < 14) {
      return '中午好';
    }
    if (hour < 18) {
      return '下午好';
    }
    return '晚上好';
  }

  private async refresh(): Promise<void> {
    await this.loadProfileSettings();
    try {
      await AppDatabase.getInstance().init(getContext(this));
      await this.appState.refreshAll();
    } catch (error) {
    }
    await this.refreshHomeMetrics();
    if (this.currentTab === 1) {
      this.statisticsRefreshKey++;
    }
  }

  private async loadProfileSettings(): Promise<void> {
    try {
      this.userName = await this.settingsRepository.loadUserName(getContext(this));
      const settings = await this.settingsRepository.load(getContext(this));
      ThemeUtil.apply(settings.themeMode, getContext(this));
    } catch (error) {
      this.userName = this.userName.trim() || '账本';
    }
  }

  private displayName(): string {
    return this.userName.trim() || '账本';
  }

  private avatarText(): string {
    return this.displayName().substring(0, 1);
  }

  private async refreshHomeMetrics(): Promise<void> {
    try {
      const todayStart = DateUtil.startOfDay();
      const todayEnd = DateUtil.addDays(todayStart, 1);
      const monthStart = DateUtil.startOfMonth();
      const monthEnd = DateUtil.startOfNextMonth();

      const todaySummary = await this.homeRecordRepository.monthSummary(todayStart, todayEnd);
      const monthSummary = await this.homeRecordRepository.monthSummary(monthStart, monthEnd);
      const recordCount = await this.homeRecordRepository.recordCount(todayStart, todayEnd);
      const budgets = await this.homeBudgetRepository.listByMonth(DateUtil.monthKey());
      const pendingCount = FeatureFlags.AUTO_BOOKKEEPING_VISIBLE ? await new AutoBookkeepingRepository().countPending() : 0;

      this.todayIncome = todaySummary.income;
      this.todayExpense = todaySummary.expense;
      this.todayBalance = todaySummary.balance;
      this.todayRecordCount = recordCount;
      this.monthIncome = monthSummary.income;
      this.monthExpense = monthSummary.expense;
      this.monthBalance = monthSummary.balance;
      this.pendingAutoBillCount = pendingCount;

      this.applyBudgetState(budgets, monthSummary.expense);
      this.syncMetricsToAppState();
    } catch (error) {
    }
  }

  private applyBudgetState(budgets: BudgetModel[], expense: number): void {
    const totalBudget = budgets.find((item: BudgetModel) => item.categoryId === 0);
    const categoryBudgetTotal = budgets.reduce((sum: number, item: BudgetModel) => {
      return item.categoryId > 0 ? sum + item.amount : sum;
    }, 0);
    this.monthBudget = totalBudget && totalBudget.amount > 0 ? totalBudget.amount : categoryBudgetTotal;
    this.monthBudgetRemaining = Math.max(0, this.monthBudget - expense);
    this.monthBudgetProgress = this.monthBudget > 0 ? Math.min(100, Math.round(expense / this.monthBudget * 100)) : 0;
  }

  private syncMetricsToAppState(): void {
    this.appState.monthIncome = this.monthIncome;
    this.appState.monthExpense = this.monthExpense;
    this.appState.monthBalance = this.monthBalance;
    this.appState.todayIncome = this.todayIncome;
    this.appState.todayExpense = this.todayExpense;
    this.appState.todayBalance = this.todayBalance;
    this.appState.todayRecordCount = this.todayRecordCount;
    this.appState.monthBudget = this.monthBudget;
    this.appState.monthBudgetRemaining = this.monthBudgetRemaining;
    this.appState.monthBudgetProgress = this.monthBudgetProgress;
    this.appState.pendingAutoBillCount = this.pendingAutoBillCount;
  }

  private isWide(): boolean {
    return this.viewportWidth >= Breakpoints.WIDE;
  }

  private isDesktop(): boolean {
    return this.viewportWidth >= Breakpoints.DESKTOP;
  }

  private isTablet(): boolean {
    return this.viewportWidth >= Breakpoints.TABLET && this.viewportWidth < Breakpoints.DESKTOP;
  }

  private isPhone(): boolean {
    return this.viewportWidth < Breakpoints.TABLET;
  }

  private isNarrowPhone(): boolean {
    return this.viewportWidth < 480;
  }

  private contentMaxWidth(): number {
    return this.isDesktop() ? LayoutSizes.CONTENT_MAX : LayoutSizes.CONTENT_COMPACT;
  }
}
