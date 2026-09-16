import { SalaryInsight, SalaryMode, SalarySettingsData } from '../model/Salary';
import { DateUtil } from '../utils/DateUtil';

export class SalaryInsightService {
  static build(settings: SalarySettingsData, monthExpense: number, timestamp: number = Date.now()): SalaryInsight {
    const insight = new SalaryInsight();
    const monthStart = DateUtil.startOfMonth(timestamp);
    const monthEnd = DateUtil.startOfNextMonth(timestamp);
    const daysInMonth = Math.max(1, Math.round((monthEnd - monthStart) / 86400000));
    const workingDays = Math.max(1, SalaryInsightService.countWorkingDays(monthStart, monthEnd, settings.workDaysPerWeek));
    const elapsedDays = SalaryInsightService.elapsedDaysInMonth(timestamp, monthStart, daysInMonth);
    const elapsedWorkingDays = SalaryInsightService.elapsedWorkingDays(timestamp, monthStart, settings.workDaysPerWeek);

    insight.monthlyIncome = SalaryInsightService.monthlyIncome(settings, workingDays);
    insight.naturalDailyIncome = SalaryInsightService.roundMoney(insight.monthlyIncome / daysInMonth);
    insight.workDailyIncome = SalaryInsightService.roundMoney(insight.monthlyIncome / workingDays);
    insight.hourlyIncome = SalaryInsightService.roundMoney(insight.workDailyIncome / Math.max(1, settings.dailyHours));
    insight.todayIncome = SalaryInsightService.isWorkday(timestamp, settings.workDaysPerWeek)
      ? insight.workDailyIncome
      : insight.naturalDailyIncome;
    insight.earnedToDate = SalaryInsightService.roundMoney(Math.max(
      insight.naturalDailyIncome * elapsedDays,
      insight.workDailyIncome * elapsedWorkingDays
    ));
    insight.monthProgress = Math.min(100, Math.max(0, Math.round(elapsedDays / daysInMonth * 100)));
    insight.paydayCountdown = SalaryInsightService.daysUntilPayday(timestamp, settings.payday);
    insight.expenseRate = insight.earnedToDate > 0 ? Math.round(monthExpense / insight.earnedToDate * 100) : 0;
    insight.remainingAfterExpense = SalaryInsightService.roundMoney(insight.earnedToDate - monthExpense);
    return insight;
  }

  static buildForRange(settings: SalarySettingsData, periodExpense: number, startTime: number, endTime: number, timestamp: number = Date.now()): SalaryInsight {
    const rangeStart = DateUtil.startOfDay(startTime);
    const rangeEnd = Math.max(DateUtil.addDays(rangeStart, 1), endTime);
    const referenceTime = Math.min(Math.max(timestamp, rangeStart), rangeEnd - 1);
    const insight = SalaryInsightService.build(settings, periodExpense, referenceTime);
    const periodIncome = SalaryInsightService.incomeForRange(settings, rangeStart, rangeEnd);
    let earnedEnd = rangeEnd;

    if (timestamp < rangeStart) {
      earnedEnd = rangeStart;
    } else if (timestamp < rangeEnd) {
      earnedEnd = DateUtil.addDays(DateUtil.startOfDay(timestamp), 1);
    }

    const earnedIncome = SalaryInsightService.incomeForRange(settings, rangeStart, earnedEnd);
    const totalDays = Math.max(1, Math.round((rangeEnd - rangeStart) / 86400000));
    const elapsedDays = Math.max(0, Math.min(totalDays, Math.round((earnedEnd - rangeStart) / 86400000)));
    insight.monthlyIncome = periodIncome;
    insight.earnedToDate = earnedIncome;
    insight.monthProgress = Math.min(100, Math.max(0, Math.round(elapsedDays / totalDays * 100)));
    insight.expenseRate = earnedIncome > 0 ? Math.round(periodExpense / earnedIncome * 100) : 0;
    insight.remainingAfterExpense = SalaryInsightService.roundMoney(earnedIncome - periodExpense);
    return insight;
  }

  static workTimeText(amount: number, hourlyIncome: number): string {
    if (amount <= 0 || hourlyIncome <= 0) {
      return '设置工资后可查看折算时间';
    }
    const totalMinutes = Math.max(1, Math.round(amount / hourlyIncome * 60));
    const hours = Math.floor(totalMinutes / 60);
    const minutes = totalMinutes % 60;
    if (hours <= 0) {
      return `${minutes} 分钟`;
    }
    if (minutes <= 0) {
      return `${hours} 小时`;
    }
    return `${hours} 小时 ${minutes} 分钟`;
  }

  static pressureLabel(rate: number): string {
    if (rate <= 0) {
      return '待记录';
    }
    if (rate <= 50) {
      return '轻松';
    }
    if (rate <= 80) {
      return '正常';
    }
    if (rate <= 100) {
      return '偏紧';
    }
    return '超出';
  }

