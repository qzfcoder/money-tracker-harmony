export enum AccountType {
  CASH = 1,
  DEBIT_CARD = 2,
  CREDIT_CARD = 3,
  ALIPAY = 4,
  WECHAT = 5,
  OTHER = 6
}

export interface AccountModel {
  id?: number;
  name: string;
  type: AccountType;
  balance: number;
  initialBalance: number;
  icon: string;
  color: string;
  isLiability: boolean;
  sortOrder: number;
  createTime: number;
}

