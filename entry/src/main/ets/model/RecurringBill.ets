import { RecordType } from './Record';

export enum RecurringFrequency {
  MONTHLY = 1,
  WEEKLY = 2
}

export interface RecurringBillModel {
  id?: number;
  name: string;
  type: RecordType.EXPENSE | RecordType.INCOME;
  amount: number;
  categoryId: number;
  accountId: number;
  frequency: RecurringFrequency;
  dayOfMonth: number;
  dayOfWeek: number;
  remark: string;
  enabled: boolean;
  lastGeneratedKey: string;
  createTime: number;
  updateTime: number;
}