  static paydayStatusText(countdown: number): string {
    if (countdown <= 0) {
      return '今天发薪';
    }
    if (countdown === 1) {
      return '明天发薪';
    }
    return `还有 ${countdown} 天发薪`;
  }

  static normalizePayday(payday: number): number {
    if (!Number.isFinite(payday)) {
      return 1;
    }
    return Math.max(1, Math.min(28, Math.round(payday)));
  }

  private static monthlyIncome(settings: SalarySettingsData, workingDays: number): number {
    let amount = settings.baseAmount;
    if (settings.salaryMode === SalaryMode.DAILY) {
      amount = settings.baseAmount * workingDays;
    }
    if (settings.salaryMode === SalaryMode.HOURLY) {
      amount = settings.baseAmount * settings.dailyHours * workingDays;
    }
    return SalaryInsightService.roundMoney(Math.max(0, amount + settings.bonusAmount + settings.allowanceAmount - settings.deductionAmount));
  }

  private static incomeForRange(settings: SalarySettingsData, startTime: number, endTime: number): number {
    if (endTime <= startTime) {
      return 0;
    }
    let total = 0;
    let cursor = DateUtil.startOfMonth(startTime);
    while (cursor < endTime) {
      const monthStart = cursor;
      const monthEnd = DateUtil.startOfNextMonth(monthStart);
      const sliceStart = Math.max(startTime, monthStart);
      const sliceEnd = Math.min(endTime, monthEnd);
      if (sliceEnd > sliceStart) {
        total += SalaryInsightService.incomeForMonthSlice(settings, monthStart, monthEnd, sliceStart, sliceEnd);
      }
      cursor = monthEnd;
    }
    return SalaryInsightService.roundMoney(total);
  }

  private static incomeForMonthSlice(settings: SalarySettingsData, monthStart: number, monthEnd: number, sliceStart: number, sliceEnd: number): number {
    const daysInMonth = Math.max(1, Math.round((monthEnd - monthStart) / 86400000));
    const sliceDays = Math.max(0, Math.round((sliceEnd - sliceStart) / 86400000));
    const sliceRatio = Math.min(1, sliceDays / daysInMonth);
    const monthWorkingDays = Math.max(1, SalaryInsightService.countWorkingDays(monthStart, monthEnd, settings.workDaysPerWeek));
    const sliceWorkingDays = SalaryInsightService.countWorkingDays(sliceStart, sliceEnd, settings.workDaysPerWeek);
    const adjustment = settings.bonusAmount + settings.allowanceAmount - settings.deductionAmount;

    if (settings.salaryMode === SalaryMode.DAILY) {
      return SalaryInsightService.roundMoney(settings.baseAmount * sliceWorkingDays + adjustment * sliceRatio);
    }
    if (settings.salaryMode === SalaryMode.HOURLY) {
      return SalaryInsightService.roundMoney(settings.baseAmount * settings.dailyHours * sliceWorkingDays + adjustment * sliceRatio);
    }
    return SalaryInsightService.roundMoney(SalaryInsightService.monthlyIncome(settings, monthWorkingDays) * sliceRatio);
  }

  private static countWorkingDays(startTime: number, endTime: number, workDaysPerWeek: number): number {
    let count = 0;
    for (let time = startTime; time < endTime; time = DateUtil.addDays(time, 1)) {
      if (SalaryInsightService.isWorkday(time, workDaysPerWeek)) {
        count++;
      }
    }
    return count;
  }

  private static elapsedWorkingDays(timestamp: number, monthStart: number, workDaysPerWeek: number): number {
    const todayStart = DateUtil.startOfDay(timestamp);
    let count = 0;
    for (let time = monthStart; time <= todayStart; time = DateUtil.addDays(time, 1)) {
      if (SalaryInsightService.isWorkday(time, workDaysPerWeek)) {
        count++;
      }
    }
    return count;
  }

  private static elapsedDaysInMonth(timestamp: number, monthStart: number, daysInMonth: number): number {
    const day = Math.floor((DateUtil.startOfDay(timestamp) - monthStart) / 86400000) + 1;
    return Math.max(1, Math.min(daysInMonth, day));
  }

  private static isWorkday(timestamp: number, workDaysPerWeek: number): boolean {
    const day = new Date(timestamp).getDay();
    const normalized = day === 0 ? 7 : day;
    return normalized <= workDaysPerWeek;
  }

  private static daysUntilPayday(timestamp: number, payday: number): number {
    const date = new Date(timestamp);
    const today = DateUtil.startOfDay(timestamp);
    const normalizedPayday = SalaryInsightService.normalizePayday(payday);
    let target = new Date(date.getFullYear(), date.getMonth(), normalizedPayday).getTime();
    if (target < today) {
      target = new Date(date.getFullYear(), date.getMonth() + 1, normalizedPayday).getTime();
    }
    return Math.max(0, Math.round((target - today) / 86400000));
  }

  private static roundMoney(value: number): number {
    return Math.round(value * 100) / 100;
  }
}
