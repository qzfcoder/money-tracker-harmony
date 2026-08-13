import { AutoRuleType } from '../model/AutoBookkeeping';
import { RecordType } from '../model/Record';

export interface AutoRuleSeed {
  ruleType: AutoRuleType;
  keyword: string;
  recordType: RecordType.EXPENSE | RecordType.INCOME;
  categoryName: string;
  sortOrder: number;
}

export const DEFAULT_AUTO_BLACKLIST_KEYWORDS: string[] = [
  '验证码',
  '校验码',
  '动态码',
  '登录',
  '广告',
  '营销',
  '活动',
  '优惠',
  '抽奖',
  '中奖',
  '还款提醒',
  '账单日',
  '分期',
  '贷款',
  '借款',
  '提额'
];

export const DEFAULT_AUTO_RULES: AutoRuleSeed[] = [
  { ruleType: AutoRuleType.CATEGORY, keyword: '餐饮|奶茶|外卖|咖啡|饭店|小吃|食堂', recordType: RecordType.EXPENSE, categoryName: '餐饮', sortOrder: 1 },
  { ruleType: AutoRuleType.CATEGORY, keyword: '地铁|打车|公交|出租|停车|加油|高铁|火车|车票', recordType: RecordType.EXPENSE, categoryName: '交通', sortOrder: 2 },
  { ruleType: AutoRuleType.CATEGORY, keyword: '超市|购物|商场|淘宝|京东|拼多多|网购', recordType: RecordType.EXPENSE, categoryName: '购物', sortOrder: 3 },
  { ruleType: AutoRuleType.CATEGORY, keyword: '工资|薪资|奖金|报销|发薪|入账', recordType: RecordType.INCOME, categoryName: '工资', sortOrder: 4 },
  { ruleType: AutoRuleType.CATEGORY, keyword: '兼职|稿费|补贴|返现|分红', recordType: RecordType.INCOME, categoryName: '兼职', sortOrder: 5 },
  { ruleType: AutoRuleType.CATEGORY, keyword: '退款|退回|报销', recordType: RecordType.INCOME, categoryName: '报销', sortOrder: 6 }
];

export const DEFAULT_AUTO_DEFAULT_ACCOUNT_KEYWORDS: string[] = [
  '微信',
  '支付宝',
  '银行卡',
  '工商银行',
  '建设银行',
  '农业银行',
  '中国银行',
  '招商银行'
];
