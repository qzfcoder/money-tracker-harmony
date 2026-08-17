import { router } from '@kit.ArkUI';
import { AppColors, AppRadius, AppSpace, LayoutSizes } from '../constants/DesignSystem';
import { BudgetRepository } from '../repository/BudgetRepository';
import { CategoryRepository } from '../repository/CategoryRepository';
import { RecordRepository } from '../repository/RecordRepository';
import { CategoryModel } from '../model/Category';
import { BudgetModel } from '../model/Budget';
import { RecordType } from '../model/Record';
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
  @State totalBudgetValue: number = 0;
  @State categoryBudgetTotal: number = 0;
  @State rows: BudgetRow[] = [];
  @State spentTotal: number = 0;
  @State remainingTotalValue: number = 0;
  @State totalProgressValue: number = 0;
  @State loading: boolean = false;
  @StorageLink('ledgerIsDarkMode') isDarkMode: boolean = false;

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
        .backgroundColor(AppColors.softBlue())
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
        .backgroundColor(AppColors.softBlue())
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
      Row({ space: 8 }) {
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
              this.totalBudgetText = this.normalizeAmount(value);
              this.totalBudgetValue = this.parseAmount(this.totalBudgetText);
              this.refreshBudgetStats();
            })
        }
        .layoutWeight(1)
      }
      .width('100%')

      Row() {
        Column({ space: 4 }) {
          Text('已用')
            .fontSize(12)
            .fontColor(AppColors.MUTED)
          Text(NumberUtil.compactMoney(this.spentTotal))
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.EXPENSE)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
            .textAlign(TextAlign.Center)
        }
        .alignItems(HorizontalAlign.Center)
        .layoutWeight(1)
        .height(76)
        .padding(12)
        .backgroundColor(AppColors.softDanger())
        .borderRadius(16)

        Column({ space: 4 }) {
          Text('剩余')
            .fontSize(12)
            .fontColor(AppColors.MUTED)
          Text(NumberUtil.compactMoney(this.remainingTotal()))
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.CHART_GREEN)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
            .textAlign(TextAlign.Center)
        }
        .alignItems(HorizontalAlign.Center)
        .layoutWeight(1)
        .height(76)
        .padding(12)
        .backgroundColor(AppColors.softGreen())
        .borderRadius(16)

        Column({ space: 4 }) {
          Text('进度')
            .fontSize(12)
            .fontColor(AppColors.MUTED)
          Text(`${this.totalProgress()}%`)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.CHART_BLUE)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
            .textAlign(TextAlign.Center)
        }
        .alignItems(HorizontalAlign.Center)
        .layoutWeight(1)
        .height(76)
        .padding(12)
        .backgroundColor(AppColors.SURFACE_TINT)
        .borderRadius(16)
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
            Text(`已用 ${NumberUtil.compactMoney(item.spent)}`)
              .fontSize(12)
              .fontColor(AppColors.MUTED)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)

        TextInput({ text: item.budgetText, placeholder: '0.00' })
          .type(InputType.NUMBER_DECIMAL)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .width(110)
          .height(44)
          .textAlign(TextAlign.End)
          .backgroundColor(AppColors.SURFACE_SOFT)
          .borderRadius(16)
          .padding({ left: 14, right: 14 })
          .onChange((value: string) => {
            this.rows[index].budgetText = this.normalizeAmount(value);
            this.categoryBudgetTotal = this.rows.reduce((total: number, row: BudgetRow) => {
              return total + this.parseAmount(row.budgetText);
            }, 0);
            this.refreshBudgetStats();
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
      this.totalBudgetValue = this.totalBudgetAmount(budgets);
      this.categoryBudgetTotal = this.categoryBudgetAmount(budgets);
      this.totalBudgetText = this.formatBudgetInput(this.totalBudgetValue);
      const spentByCategory = this.mergeSpentMaps(
        await this.recordRepository.expenseByCategoryByMonth(month),
        await this.recordRepository.expenseByCategory(startTime, endTime)
      );
      this.rows = this.buildRows(categories, budgets, spentByCategory);
      const monthSummary = await this.recordRepository.monthSummary(startTime, endTime);
      const directTotal = Math.max(
        monthSummary.expense,
        await this.recordRepository.expenseTotalByMonth(month),
        await this.recordRepository.expenseTotal(startTime, endTime)
      );
      const rowSpentTotal = this.rows.reduce((total: number, item: BudgetRow) => total + item.spent, 0);
      this.spentTotal = Math.max(directTotal, rowSpentTotal);
      this.refreshBudgetStats();
    } catch (error) {
      this.rows = [];
      this.spentTotal = 0;
      this.categoryBudgetTotal = 0;
      this.remainingTotalValue = 0;
      this.totalProgressValue = 0;
      ToastUtil.show('预算数据加载失败，请稍后重试');
    } finally {
      this.loading = false;
    }
  }

  private buildRows(
    categories: CategoryModel[],
    budgets: BudgetModel[],
    spentByCategory: Map<number, number>
  ): BudgetRow[] {
    const budgetMap = new Map<number, BudgetModel>();
    budgets.forEach((item: BudgetModel) => {
      budgetMap.set(item.categoryId, item);
    });
    return categories.map((category: CategoryModel) => {
      const budget = budgetMap.get(category.id || 0);
      const row: BudgetRow = {
        categoryId: category.id || 0,
        categoryName: category.name,
        categoryColor: category.color,
        budgetText: budget ? `${budget.amount}` : '0',
        spent: spentByCategory.get(category.id || 0) || 0
      };
      return row;
    });
  }

  private mergeSpentMaps(primary: Map<number, number>, fallback: Map<number, number>): Map<number, number> {
    const result = new Map<number, number>();
    primary.forEach((amount: number, categoryId: number) => {
      result.set(categoryId, Math.abs(amount));
    });
    fallback.forEach((amount: number, categoryId: number) => {
      result.set(categoryId, Math.max(result.get(categoryId) || 0, Math.abs(amount)));
    });
    return result;
  }

  private async saveBudget(): Promise<void> {
    try {
      this.loading = true;
      await AppDatabase.getInstance().init(getContext(this));
      const month = DateUtil.monthKey(this.anchorTime);
      const total = this.parseAmount(this.totalBudgetText);
      this.totalBudgetValue = total;
      await this.budgetRepository.upsertMonthlyBudget(0, total, month);
      for (const row of this.rows) {
        await this.budgetRepository.upsertMonthlyBudget(row.categoryId, this.parseAmount(row.budgetText), month);
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

  private categoryBudgetAmount(budgets: BudgetModel[]): number {
    return budgets.reduce((total: number, item: BudgetModel) => {
      return item.categoryId > 0 ? total + item.amount : total;
    }, 0);
  }

  private effectiveBudgetAmount(): number {
    const textBudget = this.parseAmount(this.totalBudgetText);
    const totalBudget = textBudget > 0 ? textBudget : this.totalBudgetValue;
    return totalBudget > 0 ? totalBudget : this.categoryBudgetTotal;
  }

  private rowProgress(row: BudgetRow): number {
    const budget = this.parseAmount(row.budgetText);
    if (budget <= 0) {
      return 0;
    }
    return Math.min(100, Math.round(row.spent / budget * 100));
  }

  private totalProgress(): number {
    const total = this.effectiveBudgetAmount();
    if (total <= 0) {
      return 0;
    }
    return Math.min(100, Math.round(this.spentTotal / total * 100));
  }

  private remainingTotal(): number {
    return Math.max(0, this.effectiveBudgetAmount() - this.spentTotal);
  }

  private refreshBudgetStats(): void {
    this.remainingTotalValue = this.remainingTotal();
    this.totalProgressValue = this.totalProgress();
  }

  private parseAmount(value: string): number {
    const normalized = this.normalizeAmount(value);
    return Number(normalized) || 0;
  }

  private normalizeAmount(value: string): string {
    const cleaned = value.replace(/[^0-9.]/g, '');
    const parts = cleaned.split('.');
    if (parts.length <= 1) {
      return cleaned;
    }
    return `${parts[0]}.${parts.slice(1).join('').substring(0, 2)}`;
  }

  private formatBudgetInput(value: number): string {
    return value > 0 ? `${value}` : '0';
  }

  private monthLabel(): string {
    const date = new Date(this.anchorTime);
    return `${date.getFullYear()} 年 ${date.getMonth() + 1} 月`;
  }
}
