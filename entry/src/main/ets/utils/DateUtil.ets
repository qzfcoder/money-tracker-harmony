export class DateUtil {
  static startOfDay(timestamp: number = Date.now()): number {
    const date = new Date(timestamp);
    return new Date(date.getFullYear(), date.getMonth(), date.getDate()).getTime();
  }

  static startOfWeek(timestamp: number = Date.now()): number {
    const date = new Date(timestamp);
    const day = date.getDay() === 0 ? 7 : date.getDay();
    return DateUtil.startOfDay(timestamp) - (day - 1) * 24 * 60 * 60 * 1000;
  }

  static startOfMonth(timestamp: number = Date.now()): number {
    const date = new Date(timestamp);
    return new Date(date.getFullYear(), date.getMonth(), 1).getTime();
  }

  static startOfNextMonth(timestamp: number = Date.now()): number {
    const date = new Date(timestamp);
    return new Date(date.getFullYear(), date.getMonth() + 1, 1).getTime();
  }

  static startOfQuarter(timestamp: number = Date.now()): number {
    const date = new Date(timestamp);
    const quarterStartMonth = Math.floor(date.getMonth() / 3) * 3;
    return new Date(date.getFullYear(), quarterStartMonth, 1).getTime();
  }

  static startOfNextQuarter(timestamp: number = Date.now()): number {
    const date = new Date(DateUtil.startOfQuarter(timestamp));
    return new Date(date.getFullYear(), date.getMonth() + 3, 1).getTime();
  }

  static startOfYear(timestamp: number = Date.now()): number {
    const date = new Date(timestamp);
    return new Date(date.getFullYear(), 0, 1).getTime();
  }

  static startOfNextYear(timestamp: number = Date.now()): number {
    const date = new Date(timestamp);
    return new Date(date.getFullYear() + 1, 0, 1).getTime();
  }

  static addDays(timestamp: number, days: number): number {
    return timestamp + days * 24 * 60 * 60 * 1000;
  }

  static monthKey(timestamp: number = Date.now()): string {
    const date = new Date(timestamp);
    const month = `${date.getMonth() + 1}`.padStart(2, '0');
    return `${date.getFullYear()}-${month}`;
  }

  static dayKey(timestamp: number): string {
    const date = new Date(timestamp);
    const month = `${date.getMonth() + 1}`.padStart(2, '0');
    const day = `${date.getDate()}`.padStart(2, '0');
    return `${date.getFullYear()}-${month}-${day}`;
  }

  static shortDay(timestamp: number): string {
    const date = new Date(timestamp);
    const month = `${date.getMonth() + 1}`.padStart(2, '0');
    const day = `${date.getDate()}`.padStart(2, '0');
    return `${month}/${day}`;
  }

  static dayLabel(timestamp: number): string {
    const date = new Date(timestamp);
    const month = `${date.getMonth() + 1}`.padStart(2, '0');
    const day = `${date.getDate()}`.padStart(2, '0');
    return `${month}月${day}日`;
  }

  static timeLabel(timestamp: number): string {
    const date = new Date(timestamp);
    const hour = `${date.getHours()}`.padStart(2, '0');
    const minute = `${date.getMinutes()}`.padStart(2, '0');
    return `${hour}:${minute}`;
  }

  static rangeLabel(startTime: number, endTime: number): string {
    const end = endTime - 1;
    return `${DateUtil.shortDay(startTime)} - ${DateUtil.shortDay(end)}`;
  }
}
