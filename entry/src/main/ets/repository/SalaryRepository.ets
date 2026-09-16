import preferences from '@ohos.data.preferences';
import { common } from '@kit.AbilityKit';
import { SalaryMode, SalarySettingsData } from '../model/Salary';

export class SalaryRepository {
  private static readonly FILE_NAME: string = 'money_tracker_salary';

  defaultSettings(): SalarySettingsData {
    return {
      enabled: false,
      salaryMode: SalaryMode.MONTHLY,
      baseAmount: 0,
      payday: 10,
      workDaysPerWeek: 5,
      dailyHours: 8,
      bonusAmount: 0,
      allowanceAmount: 0,
      deductionAmount: 0
    };
  }

  async load(context: common.Context): Promise<SalarySettingsData> {
    const store = await preferences.getPreferences(context, SalaryRepository.FILE_NAME);
    const defaults = this.defaultSettings();
    return {
      enabled: store.getSync('enabled', defaults.enabled) as boolean,
      salaryMode: store.getSync('salaryMode', defaults.salaryMode) as SalaryMode,
      baseAmount: store.getSync('baseAmount', defaults.baseAmount) as number,
      payday: store.getSync('payday', defaults.payday) as number,
      workDaysPerWeek: store.getSync('workDaysPerWeek', defaults.workDaysPerWeek) as number,
      dailyHours: store.getSync('dailyHours', defaults.dailyHours) as number,
      bonusAmount: store.getSync('bonusAmount', defaults.bonusAmount) as number,
      allowanceAmount: store.getSync('allowanceAmount', defaults.allowanceAmount) as number,
      deductionAmount: store.getSync('deductionAmount', defaults.deductionAmount) as number
    };
  }

  async save(context: common.Context, settings: SalarySettingsData): Promise<void> {
    const store = await preferences.getPreferences(context, SalaryRepository.FILE_NAME);
    const normalized = this.normalize(settings);
    store.putSync('enabled', normalized.enabled);
    store.putSync('salaryMode', normalized.salaryMode);
    store.putSync('baseAmount', normalized.baseAmount);
    store.putSync('payday', normalized.payday);
    store.putSync('workDaysPerWeek', normalized.workDaysPerWeek);
    store.putSync('dailyHours', normalized.dailyHours);
    store.putSync('bonusAmount', normalized.bonusAmount);
    store.putSync('allowanceAmount', normalized.allowanceAmount);
    store.putSync('deductionAmount', normalized.deductionAmount);
    await store.flush();
  }

  private normalize(settings: SalarySettingsData): SalarySettingsData {
    return {
      enabled: settings.enabled,
      salaryMode: settings.salaryMode,
      baseAmount: Math.max(0, Math.round(settings.baseAmount * 100) / 100),
      payday: Math.max(1, Math.min(28, Math.round(settings.payday || 10))),
      workDaysPerWeek: Math.max(1, Math.min(7, Math.round(settings.workDaysPerWeek || 5))),
      dailyHours: Math.max(1, Math.min(16, Math.round(settings.dailyHours * 10) / 10)),
      bonusAmount: Math.max(0, Math.round(settings.bonusAmount * 100) / 100),
      allowanceAmount: Math.max(0, Math.round(settings.allowanceAmount * 100) / 100),
      deductionAmount: Math.max(0, Math.round(settings.deductionAmount * 100) / 100)
    };
  }
}
