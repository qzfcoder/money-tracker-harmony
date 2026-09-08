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

interface IconPreset {
  key: string;
  label: string;
}

@Entry
@Component
struct CategoryManage {
  private repository: CategoryRepository = new CategoryRepository();
  private expenseIconPresets: IconPreset[] = [
    { key: 'food', label: '餐' }, { key: 'traffic', label: '行' }, { key: 'shopping', label: '购' },
    { key: 'home', label: '家' }, { key: 'coffee', label: '饮' }, { key: 'medical', label: '医' },
    { key: 'study', label: '学' }, { key: 'travel', label: '旅' }, { key: 'fruit', label: '果' },
    { key: 'snack', label: '零' }, { key: 'pet', label: '宠' }, { key: 'movie', label: '影' },
    { key: 'sport', label: '动' }, { key: 'gift', label: '礼' }, { key: 'phone', label: '话' },
    { key: 'water', label: '水' }, { key: 'electricity', label: '电' }, { key: 'rent', label: '租' },
    { key: 'beauty', label: '美' }, { key: 'other', label: '其' }
  ];
  private incomeIconPresets: IconPreset[] = [
    { key: 'salary', label: '薪' }, { key: 'bonus', label: '奖' }, { key: 'parttime', label: '兼' },
    { key: 'refund', label: '退' }, { key: 'investment', label: '投' }, { key: 'interest', label: '息' },
    { key: 'redpacket', label: '红' }, { key: 'reimburse', label: '报' }, { key: 'other_income', label: '收' }
  ];
  private colorPresets: string[] = [
    '#2F7EF7', '#21BA78', '#FFB33D', '#FF6F8D', '#826CFF', '#19BFAF',
    '#F46F80', '#657A55', '#36A2EB', '#F59E0B', '#10B981', '#EF4444'
  ];

  @State viewportWidth: number = 0;
  @State manageType: ManageType = ManageType.EXPENSE;
  @State categories: CategoryModel[] = [];
  @State selectedId: number = 0;
  @State nameText: string = '';
  @State iconText: string = '';
  @State colorText: string = '#4E7FF2';
  @State sortText: string = '0';
  @State iconPickerVisible: boolean = false;
  @State colorPickerVisible: boolean = false;
  @State editDialogVisible: boolean = false;

