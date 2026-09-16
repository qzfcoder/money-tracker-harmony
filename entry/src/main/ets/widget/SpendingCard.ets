let storage = new LocalStorage();

@Entry(storage)
@Component
struct SpendingCard {
  @LocalStorageProp('appTitle') appTitle: string = '一页账';
  @LocalStorageProp('todayExpenseText') todayExpenseText: string = '¥0';
  @LocalStorageProp('monthExpenseText') monthExpenseText: string = '¥0';
  @LocalStorageProp('monthIncomeText') monthIncomeText: string = '¥0';
  @LocalStorageProp('balanceText') balanceText: string = '¥0';
  @LocalStorageProp('updatedAtText') updatedAtText: string = '刚刚更新';
  @LocalStorageProp('statusText') statusText: string = '记录之后自动汇总';

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column()
        .width(86)
        .height(86)
        .borderRadius(43)
        .backgroundColor('#D8F4FF')
        .opacity(0.72)
        .position({ x: '70%', y: -26 })

      Column()
        .width(110)
        .height(110)
        .borderRadius(55)
        .backgroundColor('#FFE5EC')
        .opacity(0.7)
        .position({ x: -36, y: '58%' })

      Column({ space: 10 }) {
        Row() {
          Column({ space: 2 }) {
            Text(this.appTitle)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor('#17324D')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(this.updatedAtText)
              .fontSize(10)
              .fontColor('#6B8298')
              .maxLines(1)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Text('账')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .textAlign(TextAlign.Center)
            .width(30)
            .height(30)
            .borderRadius(15)
            .backgroundColor('#2F7EF7')
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Column({ space: 4 }) {
          Text('今日支出')
            .fontSize(11)
            .fontColor('#6B8298')
          Text(this.todayExpenseText)
            .fontSize(26)
            .fontWeight(FontWeight.Bold)
            .fontColor('#10263D')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')

        Row({ space: 8 }) {
          Column({ space: 2 }) {
            Text('本月')
              .fontSize(9)
              .fontColor('#7B8FA3')
              .maxLines(1)
            Text(this.monthExpenseText)
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor('#F46F80')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          .padding({ left: 8, right: 8, top: 7, bottom: 7 })
          .backgroundColor('#FFFFFFCC')
          .borderRadius(12)

          Column({ space: 2 }) {
            Text('收入')
              .fontSize(9)
              .fontColor('#7B8FA3')
              .maxLines(1)
            Text(this.monthIncomeText)
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor('#21A676')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          .padding({ left: 8, right: 8, top: 7, bottom: 7 })
          .backgroundColor('#FFFFFFCC')
          .borderRadius(12)

          Column({ space: 2 }) {
            Text('结余')
              .fontSize(9)
              .fontColor('#7B8FA3')
              .maxLines(1)
            Text(this.balanceText)
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor('#2F7EF7')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          .padding({ left: 8, right: 8, top: 7, bottom: 7 })
          .backgroundColor('#FFFFFFCC')
          .borderRadius(12)
        }
        .width('100%')

        Text(this.statusText)
          .fontSize(10)
          .fontColor('#6B8298')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .height('100%')
      .padding({ left: 14, right: 14, top: 13, bottom: 12 })
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7FBFF')
    .borderRadius(22)
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        abilityName: 'EntryAbility',
        params: {
          targetPage: 'pages/Index'
        }
      });
    })
  }
}
