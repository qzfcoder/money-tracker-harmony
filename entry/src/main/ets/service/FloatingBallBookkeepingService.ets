import { common } from '@kit.AbilityKit';

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
  static isSupported(): boolean {
    return false;
  }

  static isRunning(): boolean {
    return false;
  }

  static setClickHandler(handler: ((result: FloatingBallClickResult) => void) | null): void {
    const unused = handler;
  }

  static async start(context: common.Context): Promise<FloatingBallStateInfo> {
    const unused = context;
    return {
      supported: false,
      running: false,
      message: '发布版请使用截图识别'
    };
  }

  static async stop(): Promise<FloatingBallStateInfo> {
    return {
      supported: false,
      running: false,
      message: '发布版请使用截图识别'
    };
  }
}