  aboutToAppear(): void {
    this.loadCategories();
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
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

      if (this.editDialogVisible) {
        this.EditDialog()
      }
    }
    .width('100%')
    .height('100%')
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
        Text('新增分类')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
        Blank()
        Text('填写后保存')
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.MUTED)
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
      this.IconPicker()
      this.ColorPicker()
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
          .backgroundColor(AppColors.softDanger())
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
  private IconPicker() {
    Column({ space: 8 }) {
      Row() {
        Column({ space: 4 }) {
          Text('图标')
            .fontSize(12)
            .fontColor(AppColors.MUTED)
            .width('100%')
          Text(this.currentIconLabel())
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.INK)
            .width('100%')
            .maxLines(1)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Text(this.iconPickerVisible ? '收起' : '更换')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.CHART_BLUE)
          .padding({ left: 14, right: 14, top: 7, bottom: 7 })
          .backgroundColor(AppColors.SURFACE_TINT)
          .borderRadius(AppRadius.PILL)
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 10, bottom: 10 })
      .backgroundColor(AppColors.SURFACE_SOFT)
      .borderRadius(16)
      .onClick(() => {
        this.iconPickerVisible = !this.iconPickerVisible;
      })

      if (this.iconPickerVisible) {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.currentIconPresets(), (item: IconPreset) => {
            Text(item.label)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.iconText === item.key ? AppColors.SURFACE : this.colorText)
              .width(42)
              .height(42)
              .textAlign(TextAlign.Center)
              .backgroundColor(this.iconText === item.key ? this.colorText : AppColors.SURFACE_SOFT)
              .border({ width: 1, color: this.iconText === item.key ? this.colorText : AppColors.LINE })
              .borderRadius(14)
              .margin({ right: 8, bottom: 8 })
              .onClick(() => {
                this.iconText = item.key;
                this.iconPickerVisible = false;
              })
          }, (item: IconPreset) => item.key)
        }
        .width('100%')
      }
    }
    .width('100%')
  }

  @Builder
  private ColorPicker() {
    Column({ space: 8 }) {
      Row() {
        Column({ space: 4 }) {
          Text('颜色')
            .fontSize(12)
            .fontColor(AppColors.MUTED)
            .width('100%')
          Text(this.colorText)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.colorText)
            .width('100%')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Text(this.colorPickerVisible ? '收起' : '更换')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.CHART_BLUE)
          .padding({ left: 14, right: 14, top: 7, bottom: 7 })
          .backgroundColor(AppColors.SURFACE_TINT)
          .borderRadius(AppRadius.PILL)
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 10, bottom: 10 })
      .backgroundColor(AppColors.SURFACE_SOFT)
      .borderRadius(16)
      .onClick(() => {
        this.colorPickerVisible = !this.colorPickerVisible;
      })

      if (this.colorPickerVisible) {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.colorPresets, (color: string) => {
            Text(this.colorText === color ? '✓' : '')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.SURFACE)
              .width(42)
              .height(32)
              .textAlign(TextAlign.Center)
              .backgroundColor(color)
              .border({ width: this.colorText === color ? 2 : 0, color: AppColors.INK })
              .borderRadius(12)
              .margin({ right: 8, bottom: 8 })
              .onClick(() => {
                this.colorText = color;
                this.colorPickerVisible = false;
              })
          }, (color: string) => color)
        }
        .width('100%')
      }
    }
    .width('100%')
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
        Text('长按分类卡片可拖动排序，也可使用右下角按钮微调')
          .fontSize(12)
          .fontColor(AppColors.MUTED)
          .lineHeight(18)
          .width('100%')

        List({ space: 12 }) {
          ForEach(this.categories, (item: CategoryModel) => {
            ListItem() {
              this.CategoryRow(item)
            }
          }, (item: CategoryModel) => `${item.id}`)
            .onMove((from: number, to: number) => {
              this.moveCategoryByIndex(from, to);
            })
        }
        .width('100%')
        .height(this.categoryListHeight())
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
  }

  @Builder
  private EditDialog() {
    Column() {
      Column({ space: 14 }) {
        Row() {
          Column({ space: 4 }) {
            Text('编辑分类')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.INK)
            Text('修改后保存即可生效')
              .fontSize(12)
              .fontColor(AppColors.MUTED)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          Button('×')
            .fontSize(20)
            .fontColor(AppColors.MUTED)
            .width(38)
            .height(38)
            .backgroundColor(AppColors.SURFACE_SOFT)
            .borderRadius(19)
            .onClick(() => this.closeEditDialog())
        }
        .width('100%')

        Scroll() {
          Column({ space: 12 }) {
            TextInput({ text: this.nameText, placeholder: '分类名称' })
              .height(50)
              .fontSize(15)
              .fontColor(AppColors.INK)
              .backgroundColor(AppColors.SURFACE_SOFT)
              .borderRadius(16)
              .padding({ left: 16, right: 16 })
              .onChange((value: string) => {
                this.nameText = value;
              })
            this.IconPicker()
            this.ColorPicker()
            TextInput({ text: this.sortText, placeholder: '排序值' })
              .height(50)
              .fontSize(15)
              .fontColor(AppColors.INK)
              .type(InputType.Number)
              .backgroundColor(AppColors.SURFACE_SOFT)
              .borderRadius(16)
              .padding({ left: 16, right: 16 })
              .onChange((value: string) => {
                this.sortText = value;
              })
          }
          .width('100%')
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)

        Row({ space: 8 }) {
          Button('取消')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.MUTED)
            .width(76)
            .height(44)
            .backgroundColor(AppColors.SURFACE_SOFT)
            .borderRadius(AppRadius.PILL)
            .onClick(() => this.closeEditDialog())
          Button('重置')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.EXPENSE)
            .width(76)
            .height(44)
            .backgroundColor(AppColors.softDanger())
            .borderRadius(AppRadius.PILL)
            .onClick(() => this.resetEditDraft())
          Button('保存修改')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.SURFACE)
            .layoutWeight(1)
            .height(44)
            .backgroundColor(AppColors.CHART_BLUE)
            .borderRadius(AppRadius.PILL)
            .onClick(() => this.save())
        }
        .width('100%')
      }
      .width('92%')
      .constraintSize({ maxWidth: 560, maxHeight: 700 })
      .height('82%')
      .padding(18)
      .backgroundColor(AppColors.SURFACE)
      .borderRadius(AppRadius.CARD)
      .shadow({ radius: 28, color: AppColors.SHADOW, offsetY: 12 })
      .onClick(() => {})
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#00000066')
  }

  @Builder
  private CategoryRow(item: CategoryModel) {
    Column({ space: 10 }) {
      Row({ space: 12 }) {
        Text(this.iconLabel(item.icon, item.name))
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
              .layoutWeight(1)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
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
          .width('100%')
          Text(`${item.icon} · 排序 ${item.sortOrder}`)
            .fontSize(12)
            .fontColor(AppColors.MUTED)
            .maxLines(1)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')

      Row({ space: 6 }) {
        Button('↑  上移')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.CHART_BLUE)
          .layoutWeight(1)
          .height(36)
          .backgroundColor(AppColors.SURFACE_TINT)
          .borderRadius(18)
          .onClick(() => this.moveCategory(item, -1))
        Button('↓  下移')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.CHART_BLUE)
          .layoutWeight(1)
          .height(36)
          .backgroundColor(AppColors.SURFACE_TINT)
          .borderRadius(18)
          .onClick(() => this.moveCategory(item, 1))
        Button('✎  编辑')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .layoutWeight(1)
          .height(36)
          .backgroundColor(AppColors.SURFACE_SOFT)
          .borderRadius(18)
          .onClick(() => this.pickForEdit(item))
        if (!item.isDefault) {
          Button('×  删除')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.EXPENSE)
            .layoutWeight(1)
            .height(36)
            .backgroundColor(AppColors.softDanger())
            .borderRadius(18)
            .onClick(() => this.remove(item))
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
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
    this.iconPickerVisible = false;
    this.colorPickerVisible = false;
    this.editDialogVisible = true;
  }

  private syncForm(item: CategoryModel): void {
    this.nameText = item.name;
    this.iconText = item.icon;
    this.colorText = item.color;
    this.sortText = `${item.sortOrder}`;
  }

  private async moveCategory(item: CategoryModel, direction: number): Promise<void> {
    if (!item.id) {
      return;
    }
    const index = this.categories.findIndex((category: CategoryModel) => category.id === item.id);
    const nextIndex = index + direction;
    if (index < 0 || nextIndex < 0 || nextIndex >= this.categories.length) {
      return;
    }
    const target = this.categories[nextIndex];
    if (!target.id) {
      return;
    }
    try {
      await AppDatabase.getInstance().init(getContext(this));
      await this.repository.updateSortOrder(item.id, target.sortOrder);
      await this.repository.updateSortOrder(target.id, item.sortOrder);
      await this.loadCategories();
      ToastUtil.show('排序已更新');
    } catch (error) {
      ToastUtil.show('排序失败，请重试');
    }
  }

  private moveCategoryByIndex(from: number, to: number): void {
    if (from < 0 || to < 0 || from >= this.categories.length || to >= this.categories.length || from === to) {
      return;
    }
    const list = this.categories.slice();
    const moving = list.splice(from, 1);
    if (moving.length === 0) {
      return;
    }
    list.splice(to, 0, moving[0]);
    this.categories = list;
    this.persistCategoryOrder();
  }

  private async persistCategoryOrder(): Promise<void> {
    try {
      await AppDatabase.getInstance().init(getContext(this));
      for (let index = 0; index < this.categories.length; index++) {
        const item = this.categories[index];
        if (item.id && item.id > 0) {
          const sortOrder = index + 1;
          item.sortOrder = sortOrder;
          await this.repository.updateSortOrder(item.id, sortOrder);
        }
      }
      ToastUtil.show('排序已更新');
    } catch (error) {
      ToastUtil.show('排序失败，请重试');
      await this.loadCategories();
    }
  }

  private currentIconPresets(): IconPreset[] {
    return this.manageType === ManageType.EXPENSE ? this.expenseIconPresets : this.incomeIconPresets;
  }

  private iconLabel(icon: string, name: string): string {
    const preset = this.expenseIconPresets.concat(this.incomeIconPresets).find((item: IconPreset) => item.key === icon);
    if (preset) {
      return preset.label;
    }
    return name.substring(0, 1);
  }

  private resetForm(): void {
    this.selectedId = 0;
    this.editDialogVisible = false;
    this.nameText = '';
    this.iconText = this.manageType === ManageType.EXPENSE ? 'food' : 'salary';
    this.colorText = this.manageType === ManageType.EXPENSE ? '#4E7FF2' : '#2D8E76';
    this.sortText = `${this.nextSortOrder()}`;
    this.iconPickerVisible = false;
    this.colorPickerVisible = false;
  }

  private resetEditDraft(): void {
    const selected = this.currentSelected();
    if (selected) {
      this.syncForm(selected);
    }
    this.iconPickerVisible = false;
    this.colorPickerVisible = false;
  }

  private closeEditDialog(): void {
    this.editDialogVisible = false;
    this.resetForm();
  }

  private currentIconLabel(): string {
    const preset = this.currentIconPresets().find((item: IconPreset) => item.key === this.iconText);
    if (preset) {
      return `${preset.label} · ${preset.key}`;
    }
    return this.iconText || '未选择';
  }

  private nextSortOrder(): number {
    if (this.categories.length === 0) {
      return 1;
    }
    const max = this.categories.reduce((result: number, item: CategoryModel) => Math.max(result, item.sortOrder), 0);
    return max + 1;
  }

  private categoryListHeight(): number {
    return Math.min(620, Math.max(112, this.categories.length * 112));
  }

  private currentSelected(): CategoryModel | undefined {
    return this.categories.find((item: CategoryModel) => item.id === this.selectedId);
  }

  private resolveType(): RecordType.EXPENSE | RecordType.INCOME {
    return this.manageType === ManageType.EXPENSE ? RecordType.EXPENSE : RecordType.INCOME;
  }
}
