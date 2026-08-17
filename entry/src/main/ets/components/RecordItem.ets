import { RecordListItem, RecordType } from '../model/Record';
import { AppColors, AppRadius } from '../constants/DesignSystem';
import { DateUtil } from '../utils/DateUtil';
import { NumberUtil } from '../utils/NumberUtil';

@Component
export struct RecordItem {
  @Prop item: RecordListItem = {
    type: RecordType.EXPENSE,
    amount: 0,
    categoryId: 0,
    accountId: 0,
    recordTime: 0,
    remark: '',
    createTime: 0,
    updateTime: 0,
    categoryName: '',
    categoryIcon: '',
    categoryColor: '#657A55',
    accountName: ''
  };

  build() {
    Row({ space: 12 }) {
      Text(this.item.categoryName.substring(0, 1))
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.item.categoryColor)
        .width(42)
        .height(42)
        .textAlign(TextAlign.Center)
        .borderRadius(14)
        .backgroundColor(this.softColor())

      Column({ space: 4 }) {
        Text(this.item.categoryName)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.INK)
          .width('100%')
          .maxLines(1)
        Text(`${this.item.type === RecordType.EXPENSE ? '支出' : '收入'} · ${DateUtil.shortDay(this.item.recordTime)} · ${this.item.remark || this.item.accountName}`)
          .fontSize(12)
          .fontColor(AppColors.MUTED)
          .width('100%')
          .maxLines(1)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Column({ space: 4 }) {
        Text(`${this.item.type === RecordType.EXPENSE ? '-' : '+'}${NumberUtil.compactMoney(this.item.amount)}`)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.item.type === RecordType.EXPENSE ? AppColors.EXPENSE : AppColors.INCOME)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .constraintSize({ maxWidth: 124 })
        Text(this.item.accountName)
          .fontSize(11)
          .fontColor(AppColors.FAINT)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .constraintSize({ maxWidth: 124 })
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .height(82)
    .padding({ left: 16, right: 16 })
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 18, color: AppColors.SHADOW, offsetY: 8 })
    .margin({ bottom: 10 })
  }

  private softColor(): string {
    if (this.item.type === RecordType.INCOME) {
      return '#E6F6F0';
    }
    return '#F2F7FC';
  }
}
