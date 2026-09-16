export enum SalaryMode {
  MONTHLY = 'monthly',
  DAILY = 'daily',
  HOURLY = 'hourly'
}

export interface SalarySettingsData {
  enabled: boolean;
  salaryMode: SalaryMode;
  baseAmount: number;
  payday: number;
  workDaysPerWeek: number;
  dailyHours: number;
  bonusAmount: number;
  allowanceAmount: number;
  deductionAmount: number;
}

export class SalaryInsight {
  monthlyIncome: number = 0;
  earnedToDate: number = 0;
  todayIncome: number = 0;
  naturalDailyIncome: number = 0;
  workDailyIncome: number = 0;
  hourlyIncome: number = 0;
  monthProgress: number = 0;
  paydayCountdown: number = 0;
  expenseRate: number = 0;
  remainingAfterExpense: number = 0;
}
