import { CategoryModel } from '../model/Category';
import { RecordType } from '../model/Record';

const now = 0;

export const DEFAULT_EXPENSE_CATEGORIES: CategoryModel[] = [
  { name: '餐饮', type: RecordType.EXPENSE, icon: 'food', color: '#EF7C68', sortOrder: 1, isDefault: true, createTime: now },
  { name: '交通', type: RecordType.EXPENSE, icon: 'traffic', color: '#4E7FF2', sortOrder: 2, isDefault: true, createTime: now },
  { name: '购物', type: RecordType.EXPENSE, icon: 'shopping', color: '#8A72F4', sortOrder: 3, isDefault: true, createTime: now },
  { name: '日用', type: RecordType.EXPENSE, icon: 'daily', color: '#2B6FA7', sortOrder: 4, isDefault: true, createTime: now },
  { name: '住房', type: RecordType.EXPENSE, icon: 'home', color: '#3B82A6', sortOrder: 5, isDefault: true, createTime: now },
  { name: '通讯', type: RecordType.EXPENSE, icon: 'phone', color: '#5E8CF0', sortOrder: 6, isDefault: true, createTime: now },
  { name: '医疗', type: RecordType.EXPENSE, icon: 'medical', color: '#E56E5B', sortOrder: 7, isDefault: true, createTime: now },
  { name: '娱乐', type: RecordType.EXPENSE, icon: 'fun', color: '#9A7CF2', sortOrder: 8, isDefault: true, createTime: now },
  { name: '学习', type: RecordType.EXPENSE, icon: 'study', color: '#D89D2A', sortOrder: 9, isDefault: true, createTime: now },
  { name: '运动', type: RecordType.EXPENSE, icon: 'sport', color: '#2D8E76', sortOrder: 10, isDefault: true, createTime: now },
  { name: '人情', type: RecordType.EXPENSE, icon: 'gift', color: '#F08A4B', sortOrder: 11, isDefault: true, createTime: now },
  { name: '旅行', type: RecordType.EXPENSE, icon: 'travel', color: '#2F91C8', sortOrder: 12, isDefault: true, createTime: now },
  { name: '宠物', type: RecordType.EXPENSE, icon: 'pet', color: '#71829A', sortOrder: 13, isDefault: true, createTime: now },
  { name: '数码', type: RecordType.EXPENSE, icon: 'digital', color: '#495A6D', sortOrder: 14, isDefault: true, createTime: now },
  { name: '其他', type: RecordType.EXPENSE, icon: 'other', color: '#7F8DA0', sortOrder: 99, isDefault: true, createTime: now }
];

export const DEFAULT_INCOME_CATEGORIES: CategoryModel[] = [
  { name: '工资', type: RecordType.INCOME, icon: 'salary', color: '#2D8E76', sortOrder: 1, isDefault: true, createTime: now },
  { name: '奖金', type: RecordType.INCOME, icon: 'bonus', color: '#D89D2A', sortOrder: 2, isDefault: true, createTime: now },
  { name: '报销', type: RecordType.INCOME, icon: 'refund', color: '#2B6FA7', sortOrder: 3, isDefault: true, createTime: now },
  { name: '兼职', type: RecordType.INCOME, icon: 'part_time', color: '#53A67C', sortOrder: 4, isDefault: true, createTime: now },
  { name: '其他', type: RecordType.INCOME, icon: 'income_other', color: '#7F8DA0', sortOrder: 99, isDefault: true, createTime: now }
];

export const DEFAULT_CATEGORIES: CategoryModel[] = [
  ...DEFAULT_EXPENSE_CATEGORIES,
  ...DEFAULT_INCOME_CATEGORIES
];
