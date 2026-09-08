import preferences from '@ohos.data.preferences';
import { common } from '@kit.AbilityKit';

export enum ThemeMode {
  SYSTEM = 'system',
  LIGHT = 'light',
  DARK = 'dark'
}

export interface AutoBookkeepingSettings {
  autoBookkeepingEnabled: boolean;
  autoReviewEnabled: boolean;
  autoDefaultAccountId: number;
  alipayBillImportEnabled: boolean;
  floatingBallEnabled: boolean;
}

export interface AppSettingsData extends AutoBookkeepingSettings {
  themeMode: ThemeMode;
  currencySymbol: string;
}

export class SettingsRepository {
  private static readonly FILE_NAME: string = 'money_tracker_settings';
  private static readonly DEFAULT_USER_NAME: string = '账本';

  private defaultSettings(): AppSettingsData {
    return {
      themeMode: ThemeMode.SYSTEM,
      currencySymbol: '¥',
      autoBookkeepingEnabled: false,
      autoReviewEnabled: true,
      autoDefaultAccountId: 0,
      alipayBillImportEnabled: false,
      floatingBallEnabled: false
    };
  }

  async load(context: common.Context): Promise<AppSettingsData> {
    const store = await preferences.getPreferences(context, SettingsRepository.FILE_NAME);
    const defaults = this.defaultSettings();
    return {
      themeMode: store.getSync('themeMode', defaults.themeMode) as ThemeMode,
      currencySymbol: store.getSync('currencySymbol', defaults.currencySymbol) as string,
      autoBookkeepingEnabled: store.getSync('autoBookkeepingEnabled', defaults.autoBookkeepingEnabled) as boolean,
      autoReviewEnabled: store.getSync('autoReviewEnabled', defaults.autoReviewEnabled) as boolean,
      autoDefaultAccountId: store.getSync('autoDefaultAccountId', defaults.autoDefaultAccountId) as number,
      alipayBillImportEnabled: store.getSync('alipayBillImportEnabled', defaults.alipayBillImportEnabled) as boolean,
      floatingBallEnabled: store.getSync('floatingBallEnabled', defaults.floatingBallEnabled) as boolean
    };
  }

  async loadUserName(context: common.Context): Promise<string> {
    const store = await preferences.getPreferences(context, SettingsRepository.FILE_NAME);
    const value = store.getSync('userName', SettingsRepository.DEFAULT_USER_NAME) as string;
    return value.trim() || SettingsRepository.DEFAULT_USER_NAME;
  }

  async saveUserName(context: common.Context, userName: string): Promise<void> {
    const store = await preferences.getPreferences(context, SettingsRepository.FILE_NAME);
    store.putSync('userName', userName.trim() || SettingsRepository.DEFAULT_USER_NAME);
    await store.flush();
  }

  async save(context: common.Context, settings: AppSettingsData): Promise<void> {
    const store = await preferences.getPreferences(context, SettingsRepository.FILE_NAME);
    store.putSync('themeMode', settings.themeMode);
    store.putSync('currencySymbol', settings.currencySymbol);
    store.putSync('autoBookkeepingEnabled', settings.autoBookkeepingEnabled);
    store.putSync('autoReviewEnabled', settings.autoReviewEnabled);
    store.putSync('autoDefaultAccountId', settings.autoDefaultAccountId);
    store.putSync('alipayBillImportEnabled', settings.alipayBillImportEnabled);
    store.putSync('floatingBallEnabled', settings.floatingBallEnabled);
    await store.flush();
  }

  async reset(context: common.Context): Promise<void> {
    const store = await preferences.getPreferences(context, SettingsRepository.FILE_NAME);
    await store.clear();
    await store.flush();
  }
}
