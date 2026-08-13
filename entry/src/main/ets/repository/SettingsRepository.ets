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
  autoNotificationEnabled: boolean;
  autoSmsEnabled: boolean;
  autoDefaultAccountId: number;
  autoNotificationPromptShown: boolean;
  alipayBillImportEnabled: boolean;
}

export interface AppSettingsData extends AutoBookkeepingSettings {
  themeMode: ThemeMode;
  currencySymbol: string;
  reminderEnabled: boolean;
  reminderTime: string;
  reminderAgentId: number;
}

export class SettingsRepository {
  private static readonly FILE_NAME: string = 'money_tracker_settings';
  private static readonly DEFAULT_USER_NAME: string = '账本';
  private static readonly PRIVACY_ACCEPTED_KEY: string = 'privacyPolicyAccepted';

  private defaultSettings(): AppSettingsData {
    return {
      themeMode: ThemeMode.SYSTEM,
      currencySymbol: '¥',
      reminderEnabled: false,
      reminderTime: '20:00',
      reminderAgentId: -1,
      autoBookkeepingEnabled: false,
      autoReviewEnabled: true,
      autoNotificationEnabled: true,
      autoSmsEnabled: false,
      autoDefaultAccountId: 0,
      autoNotificationPromptShown: false,
      alipayBillImportEnabled: false
    };
  }

  async load(context: common.Context): Promise<AppSettingsData> {
    const store = await preferences.getPreferences(context, SettingsRepository.FILE_NAME);
    const defaults = this.defaultSettings();
    return {
      themeMode: store.getSync('themeMode', defaults.themeMode) as ThemeMode,
      currencySymbol: store.getSync('currencySymbol', defaults.currencySymbol) as string,
      reminderEnabled: store.getSync('reminderEnabled', defaults.reminderEnabled) as boolean,
      reminderTime: store.getSync('reminderTime', defaults.reminderTime) as string,
      reminderAgentId: store.getSync('reminderAgentId', defaults.reminderAgentId) as number,
      autoBookkeepingEnabled: store.getSync('autoBookkeepingEnabled', defaults.autoBookkeepingEnabled) as boolean,
      autoReviewEnabled: store.getSync('autoReviewEnabled', defaults.autoReviewEnabled) as boolean,
      autoNotificationEnabled: store.getSync('autoNotificationEnabled', defaults.autoNotificationEnabled) as boolean,
      autoSmsEnabled: store.getSync('autoSmsEnabled', defaults.autoSmsEnabled) as boolean,
      autoDefaultAccountId: store.getSync('autoDefaultAccountId', defaults.autoDefaultAccountId) as number,
      autoNotificationPromptShown: store.getSync('autoNotificationPromptShown', defaults.autoNotificationPromptShown) as boolean,
      alipayBillImportEnabled: store.getSync('alipayBillImportEnabled', defaults.alipayBillImportEnabled) as boolean
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

  async loadPrivacyAccepted(context: common.Context): Promise<boolean> {
    const store = await preferences.getPreferences(context, SettingsRepository.FILE_NAME);
    return store.getSync(SettingsRepository.PRIVACY_ACCEPTED_KEY, false) as boolean;
  }

  async savePrivacyAccepted(context: common.Context, accepted: boolean): Promise<void> {
    const store = await preferences.getPreferences(context, SettingsRepository.FILE_NAME);
    store.putSync(SettingsRepository.PRIVACY_ACCEPTED_KEY, accepted);
    await store.flush();
  }

  async save(context: common.Context, settings: AppSettingsData): Promise<void> {
    const store = await preferences.getPreferences(context, SettingsRepository.FILE_NAME);
    store.putSync('themeMode', settings.themeMode);
    store.putSync('currencySymbol', settings.currencySymbol);
    store.putSync('reminderEnabled', settings.reminderEnabled);
    store.putSync('reminderTime', settings.reminderTime);
    store.putSync('reminderAgentId', settings.reminderAgentId);
    store.putSync('autoBookkeepingEnabled', settings.autoBookkeepingEnabled);
    store.putSync('autoReviewEnabled', settings.autoReviewEnabled);
    store.putSync('autoNotificationEnabled', settings.autoNotificationEnabled);
    store.putSync('autoSmsEnabled', settings.autoSmsEnabled);
    store.putSync('autoDefaultAccountId', settings.autoDefaultAccountId);
    store.putSync('autoNotificationPromptShown', settings.autoNotificationPromptShown);
    store.putSync('alipayBillImportEnabled', settings.alipayBillImportEnabled);
    await store.flush();
  }

  async reset(context: common.Context): Promise<void> {
    const store = await preferences.getPreferences(context, SettingsRepository.FILE_NAME);
    await store.clear();
    await store.flush();
  }
}
