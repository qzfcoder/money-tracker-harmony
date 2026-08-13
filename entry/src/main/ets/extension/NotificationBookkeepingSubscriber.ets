import NotificationSubscriberExtensionAbility from '@ohos.application.NotificationSubscriberExtensionAbility';
import notificationExtensionSubscription from '@ohos.notificationExtensionSubscription';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppDatabase } from '../database/AppDatabase';
import { AutoCaptureSource, AutoNotificationPayload } from '../model/AutoBookkeeping';
import { AutoBookkeepingService } from '../service/AutoBookkeepingService';

const DOMAIN = 0x0002;

export default class NotificationBookkeepingSubscriber extends NotificationSubscriberExtensionAbility {
  onReceiveMessage(notificationInfo: notificationExtensionSubscription.NotificationInfo): void {
    this.handleNotification(notificationInfo);
  }

  private async handleNotification(notificationInfo: notificationExtensionSubscription.NotificationInfo): Promise<void> {
    try {
      await AppDatabase.getInstance().init(this.context);
      const content = notificationInfo.content;
      const payload: AutoNotificationPayload = {
        source: AutoCaptureSource.NOTIFICATION,
        bundleName: notificationInfo.bundleName || '',
        appName: notificationInfo.appName || '',
        title: content.title,
        content: content.text,
        rawText: `${content.title} ${content.text}`,
        eventTime: notificationInfo.deliveryTime || Date.now()
      };
      await AutoBookkeepingService.create(this.context).handleNotification(payload);
    } catch (error) {
      hilog.error(DOMAIN, 'AutoBookkeeping', `notification parse failed: ${JSON.stringify(error)}`);
    }
  }

  onCancelMessages(hashCodes: Array<string>): void {
  }
}
