export enum RecordType {
  EXPENSE = 1,
  INCOME = 2,
  TRANSFER = 3
}

export interface RecordModel {
  id?: number;
  type: RecordType;
  amount: number;
  categoryId: number;
  accountId: number;
  transferAccountId?: number;
  recordTime: number;
  ledgerName: string;
  remark: string;
  createTime: number;
  updateTime: number;
}

export interface RecordListItem extends RecordModel {
  categoryName: string;
  categoryIcon: string;
  categoryColor: string;
  accountName: string;
  transferAccountName?: string;
}
