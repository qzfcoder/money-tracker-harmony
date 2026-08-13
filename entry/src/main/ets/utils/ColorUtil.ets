export class ColorUtil {
  static alpha(hex: string, alpha: string): string {
    const normalized = hex.startsWith('#') ? hex.substring(1) : hex;
    return `#${alpha}${normalized}`;
  }
}

