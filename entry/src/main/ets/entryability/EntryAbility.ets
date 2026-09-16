import { AbilityConstant, Configuration, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { AppDatabase } from '../database/AppDatabase';
import { SpendingCardService } from '../widget/SpendingCardService';
import { ThemeUtil } from '../utils/ThemeUtil';

const DOMAIN = 0x0001;

export default class EntryAbility extends UIAbility {
  private windowStage: window.WindowStage | null = null;
  private savedLaunchWant: Want | undefined = undefined;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.savedLaunchWant = want;
    ThemeUtil.updateSystemColorMode(this.context.config.colorMode);
    hilog.info(DOMAIN, 'EntryAbility', 'onCreate');
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    ThemeUtil.updateSystemColorMode(newConfig.colorMode);
  }

  onForeground(): void {
    this.refreshSpendingCard();
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.savedLaunchWant = want;
    const page = this.resolveLaunchPage(want);
    if (this.windowStage && page.length > 0) {
      this.windowStage.loadContent(page, (err) => {
        if (err.code) {
          hilog.error(DOMAIN, 'EntryAbility', `load new want content failed: ${JSON.stringify(err)}`);
        }
      });
    }
  }

  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    this.windowStage = windowStage;
    try {
      await AppDatabase.getInstance().init(this.context);
      await SpendingCardService.refreshAllForms(this.context);
    } catch (error) {
      hilog.error(DOMAIN, 'EntryAbility', `startup card refresh failed: ${JSON.stringify(error)}`);
    }

    const page = this.resolveLaunchPage(this.savedLaunchWant) || 'pages/Index';
    windowStage.loadContent(page, (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'EntryAbility', `load content failed: ${JSON.stringify(err)}`);
      }
    });
  }

  private resolveLaunchPage(want: Want | undefined): string {
    const page = want?.parameters?.['targetPage'];
    return typeof page === 'string' ? page : '';
  }

  private refreshSpendingCard(): void {
    SpendingCardService.refreshAllForms(this.context).catch((error: Error) => {
      hilog.warn(DOMAIN, 'EntryAbility', `foreground card refresh failed: ${error.message}`);
    });
  }
}
