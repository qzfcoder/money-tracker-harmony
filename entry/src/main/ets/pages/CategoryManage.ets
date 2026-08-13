import { router } from '@kit.ArkUI';
import { CategoryModel } from '../model/Category';
import { RecordType } from '../model/Record';
import { CategoryRepository } from '../repository/CategoryRepository';
import { AppColors, AppRadius, AppSpace, LayoutSizes } from '../constants/DesignSystem';
import { AppDatabase } from '../database/AppDatabase';
import { ToastUtil } from '../utils/ToastUtil';

enum ManageType {
  EXPENSE = 'expense',
  INCOME = 'income'
}

@Entry
@Component
struct CategoryManage {
  private repository: CategoryRepository = new CategoryRepository();

  @State viewportWidth: number = 0;
  @State manageType: ManageType = ManageType.EXPENSE;
  @State categories: CategoryModel[] = [];
  @State selectedId: number = 0;
  @State nameText: string = '';
  @State iconText: string = '';
  @State colorText: string = '#4E7FF2';
  @State sortText: string = '0';

  aboutToAppear(): void {
    this.loadCategories();
  }

  build() {
    Column() {
      this.Header()

      Scroll() {
        Column({ space: 18 }) {
          this.TypeTabs()
          this.FormCard()
          this.ListCard()
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
        Text('分类管理')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .width('100%')
        Text('新增、编辑、删除分类和排序')
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
      this.TypeTab('支出分类', ManageType.EXPENSE)
      this.TypeTab('收入分类', ManageType.INCOME)
    }
    .width('100%')
  }

  @Builder
  private TypeTab(label: string, type: ManageType) {
    Text(label)
      .fontSize(14)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.manageType === type ? AppColors.INK : AppColors.MUTED)
      .height(42)
      .layoutWeight(1)
      .textAlign(TextAlign.Center)
      .backgroundColor(this.manageType === type ? AppColors.SURFACE : AppColors.SURFACE_SOFT)
      .borderRadius(AppRadius.PILL)
      .shadow(this.manageType === type ? { radius: 10, color: AppColors.SHADOW, offsetY: 4 } : { radius: 0, color: '#00000000', offsetY: 0 })
      .onClick(() => {
        this.manageType = type;
        this.selectedId = 0;
        this.loadCategories();
      })
  }

  @Builder
  private FormCard() {
    Column({ space: 14 }) {
      Row() {
        Text(this.selectedId > 0 ? '编辑分类' : '新增分类')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
        Blank()
        if (this.selectedId > 0) {
          Text('已选择')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.CHART_BLUE)
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor(AppColors.SURFACE_TINT)
            .borderRadius(AppRadius.PILL)
        }
      }
      .width('100%')

      TextInput({ text: this.nameText, placeholder: '分类名称' })
        .height(50)
        .backgroundColor(AppColors.SURFACE_SOFT)
        .borderRadius(16)
        .padding({ left: 16, right: 16 })
        .onChange((value: string) => {
          this.nameText = value;
        })
      Row({ space: 10 }) {
        TextInput({ text: this.iconText, placeholder: '图标标识，如 food' })
          .height(50)
          .layoutWeight(1)
          .backgroundColor(AppColors.SURFACE_SOFT)
          .borderRadius(16)
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => {
            this.iconText = value;
          })
        TextInput({ text: this.colorText, placeholder: '#4E7FF2' })
          .height(50)
          .layoutWeight(1)
          .backgroundColor(AppColors.SURFACE_SOFT)
          .borderRadius(16)
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => {
            this.colorText = value;
          })
      }
      Row({ space: 10 }) {
        TextInput({ text: this.sortText, placeholder: '排序值' })
          .height(50)
          .layoutWeight(1)
          .type(InputType.Number)
          .backgroundColor(AppColors.SURFACE_SOFT)
          .borderRadius(16)
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => {
            this.sortText = value;
          })
        Button('保存')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.SURFACE)
          .height(50)
          .layoutWeight(1)
          .backgroundColor(AppColors.CHART_BLUE)
          .borderRadius(16)
          .onClick(() => this.save())
      }
      Row({ space: 10 }) {
        Button('新建')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.MUTED)
          .height(40)
          .layoutWeight(1)
          .backgroundColor(AppColors.SURFACE_TINT)
          .borderRadius(AppRadius.PILL)
          .onClick(() => this.resetForm())
        Button('清空')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.EXPENSE)
          .height(40)
          .layoutWeight(1)
          .backgroundColor('#FCE9E4')
          .borderRadius(AppRadius.PILL)
          .onClick(() => this.resetForm())
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 20, color: AppColors.SHADOW, offsetY: 8 })
  }

  @Builder
  private ListCard() {
    Column({ space: 12 }) {
      Row() {
        Text('分类列表')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
        Blank()
        Text(`${this.categories.length} 项`)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.LEDGER)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor(AppColors.SURFACE_TINT)
          .borderRadius(AppRadius.PILL)
      }
      .width('100%')

      if (this.categories.length === 0) {
        this.EmptyState('没有分类', '新增一个分类开始管理')
      } else {
        ForEach(this.categories, (item: CategoryModel) => {
          this.CategoryRow(item)
        }, (item: CategoryModel) => `${item.id}`)
      }
    }
    .width('100%')
  }

  @Builder
  private CategoryRow(item: CategoryModel) {
    Row({ space: 12 }) {
      Text(item.name.substring(0, 1))
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(item.color)
        .width(44)
        .height(44)
        .textAlign(TextAlign.Center)
        .backgroundColor(AppColors.SURFACE_TINT)
        .borderRadius(14)

      Column({ space: 4 }) {
        Row({ space: 8 }) {
          Text(item.name)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.INK)
          if (item.isDefault) {
            Text('默认')
              .fontSize(11)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.CHART_BLUE)
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .backgroundColor(AppColors.SURFACE_TINT)
              .borderRadius(AppRadius.PILL)
          }
        }
        Text(`${item.icon} · 排序 ${item.sortOrder}`)
          .fontSize(12)
          .fontColor(AppColors.MUTED)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Row({ space: 6 }) {
        Button('⇅')
          .fontSize(14)
          .fontColor(AppColors.CHART_BLUE)
          .width(36)
          .height(36)
          .backgroundColor(AppColors.SURFACE_TINT)
          .borderRadius(18)
          .onClick(() => this.pickForEdit(item))
        Button('✎')
          .fontSize(14)
          .fontColor(AppColors.INK)
          .width(36)
          .height(36)
          .backgroundColor(AppColors.SURFACE_SOFT)
          .borderRadius(18)
          .onClick(() => this.pickForEdit(item))
        if (!item.isDefault) {
          Button('×')
            .fontSize(14)
            .fontColor(AppColors.EXPENSE)
            .width(36)
            .height(36)
            .backgroundColor('#FCE9E4')
            .borderRadius(18)
            .onClick(() => this.remove(item))
        }
      }
    }
    .width('100%')
    .height(68)
    .padding({ left: 16, right: 16 })
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 16, color: AppColors.SHADOW, offsetY: 6 })
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
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
  }

  private async loadCategories(): Promise<void> {
    try {
      await AppDatabase.getInstance().init(getContext(this));
      const type = this.resolveType();
      this.categories = await this.repository.listByType(type);
      if (this.selectedId > 0) {
        const current = this.categories.find((item: CategoryModel) => item.id === this.selectedId);
        if (current) {
          this.syncForm(current);
        }
      }
      if (this.selectedId === 0) {
        this.sortText = `${this.nextSortOrder()}`;
      }
    } catch (error) {
      this.categories = [];
      ToastUtil.show('分类加载失败，请重试');
    }
  }

  private async save(): Promise<void> {
    try {
      await AppDatabase.getInstance().init(getContext(this));
      const category: CategoryModel = {
        id: this.selectedId > 0 ? this.selectedId : undefined,
        name: this.nameText.trim() || '未命名分类',
        type: this.resolveType(),
        icon: this.iconText.trim() || 'cat',
        color: this.colorText.trim() || '#4E7FF2',
        sortOrder: Number(this.sortText) || this.nextSortOrder(),
        isDefault: this.selectedId > 0 ? this.currentSelected()?.isDefault || false : false,
        createTime: this.currentSelected()?.createTime || Date.now()
      };
      await this.repository.save(category);
      this.resetForm();
      await this.loadCategories();
      ToastUtil.show('分类已保存');
    } catch (error) {
      ToastUtil.show('分类保存失败，请重试');
    }
  }

  private async remove(item: CategoryModel): Promise<void> {
    if (!item.id) {
      return;
    }
    try {
      await AppDatabase.getInstance().init(getContext(this));
      await this.repository.deleteById(item.id);
      if (this.selectedId === item.id) {
        this.resetForm();
      }
      await this.loadCategories();
      ToastUtil.show('分类已删除');
    } catch (error) {
      ToastUtil.show('分类删除失败，请重试');
    }
  }

  private pickForEdit(item: CategoryModel): void {
    this.selectedId = item.id || 0;
    this.syncForm(item);
  }

  private syncForm(item: CategoryModel): void {
    this.nameText = item.name;
    this.iconText = item.icon;
    this.colorText = item.color;
    this.sortText = `${item.sortOrder}`;
  }

  private resetForm(): void {
    this.selectedId = 0;
    this.nameText = '';
    this.iconText = this.manageType === ManageType.EXPENSE ? 'food' : 'salary';
    this.colorText = this.manageType === ManageType.EXPENSE ? '#4E7FF2' : '#2D8E76';
    this.sortText = `${this.nextSortOrder()}`;
  }

  private nextSortOrder(): number {
    if (this.categories.length === 0) {
      return 1;
    }
    const max = this.categories.reduce((result: number, item: CategoryModel) => Math.max(result, item.sortOrder), 0);
    return max + 1;
  }

  private currentSelected(): CategoryModel | undefined {
    return this.categories.find((item: CategoryModel) => item.id === this.selectedId);
  }

  private resolveType(): RecordType.EXPENSE | RecordType.INCOME {
    return this.manageType === ManageType.EXPENSE ? RecordType.EXPENSE : RecordType.INCOME;
  }
}
