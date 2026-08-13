import { router } from '@kit.ArkUI';
import { CategoryModel } from '../model/Category';
import { RecordType } from '../model/Record';
import { CategoryRepository } from '../repository/CategoryRepository';
import { AppColors, AppRadius, AppSpace, LayoutSizes } from '../constants/DesignSystem';
import { AppDatabase } from '../database/AppDatabase';
import { ToastUtil } from '../utils/ToastUtil';

@Entry
@Component
struct CategoryPicker {
  private repository: CategoryRepository = new CategoryRepository();

  @State type: RecordType.EXPENSE | RecordType.INCOME = RecordType.EXPENSE;
  @State categories: CategoryModel[] = [];

  aboutToAppear(): void {
    this.loadCategories();
  }

  build() {
    Column() {
      this.Header()
      Scroll() {
        Column({ space: 16 }) {
          this.TypeTabs()
          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
            ForEach(this.categories, (item: CategoryModel) => {
              this.CategoryCell(item)
            }, (item: CategoryModel) => `${item.id}`)
          }
          .width('100%')
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
        Text('选择分类')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .width('100%')
        Text('浏览支出和收入分类')
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
  private TypeTabs() {
    Row({ space: 8 }) {
      this.TypeTab('支出', RecordType.EXPENSE)
      this.TypeTab('收入', RecordType.INCOME)
    }
    .width('100%')
  }

  @Builder
  private TypeTab(label: string, type: RecordType.EXPENSE | RecordType.INCOME) {
    Text(label)
      .fontSize(14)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.type === type ? AppColors.SURFACE : AppColors.INK)
      .height(42)
      .layoutWeight(1)
      .textAlign(TextAlign.Center)
      .backgroundColor(this.type === type ? AppColors.CHART_BLUE : AppColors.SURFACE_SOFT)
      .borderRadius(AppRadius.PILL)
      .onClick(() => {
        this.type = type;
        this.loadCategories();
      })
  }

  @Builder
  private CategoryCell(item: CategoryModel) {
    Column({ space: 8 }) {
      Text(item.name.substring(0, 1))
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(item.color)
        .width(52)
        .height(52)
        .textAlign(TextAlign.Center)
        .backgroundColor(AppColors.SURFACE_TINT)
        .borderRadius(18)
      Text(item.name)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.INK)
        .maxLines(1)
    }
    .width('31%')
    .height(96)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 16, color: AppColors.SHADOW, offsetY: 6 })
    .margin({ bottom: 12 })
    .onClick(() => router.back())
  }

  private async loadCategories(): Promise<void> {
    try {
      await AppDatabase.getInstance().init(getContext(this));
      this.categories = await this.repository.listByType(this.type);
    } catch (error) {
      this.categories = [];
      ToastUtil.show('分类加载失败，请重试');
    }
  }
}
