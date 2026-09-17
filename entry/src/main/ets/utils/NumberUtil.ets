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
    return NumberUtil.toDecimalSafe(value, 2);
  }

  static toDecimalSafe(value: string, decimalPlaces: number): number {
    const normalized = NumberUtil.normalizeDecimalInput(value, decimalPlaces).trim();
    if (!normalized) {
      return 0;
    }
    const numberValue = Number(normalized);
    if (Number.isNaN(numberValue)) {
      return 0;
    }
    const scale = Math.pow(10, decimalPlaces);
    return Math.round(numberValue * scale) / scale;
  }

  static normalizeAmountInput(value: string): string {
    return NumberUtil.normalizeDecimalInput(value, 2);
  }

  static normalizeDecimalInput(value: string, decimalPlaces: number): string {
    const cleaned = value.replace(/[^0-9.]/g, '');
    const parts = cleaned.split('.');
    if (parts.length <= 1) {
      return cleaned;
    }
    const integerPart = parts[0] || '0';
    return `${integerPart}.${parts.slice(1).join('').substring(0, decimalPlaces)}`;
  }
}
