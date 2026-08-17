import { AccountModel } from '../model/Account';
import { AccountRepository } from '../repository/AccountRepository';

@Observed
export class AssetsViewModel {
  private accountRepository: AccountRepository = new AccountRepository();

  accounts: AccountModel[] = [];
  totalAssets: number = 0;
  assetBalance: number = 0;
  liabilityBalance: number = 0;
  assetAccountCount: number = 0;
  liabilityAccountCount: number = 0;

  async refresh(): Promise<void> {
    this.accounts = await this.accountRepository.list();
    this.assetBalance = this.accounts.reduce((sum: number, account: AccountModel) => {
      return account.isLiability ? sum : sum + account.balance;
    }, 0);
    this.liabilityBalance = this.accounts.reduce((sum: number, account: AccountModel) => {
      return account.isLiability ? sum + account.balance : sum;
    }, 0);
    this.assetAccountCount = this.accounts.filter((account: AccountModel) => !account.isLiability).length;
    this.liabilityAccountCount = this.accounts.filter((account: AccountModel) => account.isLiability).length;
    this.totalAssets = this.accounts.reduce((sum: number, account: AccountModel) => {
      return sum + (account.isLiability ? -account.balance : account.balance);
    }, 0);
  }
}
