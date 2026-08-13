import { router } from '@kit.ArkUI';
import { AppColors, AppRadius, AppSpace, LayoutSizes } from '../constants/DesignSystem';
import { BudgetRepository } from '../repository/BudgetRepository';
import { CategoryRepository } from '../repository/CategoryRepository';
import { RecordRepository } from '../repository/RecordRepository';
import { CategoryModel } from '../model/Category';
import { BudgetModel } from '../model/Budget';
import { RecordType } from '../model/Record';
import { CategoryExpenseRank } from '../repository/RecordRepository';
import { AppState } from '../viewmodel/AppState';
import { DateUtil } from '../utils/DateUtil';
import { NumberUtil } from '../utils/NumberUtil';
import { ToastUtil } from '../utils/ToastUtil';
import { AppDatabase } from '../database/AppDatabase';

interface BudgetRow {
  categoryId: number;
  categoryName: string;
  categoryColor: string;
  budgetText: string;
  spent: number;
}

@Entry
@Component
struct BudgetSetting {
  private budgetRepository: BudgetRepository = new BudgetRepository();
  private categoryRepository: CategoryRepository = new CategoryRepository();
  private recordRepository: RecordRepository = new RecordRepository();

  @State viewportWidth: number = 0;
  @State anchorTime: number = Date.now();
  @State totalBudgetText: string = '0';
  @State rows: BudgetRow[] = [];
  @State spentTotal: number = 0;
  @State loading: boolean = false;

  aboutToAppear(): void {
    this.loadMonthData();
  }

  onPageShow(): void {
    this.loadMonthData();
  }

  build() {
    Column() {
      this.Header()

      Scroll() {
        Column({ space: 18 }) {
          this.MonthToolbar()
          this.TotalCard()
          this.CategoryBudgetCard()
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
        Text('预算管理')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .width('100%')
        Text('月度总预算和分类预算')
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
  private MonthToolbar() {
    Row() {
      Button('‹')
        .fontSize(24)
        .fontColor(AppColors.CHART_BLUE)
        .width(42)
        .height(38)
        .backgroundColor('#EAF4FF')
        .borderRadius(19)
        .onClick(() => {
          this.anchorTime = new Date(new Date(this.anchorTime).getFullYear(), new Date(this.anchorTime).getMonth() - 1, 1).getTime();
          this.loadMonthData();
        })

      Text(this.monthLabel())
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.INK)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Button('›')
        .fontSize(24)
        .fontColor(AppColors.CHART_BLUE)
        .width(42)
        .height(38)
        .backgroundColor('#EAF4FF')
        .borderRadius(19)
        .onClick(() => {
          this.anchorTime = new Date(new Date(this.anchorTime).getFullYear(), new Date(this.anchorTime).getMonth() + 1, 1).getTime();
          this.loadMonthData();
        })
    }
    .width('100%')
  }

  @Builder
  private TotalCard() {
    Column({ space: 16 }) {
      Row() {
        Column({ space: 4 }) {
          Text('月度总预算')
            .fontSize(13)
            .fontColor(AppColors.MUTED)
          TextInput({ text: this.totalBudgetText, placeholder: '0.00' })
            .height(52)
            .fontSize(26)
            .fontWeight(FontWeight.Bold)
            .backgroundColor(AppColors.SURFACE_SOFT)
            .borderRadius(18)
            .padding({ left: 16, right: 16 })
            .onChange((value: string) => {
              this.totalBudgetText = value;
            })
        }
        .layoutWeight(1)
      }
      .width('100%')

      Row() {
        this.InfoChip('已用', NumberUtil.money(this.spentTotal), AppColors.EXPENSE, '#FCE9E4')
        this.InfoChip('剩余', NumberUtil.money(this.remainingTotal()), AppColors.CHART_GREEN, '#E6F7EF')
        this.InfoChip('进度', `${this.totalProgress()}%`, AppColors.CHART_BLUE, AppColors.SURFACE_TINT)
      }
      .width('100%')

      Stack({ alignContent: Alignment.Start }) {
        Column()
          .height(10)
          .width('100%')
          .backgroundColor('#EAF0F6')
          .borderRadius(5)
        Column()
          .height(10)
          .width(`${this.totalProgress()}%`)
          .backgroundColor(this.totalProgress() >= 100 ? AppColors.EXPENSE : AppColors.CHART_BLUE)
          .borderRadius(5)
      }
      .width('100%')
      .height(10)

      Button('保存月度总预算')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.SURFACE)
        .height(48)
        .width('100%')
        .backgroundColor(AppColors.CHART_BLUE)
        .borderRadius(AppRadius.PILL)
        .onClick(() => this.saveBudget())
    }
    .width('100%')
    .padding(16)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 20, color: AppColors.SHADOW, offsetY: 8 })
  }

