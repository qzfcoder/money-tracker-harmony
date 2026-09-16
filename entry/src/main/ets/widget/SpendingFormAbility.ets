import { Want } from '@kit.AbilityKit';
import { FormExtensionAbility, formBindingData, formInfo } from '@kit.FormKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { SpendingCardService } from './SpendingCardService';

const DOMAIN = 0x0001;

export default class SpendingFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    const formId = this.resolveFormId(want);
    hilog.info(DOMAIN, 'SpendingFormAbility', `onAddForm formId=${formId || 'empty'}`);
    this.registerForm(formId);
    return SpendingCardService.bindingData(SpendingCardService.initialData(this.context));
  }

  onUpdateForm(formId: string): void {
    if (!formId) {
      hilog.warn(DOMAIN, 'SpendingFormAbility', 'skip update with empty form id');
      return;
    }
    // The extension process has an isolated database view on some devices.
    // It must not calculate or push data here, otherwise a zero snapshot can
    // overwrite the valid snapshot written by the main application process.
    this.registerForm(formId);
  }

  onRemoveForm(formId: string): void {
    SpendingCardService.removeFormId(this.context, formId).catch((error: Error) => {
      hilog.warn(DOMAIN, 'SpendingFormAbility', `remove form id failed: ${error.message}`);
    });
  }

  private registerForm(formId: string): void {
    if (!formId) {
      return;
    }
    SpendingCardService.addFormId(this.context, formId)
      .catch((error: Error) => {
        hilog.warn(DOMAIN, 'SpendingFormAbility', `register form failed: ${error.message}`);
      });
  }

  private resolveFormId(want: Want): string {
    const value = want.parameters?.[formInfo.FormParam.IDENTITY_KEY];
    if (typeof value === 'string') {
      return value;
    }
    if (typeof value === 'number') {
      return `${value}`;
    }
    return '';
  }
}
