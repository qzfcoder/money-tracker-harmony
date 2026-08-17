import { RecordType } from './Record';

export interface RecordTemplateModel {
  id?: number;
  name: string;
  type: RecordType.EXPENSE | RecordType.INCOME;
  amount: number;
  categoryId: number;
  accountId: number;
  remark: string;
  useCount: number;
  createTime: number;
  updateTime: number;
  categoryName?: string;
  categoryColor?: string;
  accountName?: string;
}
