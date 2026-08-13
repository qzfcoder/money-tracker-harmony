export class AppColors {
  static CANVAS: string = '#F1FAFF';
  static SURFACE: string = '#FFFFFF';
  static SURFACE_SOFT: string = '#F6FBFF';
  static SURFACE_TINT: string = '#EAF4FF';
  static INK: string = '#10263D';
  static MUTED: string = '#6E8093';
  static FAINT: string = '#A4B3C4';
  static LINE: string = '#E6F0F8';
  static LEDGER: string = '#327DEB';
  static LEDGER_DARK: string = '#122840';
  static INCOME: string = '#21BA78';
  static EXPENSE: string = '#F46F80';
  static WARNING: string = '#E7A936';
  static ACCENT: string = '#2F7EF7';
  static LILAC: string = '#826CFF';
  static CHART_BLUE: string = '#2F7EF7';
  static CHART_CYAN: string = '#19BFAF';
  static CHART_ORANGE: string = '#FFB33D';
  static CHART_PINK: string = '#FF6F8D';
  static CHART_PURPLE: string = '#826CFF';
  static CHART_GREEN: string = '#21BA78';
  static SHADOW: string = '#315F7D12';

  static useLight(): void {
    AppColors.CANVAS = '#F1FAFF';
    AppColors.SURFACE = '#FFFFFF';
    AppColors.SURFACE_SOFT = '#F6FBFF';
    AppColors.SURFACE_TINT = '#EAF4FF';
    AppColors.INK = '#10263D';
    AppColors.MUTED = '#6E8093';
    AppColors.FAINT = '#A4B3C4';
    AppColors.LINE = '#E6F0F8';
    AppColors.LEDGER = '#327DEB';
    AppColors.LEDGER_DARK = '#122840';
    AppColors.INCOME = '#21BA78';
    AppColors.EXPENSE = '#F46F80';
    AppColors.WARNING = '#E7A936';
    AppColors.ACCENT = '#2F7EF7';
    AppColors.LILAC = '#826CFF';
    AppColors.CHART_BLUE = '#2F7EF7';
    AppColors.CHART_CYAN = '#19BFAF';
    AppColors.CHART_ORANGE = '#FFB33D';
    AppColors.CHART_PINK = '#FF6F8D';
    AppColors.CHART_PURPLE = '#826CFF';
    AppColors.CHART_GREEN = '#21BA78';
    AppColors.SHADOW = '#315F7D12';
  }

  static useDark(): void {
    AppColors.CANVAS = '#0B1220';
    AppColors.SURFACE = '#162235';
    AppColors.SURFACE_SOFT = '#101A2B';
    AppColors.SURFACE_TINT = '#213653';
    AppColors.INK = '#EEF6FF';
    AppColors.MUTED = '#9FB0C4';
    AppColors.FAINT = '#65778F';
    AppColors.LINE = '#25364C';
    AppColors.LEDGER = '#7DB3FF';
    AppColors.LEDGER_DARK = '#DCEBFF';
    AppColors.INCOME = '#4ED99A';
    AppColors.EXPENSE = '#FF8898';
    AppColors.WARNING = '#F2C15A';
    AppColors.ACCENT = '#75ABFF';
    AppColors.LILAC = '#A99CFF';
    AppColors.CHART_BLUE = '#75ABFF';
    AppColors.CHART_CYAN = '#42D4C8';
    AppColors.CHART_ORANGE = '#FFC46B';
    AppColors.CHART_PINK = '#FF8AA2';
    AppColors.CHART_PURPLE = '#A99CFF';
    AppColors.CHART_GREEN = '#4ED99A';
    AppColors.SHADOW = '#00000028';
  }
}

export class AppRadius {
  static readonly CARD: number = 18;
  static readonly CONTROL: number = 16;
  static readonly PILL: number = 999;
}

export class AppSpace {
  static readonly PAGE: number = 14;
  static readonly PAGE_WIDE: number = 24;
  static readonly SECTION: number = 18;
  static readonly CARD: number = 18;
}

export class Breakpoints {
  static readonly TABLET: number = 840;
  static readonly WIDE: number = 1024;
  static readonly DESKTOP: number = 1200;
}

export class LayoutSizes {
  static readonly CONTENT_MAX: number = 920;
  static readonly CONTENT_COMPACT: number = 680;
}
