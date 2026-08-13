import { common } from '@kit.AbilityKit';
import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { notificationManager } from '@kit.NotificationKit';
import { ToastUtil } from '../utils/ToastUtil';

export class ReminderService {
  private static readonly BUNDLE_NAME: string = 'com.ccstudio.zhiyuledger';
  private static readonly NOTIFICATION_ID: number = 10001;

  static parseTime(value: string): number[] | null {
    const match = /^(\d{1,2}):(\d{2})$/.exec(value.trim());
    if (!match) {
      return null;
    }
    const hour = Number(match[1]);
    const minute = Number(match[2]);
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }
    return [hour, minute];
  }

  static async schedule(
    context: common.UIAbilityContext,
    time: string,
    previousReminderId: number
  ): Promise<number> {
    const parts = ReminderService.parseTime(time);
    if (!parts) {
      throw new Error('提醒时间格式应为 HH:mm');
    }

    let enabled = false;
    try {
      enabled = await notificationManager.isNotificationEnabled();
      if (!enabled) {
        await notificationManager.requestEnableNotification(context);
        enabled = await notificationManager.isNotificationEnabled();
      }
    } catch (error) {
      throw new Error(`通知权限请求失败：${ToastUtil.error(error)}`);
    }
    if (!enabled) {
      throw new Error('请允许通知后再开启记账提醒');
    }

    try {
      const request = ReminderService.buildRequest(parts[0], parts[1]);
      await ReminderService.cancelExistingReminders();
      return await ReminderService.publishSingle(request);
    } catch (error) {
      try {
        const request = ReminderService.buildRequest(parts[0], parts[1]);
        await ReminderService.cancelExistingReminders();
        return await ReminderService.publishSingle(request);
      } catch (retryError) {
        throw new Error(`系统提醒发布失败：${ToastUtil.error(retryError)}`);
      }
    }
  }

  static async cancel(reminderId: number): Promise<void> {
    if (reminderId > 0) {
      try {
        await reminderAgentManager.cancelReminder(reminderId);
      } catch (error) {
      }
    }
    await ReminderService.cancelExistingReminders();
  }

  static async cancelAll(): Promise<void> {
    await ReminderService.cancelExistingReminders();
  }

  private static async publishSingle(request: reminderAgentManager.ReminderRequestAlarm): Promise<number> {
    return await reminderAgentManager.publishReminder(request);
  }

  private static async cancelExistingReminders(): Promise<void> {
    try {
      const list = await reminderAgentManager.getAllValidReminders();
      for (const item of list) {
        try {
          await reminderAgentManager.cancelReminder(item.reminderId);
        } catch (error) {
        }
      }
    } catch (error) {
    }
    try {
      await reminderAgentManager.cancelAllReminders();
    } catch (error) {
    }
  }

  private static buildRequest(hour: number, minute: number): reminderAgentManager.ReminderRequestAlarm {
    return {
      reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_ALARM,
      hour,
      minute,
      daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
      title: '记账提醒',
      content: '今天的收支记录了吗？',
      expiredContent: '别忘了补记今天的收支',
      notificationId: ReminderService.NOTIFICATION_ID,
      slotType: notificationManager.SlotType.SERVICE_INFORMATION,
      tapDismissed: true,
      wantAgent: {
        pkgName: ReminderService.BUNDLE_NAME,
        abilityName: 'EntryAbility'
      }
    };
  }
}
