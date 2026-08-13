import { AppColors } from '../constants/DesignSystem';

@Component
export struct CategoryIcon {
  @Prop name: string = '';
  @Prop color: string = '#657A55';
  @Prop selected: boolean = false;

  build() {
    Column({ space: 6 }) {
      Column() {
        Text(this.shortLabel())
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.selected ? AppColors.SURFACE : this.color)
          .textAlign(TextAlign.Center)
          .maxLines(1)
      }
      .width(52)
      .height(52)
      .justifyContent(FlexAlign.Center)
      .borderRadius(12)
      .backgroundColor(this.selected ? this.color : AppColors.SURFACE_SOFT)
      .border({ width: 1, color: this.selected ? this.color : AppColors.LINE })
      .shadow(this.selected ? { radius: 10, color: AppColors.SHADOW, offsetY: 4 } : { radius: 0, color: '#00000000', offsetY: 0 })

      Text(this.name)
        .fontSize(11)
        .fontColor(AppColors.MUTED)
        .maxLines(1)
        .textAlign(TextAlign.Center)
        .width('100%')
    }
    .width('25%')
    .constraintSize({ minWidth: 84, maxWidth: 124 })
    .padding({ top: 8, bottom: 8 })
  }

  private shortLabel(): string {
    if (this.name.length <= 2) {
      return this.name;
    }
    return this.name.substring(0, 2);
  }
}
