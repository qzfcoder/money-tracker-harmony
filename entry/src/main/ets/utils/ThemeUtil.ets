import { common, ConfigurationConstant } from '@kit.AbilityKit';
import { AppColors } from '../constants/DesignSystem';
import { ThemeMode } from '../repository/SettingsRepository';

export class ThemeUtil {
  static apply(mode: ThemeMode, context?: common.Context): void {
    const dark = mode === ThemeMode.DARK;
    if (dark) {
      AppColors.useDark();
    } else {
      AppColors.useLight();
    }
    ThemeUtil.applySystemColorMode(mode, context);
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
