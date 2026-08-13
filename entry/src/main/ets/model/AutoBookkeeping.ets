import { RecordType } from './Record';

export enum AutoCaptureSource {
  NOTIFICATION = 'notification',
  SMS = 'sms',
  MANUAL = 'manual'
}

export enum AutoRuleType {
  BLACKLIST = 1,
  CATEGORY = 2
}

export enum AutoBillStatus {
  PENDING = 0,
  CONFIRMED = 1,
  DISCARDED = 2
}

export interface AutoRuleModel {
  id?: number;
  ruleType: AutoRuleType;
  keyword: string;
  recordType: RecordType.EXPENSE | RecordType.INCOME;
  categoryId: number;
  enabled: boolean;
  sortOrder: number;
  createTime: number;
  updateTime: number;
  categoryName?: string;
  categoryColor?: string;
}

export interface AutoNotificationPayload {
  source: AutoCaptureSource;
  bundleName: string;
  appName: string;
  title: string;
  content: string;
  rawText: string;
  eventTime: number;
}

export interface AutoBillModel {
  id?: number;
  source: AutoCaptureSource;
  bundleName: string;
  appName: string;
  title: string;
  content: string;
  rawText: string;
  amount: number;
  type: RecordType.EXPENSE | RecordType.INCOME;
  categoryId: number;
  accountId: number;
  recordTime: number;
  remark: string;
  confidence: number;
  matchedRule: string;
  status: AutoBillStatus;
  createTime: number;
  updateTime: number;
  categoryName?: string;
  categoryColor?: string;
  accountName?: string;
}

export interface AutoParseResult {
  matched: boolean;
  reason: string;
  bill?: AutoBillModel;
}
