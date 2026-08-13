export class NumberUtil {
  static money(value: number, currency: string = '¥'): string {
    return `${currency}${value.toFixed(2)}`;
  }

  static plainMoney(value: number): string {
    return value.toFixed(2);
  }

  static compactMoney(value: number, currency: string = '¥'): string {
    const absoluteValue = Math.abs(value);
    if (absoluteValue >= 100000000) {
      return `${value < 0 ? '-' : ''}${currency}${(absoluteValue / 100000000).toFixed(2)}亿`;
    }
    if (absoluteValue >= 10000) {
      return `${value < 0 ? '-' : ''}${currency}${(absoluteValue / 10000).toFixed(2)}万`;
    }
    const amount = value.toFixed(2).replace(/\.00$/, '').replace(/(\.\d)0$/, '$1');
    return `${currency}${amount}`;
  }

  static toCentSafe(value: string): number {
    const normalized = value.trim();
    if (!normalized) {
      return 0;
    }
    const numberValue = Number(normalized);
    if (Number.isNaN(numberValue)) {
      return 0;
    }
    return Math.round(numberValue * 100) / 100;
  }
}
