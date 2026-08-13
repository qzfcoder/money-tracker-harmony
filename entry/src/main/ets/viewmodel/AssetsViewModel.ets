import { AccountModel } from '../model/Account';
import { AccountRepository } from '../repository/AccountRepository';

@Observed
export class AssetsViewModel {
  private accountRepository: AccountRepository = new AccountRepository();

  accounts: AccountModel[] = [];
  totalAssets: number = 0;

  async refresh(): Promise<void> {
    this.accounts = await this.accountRepository.list();
    this.totalAssets = this.accounts.reduce((sum: number, account: AccountModel) => {
      return sum + (account.isLiability ? -account.balance : account.balance);
    }, 0);
  }
}

