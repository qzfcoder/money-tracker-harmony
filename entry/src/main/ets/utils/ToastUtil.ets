import { promptAction } from '@kit.ArkUI';

export class ToastUtil {
  static show(message: string): void {
    promptAction.showToast({
      message,
      duration: 1800
    });
  }

  static error(error: Object, fallback: string = '操作失败，请重试'): string {
    const item = error as Error;
    const message = item.message || `${error}`;
    const detail = error as Record<string, Object>;
    const code = detail['code'];
    if (message === '[object Object]' || message.length === 0) {
      return code !== undefined ? `${fallback}（${code}）` : fallback;
    }
    return code !== undefined ? `${message}（${code}）` : message;
  }
}
