import { common, ConfigurationConstant } from '@kit.AbilityKit';
import { AppColors } from '../constants/DesignSystem';
import { ThemeMode } from '../repository/SettingsRepository';

export class ThemeUtil {
  static readonly DARK_STORAGE_KEY: string = 'ledgerIsDarkMode';
  static readonly THEME_MODE_STORAGE_KEY: string = 'ledgerThemeMode';
  static readonly SYSTEM_COLOR_MODE_STORAGE_KEY: string = 'ledgerSystemColorMode';

  static apply(mode: ThemeMode, context?: common.Context): void {
    AppStorage.setOrCreate<string>(ThemeUtil.THEME_MODE_STORAGE_KEY, mode);
    ThemeUtil.applySystemColorMode(mode, context);
    ThemeUtil.applyPalette(ThemeUtil.shouldUseDark(mode, context));
  }

  static updateSystemColorMode(colorMode?: ConfigurationConstant.ColorMode): void {
    const normalizedColorMode = colorMode === undefined ? ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT : colorMode;
    AppStorage.setOrCreate<number>(ThemeUtil.SYSTEM_COLOR_MODE_STORAGE_KEY, normalizedColorMode);
    const storedThemeMode = AppStorage.get<string>(ThemeUtil.THEME_MODE_STORAGE_KEY);
    const mode = ThemeUtil.normalizeThemeMode(storedThemeMode);
    if (mode === ThemeMode.SYSTEM) {
      ThemeUtil.applyPalette(ThemeUtil.isDarkColorMode(colorMode));
    }
  }

  private static shouldUseDark(mode: ThemeMode, context?: common.Context): boolean {
    if (mode === ThemeMode.DARK) {
      return true;
    }
    if (mode === ThemeMode.LIGHT) {
      return false;
    }
    const abilityContext = context as common.UIAbilityContext;
    if (abilityContext && abilityContext.config && typeof abilityContext.config.colorMode === 'number') {
      return ThemeUtil.isDarkColorMode(abilityContext.config.colorMode);
    }
    const storedColorMode = AppStorage.get<number>(ThemeUtil.SYSTEM_COLOR_MODE_STORAGE_KEY);
    return ThemeUtil.isDarkColorMode(storedColorMode);
  }

  private static isDarkColorMode(colorMode?: number): boolean {
    return colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
  }

  private static normalizeThemeMode(mode?: string): ThemeMode {
    if (mode === ThemeMode.DARK) {
      return ThemeMode.DARK;
    }
    if (mode === ThemeMode.LIGHT) {
      return ThemeMode.LIGHT;
    }
    return ThemeMode.SYSTEM;
  }

  private static applyPalette(dark: boolean): void {
    if (dark) {
      AppColors.useDark();
    } else {
      AppColors.useLight();
    }
    AppStorage.setOrCreate<boolean>(ThemeUtil.DARK_STORAGE_KEY, dark);
  }

  private static applySystemColorMode(mode: ThemeMode, context?: common.Context): void {
    const abilityContext = context as common.UIAbilityContext;
    if (!abilityContext || !abilityContext.setColorMode) {
      return;
    }
    try {
      if (mode === ThemeMode.DARK) {
        abilityContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
      } else if (mode === ThemeMode.LIGHT) {
        abilityContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
      } else {
        abilityContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
      }
    } catch (error) {
    }
  }
}
