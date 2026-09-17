import { AccountModel } from '../model/Account';
import { InvestmentPosition, InvestmentType } from '../model/Investment';
import { AccountRepository } from '../repository/AccountRepository';
import { InvestmentRepository } from '../repository/InvestmentRepository';
import { MarketQuote, MarketQuoteService } from '../service/MarketQuoteService';

@Observed
export class AssetsViewModel {
  private accountRepository: AccountRepository = new AccountRepository();
  private investmentRepository: InvestmentRepository = new InvestmentRepository();
  accounts: AccountModel[] = [];
  positions: InvestmentPosition[] = [];
  totalAssets: number = 0;
  accountNetAssets: number = 0;
  assetBalance: number = 0;
  liabilityBalance: number = 0;
  stockValue: number = 0;
  fundValue: number = 0;
  stockProfit: number = 0;
  fundProfit: number = 0;

  async refresh(): Promise<void> {
    this.accounts = await this.accountRepository.list();
    this.positions = await this.investmentRepository.list();
    this.assetBalance = this.accounts.reduce((sum: number, item: AccountModel) => item.isLiability ? sum : sum + item.balance, 0);
    this.liabilityBalance = this.accounts.reduce((sum: number, item: AccountModel) => item.isLiability ? sum + item.balance : sum, 0);
    this.accountNetAssets = this.assetBalance - this.liabilityBalance;
    this.stockValue = this.positionValue(InvestmentType.STOCK);
    this.fundValue = this.positionValue(InvestmentType.FUND);
    this.stockProfit = this.positionProfit(InvestmentType.STOCK);
    this.fundProfit = this.positionProfit(InvestmentType.FUND);
    this.totalAssets = this.accountNetAssets + this.stockValue + this.fundValue;
  }

  positionsByType(type: InvestmentType): InvestmentPosition[] {
    return this.positions.filter((item: InvestmentPosition) => item.type === type);
  }

  async refreshInvestmentQuotes(): Promise<number> {
    let updated = 0;
    for (const item of this.positions) {
      if (!item.id || !item.securityCode) continue;
      try {
        const quote: MarketQuote = await MarketQuoteService.fetch(item.type, item.securityCode);
        await this.investmentRepository.updateQuote(item.id, quote.price, quote.quoteTime);
        updated++;
      } catch (error) {
      }
    }
    await this.refresh();
    return updated;
  }

  private positionValue(type: InvestmentType): number {
    return this.positionsByType(type).reduce((sum: number, item: InvestmentPosition) => {
      return sum + item.holdingQuantity * item.currentPrice;
    }, 0);
  }

  private positionProfit(type: InvestmentType): number {
    return this.positionsByType(type).reduce((sum: number, item: InvestmentPosition) => {
      return sum + item.holdingQuantity * (item.currentPrice - item.costPrice);
    }, 0);
  }
}
