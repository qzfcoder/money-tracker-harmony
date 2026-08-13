import { AccountModel, AccountType } from '../model/Account';

export const DEFAULT_ACCOUNTS: AccountModel[] = [
  { name: '现金', type: AccountType.CASH, balance: 0, initialBalance: 0, icon: 'cash', color: '#2B6FA7', isLiability: false, sortOrder: 1, createTime: 0 },
  { name: '微信', type: AccountType.WECHAT, balance: 0, initialBalance: 0, icon: 'wechat', color: '#2D8E76', isLiability: false, sortOrder: 2, createTime: 0 },
  { name: '支付宝', type: AccountType.ALIPAY, balance: 0, initialBalance: 0, icon: 'alipay', color: '#4E7FF2', isLiability: false, sortOrder: 3, createTime: 0 },
  { name: '银行卡', type: AccountType.DEBIT_CARD, balance: 0, initialBalance: 0, icon: 'bank_card', color: '#71829A', isLiability: false, sortOrder: 4, createTime: 0 }
];