  @Builder
  private CategoryBudgetCard() {
    Column({ space: 12 }) {
      Row() {
        Text('分类预算')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
        Blank()
        Text(`${this.rows.length} 项`)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.LEDGER)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor(AppColors.SURFACE_TINT)
          .borderRadius(AppRadius.PILL)
      }
      .width('100%')

      if (this.rows.length === 0) {
        this.EmptyState('暂无分类预算', '保存后会按当前支出分类生成列表')
      } else {
        ForEach(this.rows, (item: BudgetRow, index: number) => {
          this.BudgetRow(item, index)
        }, (item: BudgetRow) => `${item.categoryId}`)
      }

      Button('保存分类预算')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.SURFACE)
        .height(48)
        .width('100%')
        .backgroundColor(AppColors.CHART_GREEN)
        .borderRadius(AppRadius.PILL)
        .onClick(() => this.saveBudget())
    }
    .width('100%')
    .padding(16)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 20, color: AppColors.SHADOW, offsetY: 8 })
  }

  @Builder
  private BudgetRow(item: BudgetRow, index: number) {
    Column({ space: 10 }) {
      Row() {
        Row({ space: 10 }) {
          Text(item.categoryName.substring(0, 1))
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(item.categoryColor)
            .width(40)
            .height(40)
            .textAlign(TextAlign.Center)
            .backgroundColor(AppColors.SURFACE_TINT)
            .borderRadius(14)
          Column({ space: 2 }) {
            Text(item.categoryName)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.INK)
              .maxLines(1)
            Text(`已用 ${NumberUtil.money(item.spent)}`)
              .fontSize(12)
              .fontColor(AppColors.MUTED)
          }
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)

        TextInput({ text: item.budgetText, placeholder: '0.00' })
          .type(InputType.Number)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .width(110)
          .height(44)
          .textAlign(TextAlign.End)
          .backgroundColor(AppColors.SURFACE_SOFT)
          .borderRadius(16)
          .padding({ left: 14, right: 14 })
          .onChange((value: string) => {
            this.rows[index].budgetText = value;
          })
      }
      .width('100%')

      Stack({ alignContent: Alignment.Start }) {
        Column()
          .height(7)
          .width('100%')
          .backgroundColor(AppColors.SURFACE_SOFT)
          .borderRadius(4)
        Column()
          .height(7)
          .width(`${this.rowProgress(item)}%`)
          .backgroundColor(this.rowProgress(item) >= 100 ? AppColors.EXPENSE : item.categoryColor)
          .borderRadius(4)
      }
      .width('100%')
      .height(7)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(AppColors.SURFACE_SOFT)
    .border({ width: 1, color: AppColors.LINE })
    .borderRadius(20)
  }

  @Builder
  private InfoChip(label: string, value: string, color: string, bgColor: string) {
    Column({ space: 4 }) {
      Text(label)
        .fontSize(12)
        .fontColor(AppColors.MUTED)
      Text(value)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
    }
    .layoutWeight(1)
    .padding(12)
    .backgroundColor(bgColor)
    .borderRadius(16)
  }

  @Builder
  private EmptyState(title: string, subtitle: string) {
    Column({ space: 6 }) {
      Text(title)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.INK)
      Text(subtitle)
        .fontSize(12)
        .fontColor(AppColors.MUTED)
    }
    .width('100%')
    .height(104)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(AppColors.SURFACE_SOFT)
    .borderRadius(20)
  }

  private async loadMonthData(): Promise<void> {
    try {
      this.loading = true;
      await AppDatabase.getInstance().init(getContext(this));
      const month = DateUtil.monthKey(this.anchorTime);
      const startTime = DateUtil.startOfMonth(this.anchorTime);
      const endTime = DateUtil.startOfNextMonth(this.anchorTime);
      const categories = await this.categoryRepository.listByType(RecordType.EXPENSE);
      const budgets = await this.budgetRepository.listByMonth(month);
      const summary = await this.recordRepository.monthSummary(startTime, endTime);
      this.totalBudgetText = `${this.totalBudgetAmount(budgets)}`;
      const rankList = await this.recordRepository.categoryExpenseRanks(startTime, endTime);
      const compatibleSpent = await this.compatibleExpenseByCategory(startTime, endTime);
      this.rows = this.buildRows(categories, budgets, rankList, compatibleSpent);
      const rowSpentTotal = this.rows.reduce((total: number, item: BudgetRow) => total + item.spent, 0);
      this.spentTotal = rowSpentTotal > 0 ? rowSpentTotal : summary.expense;
    } catch (error) {
      this.rows = [];
      this.spentTotal = 0;
      ToastUtil.show('预算数据加载失败，请稍后重试');
    } finally {
      this.loading = false;
    }
  }

  private buildRows(
    categories: CategoryModel[],
    budgets: BudgetModel[],
    ranks: CategoryExpenseRank[],
    compatibleSpent: Map<number, number>
  ): BudgetRow[] {
    const budgetMap = new Map<number, BudgetModel>();
    budgets.forEach((item: BudgetModel) => {
      budgetMap.set(item.categoryId, item);
    });
    const spentMap = new Map<number, number>();
    ranks.forEach((item: CategoryExpenseRank) => {
      spentMap.set(item.categoryId, item.amount);
    });
    return categories.map((category: CategoryModel) => {
      const budget = budgetMap.get(category.id || 0);
      const row: BudgetRow = {
        categoryId: category.id || 0,
        categoryName: category.name,
        categoryColor: category.color,
        budgetText: budget ? `${budget.amount}` : '0',
        spent: spentMap.get(category.id || 0) || compatibleSpent.get(category.id || 0) || 0
      };
      return row;
    });
  }

  private async saveBudget(): Promise<void> {
    try {
      this.loading = true;
      await AppDatabase.getInstance().init(getContext(this));
      const month = DateUtil.monthKey(this.anchorTime);
      const total = Number(this.totalBudgetText) || 0;
      await this.budgetRepository.upsertMonthlyBudget(0, total, month);
      for (const row of this.rows) {
        await this.budgetRepository.upsertMonthlyBudget(row.categoryId, Number(row.budgetText) || 0, month);
      }
      await AppState.getInstance().refreshAll();
      await this.loadMonthData();
      ToastUtil.show('本月预算已保存');
    } catch (error) {
      ToastUtil.show(ToastUtil.error(error, '预算保存失败，请稍后重试'));
    } finally {
      this.loading = false;
    }
  }

  private totalBudgetAmount(budgets: BudgetModel[]): number {
    const item = budgets.find((budget: BudgetModel) => budget.categoryId === 0);
    return item ? item.amount : 0;
  }

  private rankExpenseTotal(ranks: CategoryExpenseRank[]): number {
    return ranks.reduce((total: number, item: CategoryExpenseRank) => total + item.amount, 0);
  }

  private async compatibleExpenseByCategory(startTime: number, endTime: number): Promise<Map<number, number>> {
    const records = await this.recordRepository.listByRange(startTime, endTime, 10000, 0);
    const result = new Map<number, number>();
    records.forEach((item) => {
      if (item.type === RecordType.EXPENSE) {
        result.set(item.categoryId, (result.get(item.categoryId) || 0) + item.amount);
      }
    });
    return result;
  }

  private mapExpenseTotal(spent: Map<number, number>): number {
    let total = 0;
    spent.forEach((amount: number) => {
      total += amount;
    });
    return total;
  }

  private rowProgress(row: BudgetRow): number {
    const budget = Number(row.budgetText) || 0;
    if (budget <= 0) {
      return 0;
    }
    return Math.min(100, Math.round(row.spent / budget * 100));
  }

  private totalProgress(): number {
    const total = Number(this.totalBudgetText) || 0;
    if (total <= 0) {
      return 0;
    }
    return Math.min(100, Math.round(this.spentTotal / total * 100));
  }

  private remainingTotal(): number {
    return Math.max(0, (Number(this.totalBudgetText) || 0) - this.spentTotal);
  }

  private monthLabel(): string {
    const date = new Date(this.anchorTime);
    return `${date.getFullYear()} 年 ${date.getMonth() + 1} 月`;
  }
}
