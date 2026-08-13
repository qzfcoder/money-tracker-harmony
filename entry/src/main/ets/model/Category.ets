import { RecordType } from './Record';

export interface CategoryModel {
  id?: number;
  name: string;
  type: RecordType.EXPENSE | RecordType.INCOME;
  icon: string;
  color: string;
  sortOrder: number;
  isDefault: boolean;
  createTime: number;
}

