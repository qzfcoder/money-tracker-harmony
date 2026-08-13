import { router } from '@kit.ArkUI';
import { CategoryModel } from '../model/Category';
import { RecordListItem, RecordType } from '../model/Record';
import { CategoryRepository } from '../repository/CategoryRepository';
import { RecordRepository, RecordSearchOptions } from '../repository/RecordRepository';
import { AppColors, AppRadius, AppSpace, Breakpoints, LayoutSizes } from '../constants/DesignSystem';
import { ROUTES } from '../constants/RouteConstants';
import { DateUtil } from '../utils/DateUtil';
import { RecordItem } from '../components/RecordItem';
import { AppDatabase } from '../database/AppDatabase';

interface DatePickerResult {
  year?: number;
  month?: number;
  day?: number;
}

enum SearchRange {
  ALL = 'all',
  WEEK = 'week',
  MONTH = 'month',
  QUARTER = 'quarter',
  YEAR = 'year',
  CUSTOM = 'custom'
}

enum SearchType {
  ALL = 'all',
  EXPENSE = 'expense',
  INCOME = 'income',
  TRANSFER = 'transfer'
}

@Entry
@Component
struct SearchPage {
  private recordRepository: RecordRepository = new RecordRepository();
  private categoryRepository: CategoryRepository = new CategoryRepository();

  @State viewportWidth: number = 0;
  @State keyword: string = '';
  @State searchType: SearchType = SearchType.ALL;
  @State searchRange: SearchRange = SearchRange.MONTH;
  @State selectedCategoryId: number = 0;
  @State anchorTime: number = Date.now();
  @State startTime: number = DateUtil.startOfMonth();
  @State endTime: number = DateUtil.startOfNextMonth();
  @State customEditorVisible: boolean = false;
  @State draftCustomStartTime: number = DateUtil.addDays(DateUtil.startOfDay(), -29);
  @State draftCustomEndTime: number = DateUtil.startOfDay();
  @State categories: CategoryModel[] = [];
  @State results: RecordListItem[] = [];
  @State loading: boolean = false;

  aboutToAppear(): void {
    this.loadData();
  }

