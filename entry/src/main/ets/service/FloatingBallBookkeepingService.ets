import { common, Want } from '@kit.AbilityKit';
import floatingBall from '@ohos.window.floatingBall';
import { FeatureFlags } from '../constants/FeatureFlags';
import { ROUTES } from '../constants/RouteConstants';
import { ToastUtil } from '../utils/ToastUtil';

export interface FloatingBallStateInfo {
  supported: boolean;
  running: boolean;
  message: string;
}

export interface FloatingBallClickResult {
  recognized: boolean;
  message: string;
  text: string;
}

export class FloatingBallBookkeepingService {
  private static controller: floatingBall.FloatingBallController | null = null;
  private static running: boolean = false;
  private static clickHandler: ((result: FloatingBallClickResult) => void) | null = null;
  private static clickCallback: (() => void) | null = null;
  private static context: common.UIAbilityContext | null = null;

  static isSupported(): boolean {
    if (!FeatureFlags.FLOATING_BALL_VISIBLE) {
      return false;
    }
    try {
      return floatingBall.isFloatingBallEnabled();
    } catch (error) {
      return false;
    }
  }

  static isRunning(): boolean {
    return FloatingBallBookkeepingService.running;
  }

  static setClickHandler(handler: ((result: FloatingBallClickResult) => void) | null): void {
    FloatingBallBookkeepingService.clickHandler = handler;
  }

  static async start(context: common.Context): Promise<FloatingBallStateInfo> {
    if (!FeatureFlags.FLOATING_BALL_VISIBLE) {
      return FloatingBallBookkeepingService.state(false, false, '当前发布配置未开启闪控球');
    }
    if (!FloatingBallBookkeepingService.isSupported()) {
      return FloatingBallBookkeepingService.state(false, false, '当前设备暂不支持系统闪控球');
    }

    try {
      const abilityContext = context as common.UIAbilityContext;
      FloatingBallBookkeepingService.context = abilityContext;
      if (!FloatingBallBookkeepingService.controller) {
        FloatingBallBookkeepingService.controller = await floatingBall.create({ context: abilityContext });
      }
      FloatingBallBookkeepingService.bindClickEvent();
      await FloatingBallBookkeepingService.controller.startFloatingBall({
        template: floatingBall.FloatingBallTemplate.NORMAL,
        title: '一页账',
        content: '识别账单',
        backgroundColor: '#2F7EF7'
      });
      FloatingBallBookkeepingService.running = true;
      try {
        await FloatingBallBookkeepingService.controller.setFloatingBallVisibilityInApp(false);
      } catch (error) {
      }
      return FloatingBallBookkeepingService.state(true, true, '闪控球已开启，点球后回到识别页');
    } catch (error) {
      FloatingBallBookkeepingService.running = false;
      return FloatingBallBookkeepingService.state(true, false, ToastUtil.error(error, '闪控球开启失败，请检查权限'));
    }
  }

  static async stop(): Promise<FloatingBallStateInfo> {
    try {
      if (FloatingBallBookkeepingService.controller) {
        if (FloatingBallBookkeepingService.clickCallback) {
          FloatingBallBookkeepingService.controller.off('click', FloatingBallBookkeepingService.clickCallback);
        }
        await FloatingBallBookkeepingService.controller.stopFloatingBall();
      }
    } catch (error) {
    }
    FloatingBallBookkeepingService.clickCallback = null;
    FloatingBallBookkeepingService.running = false;
    return FloatingBallBookkeepingService.state(
      FeatureFlags.FLOATING_BALL_VISIBLE,
      false,
      FeatureFlags.FLOATING_BALL_VISIBLE ? '闪控球已关闭' : '当前发布配置未开启闪控球'
    );
  }

  private static bindClickEvent(): void {
    const controller = FloatingBallBookkeepingService.controller;
    if (!controller || FloatingBallBookkeepingService.clickCallback) {
      return;
    }
    FloatingBallBookkeepingService.clickCallback = () => {
      FloatingBallBookkeepingService.restoreToRecognitionPage();
    };
    controller.on('click', FloatingBallBookkeepingService.clickCallback);
  }

  private static async restoreToRecognitionPage(): Promise<void> {
    const controller = FloatingBallBookkeepingService.controller;
    const context = FloatingBallBookkeepingService.context;
    if (!controller || !context) {
      FloatingBallBookkeepingService.emitClickResult(false, '闪控球状态异常，请重新开启', '');
      return;
    }
    try {
      const want: Want = {
        bundleName: context.abilityInfo.bundleName,
        abilityName: context.abilityInfo.name,
        parameters: {
          targetPage: ROUTES.AUTO_BOOKKEEPING,
          launchAction: 'floatingBallOcr',
          recordTime: Date.now()
        }
      };
      await controller.restoreMainWindow(want);
      FloatingBallBookkeepingService.emitClickResult(false, '已从闪控球进入识别页', '');
    } catch (error) {
      FloatingBallBookkeepingService.emitClickResult(false, ToastUtil.error(error, '拉起识别页失败'), '');
    }
  }

  private static emitClickResult(recognized: boolean, message: string, text: string): void {
    if (FloatingBallBookkeepingService.clickHandler) {
      FloatingBallBookkeepingService.clickHandler({ recognized, message, text });
    }
  }

  private static state(supported: boolean, running: boolean, message: string): FloatingBallStateInfo {
    return {
      supported,
      running,
      message
    };
  }
}
