import { router } from '@kit.ArkUI';
import { AccountModel } from '../model/Account';
import { RecordListItem, RecordType } from '../model/Record';
import { AccountRepository } from '../repository/AccountRepository';
import { RecordRepository } from '../repository/RecordRepository';
import { AppDatabase } from '../database/AppDatabase';
import { AppColors, AppRadius, AppSpace, LayoutSizes } from '../constants/DesignSystem';
import { NumberUtil } from '../utils/NumberUtil';
import { ToastUtil } from '../utils/ToastUtil';
import { RecordItem } from '../components/RecordItem';
import { ROUTES } from '../constants/RouteConstants';

interface AccountLedgerParams {
  accountId?: number;
}

@Entry
@Component
struct AccountLedger {
  private accountRepository: AccountRepository = new AccountRepository();
  private recordRepository: RecordRepository = new RecordRepository();

  @State account: AccountModel | null = null;
  @State records: RecordListItem[] = [];
  @State income: number = 0;
  @State expense: number = 0;
  @State transferCount: number = 0;
  private accountId: number = 0;

  aboutToAppear(): void {
    const params = router.getParams() as AccountLedgerParams;
    this.accountId = Number(params?.accountId || 0);
    this.loadData();
  }

  onPageShow(): void {
    this.loadData();
  }

  build() {
    Column() {
      this.Header()
      Scroll() {
        Column({ space: 16 }) {
          this.SummaryCard()
          this.SectionTitle('账户流水', `${this.records.length} 笔`)
          if (this.records.length === 0) {
            this.EmptyCard()
          } else {
            ForEach(this.records, (item: RecordListItem) => {
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
        .constraintSize({ maxWidth: LayoutSizes.CONTENT_COMPACT })
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
      Text(this.accountName())
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.INK)
        .width('100%')
      Text('查看这个账户相关的收入、支出和转账')
        .fontSize(13)
        .fontColor(AppColors.MUTED)
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ left: AppSpace.PAGE, right: AppSpace.PAGE, top: 22, bottom: 8 })
  }

  @Builder
  private SummaryCard() {
    Column({ space: 14 }) {
      Row() {
        Text(this.accountMark())
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.accountColor())
          .width(52)
          .height(52)
          .textAlign(TextAlign.Center)
          .borderRadius(18)
          .backgroundColor(AppColors.SURFACE_TINT)
        Blank()
        Button('管理账户')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.CHART_BLUE)
          .height(36)
          .padding({ left: 14, right: 14 })
          .backgroundColor(AppColors.SURFACE_TINT)
          .borderRadius(AppRadius.PILL)
          .onClick(() => router.pushUrl({ url: ROUTES.ACCOUNT_MANAGE }))
      }
      .width('100%')

      Text(NumberUtil.compactMoney(this.accountBalance()))
        .fontSize(36)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.INK)
        .width('100%')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Row({ space: 8 }) {
        this.Metric('收入', NumberUtil.compactMoney(this.income), AppColors.CHART_GREEN, AppColors.softGreen())
        this.Metric('支出', NumberUtil.compactMoney(this.expense), AppColors.CHART_PINK, AppColors.softPink())
        this.Metric('转账', `${this.transferCount} 笔`, AppColors.CHART_BLUE, AppColors.SURFACE_TINT)
      }
      .width('100%')
    }
    .width('100%')
    .padding(18)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 24, color: AppColors.SHADOW, offsetY: 10 })
  }

  @Builder
  private Metric(label: string, value: string, color: string, bgColor: string) {
    Column({ space: 4 }) {
      Text(label)
        .fontSize(11)
        .fontColor(AppColors.MUTED)
        .maxLines(1)
      Text(value)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
        .width('100%')
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .layoutWeight(1)
    .height(60)
    .justifyContent(FlexAlign.Center)
    .padding({ left: 8, right: 8 })
    .backgroundColor(bgColor)
    .borderRadius(16)
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

  @Builder
  private EmptyCard() {
    Column({ space: 8 }) {
      Text('暂无流水')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.INK)
      Text('这个账户还没有相关账单。')
        .fontSize(13)
        .fontColor(AppColors.MUTED)
    }
    .width('100%')
    .height(120)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .shadow({ radius: 18, color: AppColors.SHADOW, offsetY: 8 })
  }

  private async loadData(): Promise<void> {
    try {
      await AppDatabase.getInstance().init(getContext(this));
      this.account = await this.accountRepository.findById(this.accountId);
      this.records = await this.recordRepository.searchRecords({ accountId: this.accountId, limit: 200, offset: 0 });
      this.income = this.records.reduce((sum: number, item: RecordListItem) => {
        return item.type === RecordType.INCOME ? sum + item.amount : sum;
      }, 0);
      this.expense = this.records.reduce((sum: number, item: RecordListItem) => {
        return item.type === RecordType.EXPENSE ? sum + item.amount : sum;
      }, 0);
      this.transferCount = this.records.filter((item: RecordListItem) => item.type === RecordType.TRANSFER).length;
    } catch (error) {
      ToastUtil.show('账户流水加载失败');
    }
  }

  private accountName(): string {
    return this.account ? this.account.name : '账户流水';
  }

  private accountMark(): string {
    return this.account ? this.account.name.substring(0, 1) : '账';
  }

  private accountColor(): string {
    return this.account ? this.account.color : AppColors.CHART_BLUE;
  }

  private accountBalance(): number {
    return this.account ? this.account.balance : 0;
  }
}