  build() {
    Column() {
      this.Header()

      Scroll() {
        Column({ space: 18 }) {
          this.SearchPanel()
          this.FilterPanel()
          this.RangePanel()
          this.ResultHeader()
          this.ResultList()
        }
        .width('100%')
        .constraintSize({ maxWidth: this.contentMaxWidth() })
        .alignSelf(ItemAlign.Center)
        .padding({ left: AppSpace.PAGE, right: AppSpace.PAGE, top: 8, bottom: 24 })
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
        Text('搜索')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .width('100%')
        Text('关键词、分类和时间范围筛选')
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
  private SearchPanel() {
    Column({ space: 12 }) {
      Text('关键字')
        .fontSize(13)
        .fontColor(AppColors.MUTED)
        .width('100%')
      TextInput({ text: this.keyword, placeholder: '输入分类、账户、备注或金额' })
        .fontSize(15)
        .height(52)
        .backgroundColor(AppColors.SURFACE_SOFT)
        .borderRadius(18)
        .padding({ left: 16, right: 16 })
        .onChange((value: string) => {
          this.keyword = value;
          this.runSearch();
        })
      Row({ space: 10 }) {
        this.ActionButton('搜索', () => this.runSearch())
        this.ActionButton('重置', () => this.resetFilters())
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
  private FilterPanel() {
    Column({ space: 12 }) {
      Text('类型')
        .fontSize(13)
        .fontColor(AppColors.MUTED)
        .width('100%')
      Row({ space: 5 }) {
        this.SegButton('全部', SearchType.ALL)
        this.SegButton('支出', SearchType.EXPENSE)
        this.SegButton('收入', SearchType.INCOME)
        this.SegButton('转账', SearchType.TRANSFER)
      }
      .height(44)
      .padding(4)
      .width('100%')
      .backgroundColor('#E7EAEE')
      .borderRadius(AppRadius.PILL)

      Text('分类')
        .fontSize(13)
        .fontColor(AppColors.MUTED)
        .width('100%')
      Scroll() {
        Row({ space: 8 }) {
          this.CategoryChip(0, '全部')
          ForEach(this.filteredCategories(), (item: CategoryModel) => {
            this.CategoryChip(item.id || 0, item.name)
          }, (item: CategoryModel) => `${item.id}`)
        }
        .height(42)
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .height(46)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 20, color: AppColors.SHADOW, offsetY: 8 })
  }

  @Builder
  private RangePanel() {
    Column({ space: 12 }) {
      Text('时间')
        .fontSize(13)
        .fontColor(AppColors.MUTED)
        .width('100%')
      Row({ space: 4 }) {
        this.RangeChip('全部', SearchRange.ALL)
        this.RangeChip('周', SearchRange.WEEK)
        this.RangeChip('月', SearchRange.MONTH)
        this.RangeChip('季', SearchRange.QUARTER)
        this.RangeChip('年', SearchRange.YEAR)
        this.RangeChip('自定义', SearchRange.CUSTOM)
      }
      .height(44)
      .padding(4)
      .width('100%')
      .backgroundColor('#E7EAEE')
      .borderRadius(AppRadius.PILL)

      Row() {
        Button('‹')
          .fontSize(24)
          .fontColor(this.searchRange === SearchRange.ALL ? AppColors.FAINT : AppColors.CHART_BLUE)
          .width(42)
          .height(34)
          .backgroundColor(AppColors.SURFACE_TINT)
          .borderRadius(17)
          .enabled(this.searchRange !== SearchRange.ALL)
          .onClick(() => this.movePrevious())
        Text(this.rangeLabel())
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .maxLines(1)
        Button('›')
          .fontSize(24)
          .fontColor(this.searchRange === SearchRange.ALL ? AppColors.FAINT : AppColors.CHART_BLUE)
          .width(42)
          .height(34)
          .backgroundColor(AppColors.SURFACE_TINT)
          .borderRadius(17)
          .enabled(this.searchRange !== SearchRange.ALL)
          .onClick(() => this.moveNext())
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
            Button('确定')
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
  private ResultHeader() {
    Row() {
      Text('结果')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.INK)
      Blank()
      Text(`${this.results.length} 条`)
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
  private ResultList() {
    Column({ space: 10 }) {
      if (this.loading) {
        this.EmptyState('正在加载', '请稍等片刻')
      } else if (this.results.length === 0) {
        this.EmptyState('没有匹配的账单', '换个关键词或时间范围再试试')
      } else {
        ForEach(this.results, (item: RecordListItem) => {
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
  private EmptyState(title: string, subtitle: string) {
    Column({ space: 8 }) {
      Text(title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.INK)
      Text(subtitle)
        .fontSize(13)
        .fontColor(AppColors.MUTED)
    }
    .width('100%')
    .height(112)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 18, color: AppColors.SHADOW, offsetY: 8 })
  }

  @Builder
  private ActionButton(label: string, onClick: () => void) {
    Button(label)
      .fontSize(14)
      .fontWeight(FontWeight.Bold)
      .fontColor(AppColors.CHART_BLUE)
      .height(42)
      .layoutWeight(1)
      .backgroundColor(AppColors.SURFACE_TINT)
      .borderRadius(AppRadius.PILL)
      .onClick(onClick)
  }

  @Builder
  private SegButton(label: string, type: SearchType) {
    Text(label)
      .fontSize(13)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.searchType === type ? AppColors.INK : AppColors.MUTED)
      .height(36)
      .layoutWeight(1)
      .textAlign(TextAlign.Center)
      .backgroundColor(this.searchType === type ? AppColors.SURFACE : '#00000000')
      .borderRadius(AppRadius.PILL)
      .shadow(this.searchType === type ? { radius: 10, color: AppColors.SHADOW, offsetY: 4 } : { radius: 0, color: '#00000000', offsetY: 0 })
      .onClick(() => {
        this.searchType = type;
        this.runSearch();
      })
  }

  @Builder
  private RangeChip(label: string, range: SearchRange) {
    Text(label)
      .fontSize(label === '自定义' ? 12 : 13)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.searchRange === range ? AppColors.INK : AppColors.MUTED)
      .height(36)
      .layoutWeight(label === '自定义' ? 1.35 : 1)
      .padding({ left: 2, right: 2 })
      .textAlign(TextAlign.Center)
      .backgroundColor(this.searchRange === range ? AppColors.SURFACE : '#00000000')
      .borderRadius(AppRadius.PILL)
      .shadow(this.searchRange === range ? { radius: 10, color: AppColors.SHADOW, offsetY: 4 } : { radius: 0, color: '#00000000', offsetY: 0 })
      .onClick(() => {
        if (range === SearchRange.CUSTOM) {
          this.openCustomEditor();
        } else {
          this.searchRange = range;
          this.customEditorVisible = false;
          this.applyRange();
          this.runSearch();
        }
      })
  }

  @Builder
  private CategoryChip(categoryId: number, label: string) {
    Text(label)
      .fontSize(13)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.selectedCategoryId === categoryId ? AppColors.SURFACE : AppColors.INK)
      .height(38)
      .padding({ left: 14, right: 14 })
      .textAlign(TextAlign.Center)
      .backgroundColor(this.selectedCategoryId === categoryId ? AppColors.CHART_BLUE : AppColors.SURFACE_SOFT)
      .borderRadius(AppRadius.PILL)
      .shadow(this.selectedCategoryId === categoryId ? { radius: 10, color: '#3B8CFF30', offsetY: 4 } : { radius: 0, color: '#00000000', offsetY: 0 })
      .onClick(() => {
        this.selectedCategoryId = categoryId;
        this.runSearch();
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

  private async loadData(): Promise<void> {
    try {
      await AppDatabase.getInstance().init(getContext(this));
      this.categories = await this.categoryRepository.listAll();
      this.applyRange();
      await this.runSearch();
    } catch (error) {
      this.loading = false;
    }
  }

  private async runSearch(): Promise<void> {
    try {
      this.loading = true;
      await AppDatabase.getInstance().init(getContext(this));
      const options: RecordSearchOptions = {
        keyword: this.keyword,
        type: this.resolveType(),
        categoryId: this.selectedCategoryId,
        limit: 200
      };
      if (this.searchRange !== SearchRange.ALL) {
        options.startTime = this.startTime;
        options.endTime = this.endTime;
      }
      this.results = await this.recordRepository.searchRecords(options);
    } catch (error) {
      this.results = [];
    } finally {
      this.loading = false;
    }
  }

  private resetFilters(): void {
    this.keyword = '';
    this.searchType = SearchType.ALL;
    this.searchRange = SearchRange.MONTH;
    this.selectedCategoryId = 0;
    this.anchorTime = Date.now();
    this.customEditorVisible = false;
    this.applyRange();
    this.runSearch();
  }

  private applyRange(): void {
    if (this.searchRange === SearchRange.ALL) {
      this.startTime = 0;
      this.endTime = DateUtil.addDays(DateUtil.startOfDay(Date.now()), 1);
      return;
    }
    if (this.searchRange === SearchRange.WEEK) {
      const start = DateUtil.startOfWeek(this.anchorTime);
      this.startTime = start;
      this.endTime = DateUtil.addDays(start, 7);
      return;
    }
    if (this.searchRange === SearchRange.MONTH) {
      this.startTime = DateUtil.startOfMonth(this.anchorTime);
      this.endTime = DateUtil.startOfNextMonth(this.anchorTime);
      return;
    }
    if (this.searchRange === SearchRange.QUARTER) {
      this.startTime = DateUtil.startOfQuarter(this.anchorTime);
      this.endTime = DateUtil.startOfNextQuarter(this.anchorTime);
      return;
    }
    if (this.searchRange === SearchRange.YEAR) {
      this.startTime = DateUtil.startOfYear(this.anchorTime);
      this.endTime = DateUtil.startOfNextYear(this.anchorTime);
    }
  }

  private async movePrevious(): Promise<void> {
    if (this.searchRange === SearchRange.WEEK) {
      this.anchorTime = DateUtil.addDays(this.anchorTime, -7);
    } else if (this.searchRange === SearchRange.MONTH) {
      const date = new Date(this.anchorTime);
      this.anchorTime = new Date(date.getFullYear(), date.getMonth() - 1, 1).getTime();
    } else if (this.searchRange === SearchRange.QUARTER) {
      const date = new Date(this.anchorTime);
      this.anchorTime = new Date(date.getFullYear(), date.getMonth() - 3, 1).getTime();
    } else if (this.searchRange === SearchRange.YEAR) {
      const date = new Date(this.anchorTime);
      this.anchorTime = new Date(date.getFullYear() - 1, 0, 1).getTime();
    } else if (this.searchRange === SearchRange.CUSTOM) {
      const span = this.endTime - this.startTime;
      this.startTime -= span;
      this.endTime -= span;
      this.draftCustomStartTime = this.startTime;
      this.draftCustomEndTime = this.endTime - 1;
    }
    if (this.searchRange !== SearchRange.CUSTOM) {
      this.applyRange();
    }
    await this.runSearch();
  }

  private async moveNext(): Promise<void> {
    if (this.searchRange === SearchRange.WEEK) {
      this.anchorTime = DateUtil.addDays(this.anchorTime, 7);
    } else if (this.searchRange === SearchRange.MONTH) {
      const date = new Date(this.anchorTime);
      this.anchorTime = new Date(date.getFullYear(), date.getMonth() + 1, 1).getTime();
    } else if (this.searchRange === SearchRange.QUARTER) {
      const date = new Date(this.anchorTime);
      this.anchorTime = new Date(date.getFullYear(), date.getMonth() + 3, 1).getTime();
    } else if (this.searchRange === SearchRange.YEAR) {
      const date = new Date(this.anchorTime);
      this.anchorTime = new Date(date.getFullYear() + 1, 0, 1).getTime();
    } else if (this.searchRange === SearchRange.CUSTOM) {
      const span = this.endTime - this.startTime;
      this.startTime += span;
      this.endTime += span;
      this.draftCustomStartTime = this.startTime;
      this.draftCustomEndTime = this.endTime - 1;
    }
    if (this.searchRange !== SearchRange.CUSTOM) {
      this.applyRange();
    }
    await this.runSearch();
  }

  private openCustomEditor(): void {
    this.searchRange = SearchRange.CUSTOM;
    this.draftCustomStartTime = this.startTime > 0 ? this.startTime : DateUtil.addDays(DateUtil.startOfDay(), -29);
    this.draftCustomEndTime = this.endTime > 0 ? this.endTime - 1 : DateUtil.startOfDay();
    this.customEditorVisible = true;
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
    this.customEditorVisible = false;
    this.searchRange = SearchRange.CUSTOM;
    this.startTime = DateUtil.startOfDay(this.draftCustomStartTime);
    this.endTime = DateUtil.addDays(DateUtil.startOfDay(this.draftCustomEndTime), 1);
    await this.runSearch();
  }

  private rangeLabel(): string {
    if (this.searchRange === SearchRange.ALL) {
      return '全部账单';
    }
    return DateUtil.rangeLabel(this.startTime, this.endTime);
  }

  private fullDateLabel(timestamp: number): string {
    const date = new Date(timestamp);
    const month = `${date.getMonth() + 1}`.padStart(2, '0');
    const day = `${date.getDate()}`.padStart(2, '0');
    return `${date.getFullYear()}/${month}/${day}`;
  }

  private resolveType(): RecordType.EXPENSE | RecordType.INCOME | RecordType.TRANSFER | 0 {
    if (this.searchType === SearchType.EXPENSE) {
      return RecordType.EXPENSE;
    }
    if (this.searchType === SearchType.INCOME) {
      return RecordType.INCOME;
    }
    if (this.searchType === SearchType.TRANSFER) {
      return RecordType.TRANSFER;
    }
    return 0;
  }

  private filteredCategories(): CategoryModel[] {
    if (this.searchType === SearchType.EXPENSE) {
      return this.categories.filter((item: CategoryModel) => item.type === RecordType.EXPENSE);
    }
    if (this.searchType === SearchType.INCOME) {
      return this.categories.filter((item: CategoryModel) => item.type === RecordType.INCOME);
    }
    return this.categories;
  }

  private contentMaxWidth(): number {
    return this.viewportWidth >= Breakpoints.DESKTOP ? LayoutSizes.CONTENT_MAX : LayoutSizes.CONTENT_COMPACT;
  }
}
