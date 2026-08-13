import { buffer } from '@kit.ArkTS';
import { common } from '@kit.AbilityKit';
import { fileIo, picker } from '@kit.CoreFileKit';
import { AutoBookkeepingService } from './AutoBookkeepingService';

export class AlipayImportResult {
  fileName: string = '';
  totalRows: number = 0;
  importedRows: number = 0;
  skippedRows: number = 0;
}

interface AlipayColumnMap {
  time: number;
  direction: number;
  amount: number;
  counterparty: number;
  description: number;
  paymentMethod: number;
  status: number;
  remark: number;
}

export class AlipayBillImportService {
  private static readonly MAX_FILE_SIZE: number = 8 * 1024 * 1024;

  static async pickAndImport(context: common.UIAbilityContext): Promise<AlipayImportResult> {
    const options = new picker.DocumentSelectOptions();
    options.maxSelectNumber = 1;
    options.fileSuffixFilters = ['支付宝账单|.csv'];
    const documentPicker = new picker.DocumentViewPicker(context);
    const uris = await documentPicker.select(options);
    if (uris.length === 0) {
      throw new Error('未选择账单文件');
    }
    return await AlipayBillImportService.importUri(context, uris[0]);
  }

  private static async importUri(context: common.Context, uri: string): Promise<AlipayImportResult> {
    const content = AlipayBillImportService.readUtf8File(uri);
    const rows = AlipayBillImportService.parseCsv(content.replace(/^\uFEFF/, ''));
    const headerIndex = AlipayBillImportService.findHeaderRow(rows);
    if (headerIndex < 0) {
      throw new Error('未识别到支付宝账单表头，请选择支付宝导出的 CSV 文件');
    }

    const columns = AlipayBillImportService.buildColumnMap(rows[headerIndex]);
    if (columns.amount < 0 || columns.direction < 0) {
      throw new Error('账单缺少“金额”或“收/支”字段');
    }

    const result = new AlipayImportResult();
    result.fileName = AlipayBillImportService.fileName(uri);
    const bookkeeping = AutoBookkeepingService.create(context);
    for (let index = headerIndex + 1; index < rows.length; index++) {
      const row = rows[index];
      if (AlipayBillImportService.isEmptyRow(row)) {
        continue;
      }
      result.totalRows++;
      const direction = AlipayBillImportService.cell(row, columns.direction);
      const amount = AlipayBillImportService.parseAmount(AlipayBillImportService.cell(row, columns.amount));
      const status = AlipayBillImportService.cell(row, columns.status);
      if (!AlipayBillImportService.isBookkeepingRow(direction, amount, status)) {
        result.skippedRows++;
        continue;
      }

      const timeText = AlipayBillImportService.cell(row, columns.time);
      const counterparty = AlipayBillImportService.cell(row, columns.counterparty);
      const description = AlipayBillImportService.cell(row, columns.description);
      const paymentMethod = AlipayBillImportService.cell(row, columns.paymentMethod);
      const remark = AlipayBillImportService.cell(row, columns.remark);
      const title = description || counterparty || '支付宝账单导入';
      const rawText = [
        '支付宝',
        direction,
        `${amount.toFixed(2)}元`,
        counterparty,
        description,
        paymentMethod,
        remark
      ].filter((item: string) => item.length > 0).join(' ');
      const parseResult = await bookkeeping.captureImportedText(
        rawText,
        AlipayBillImportService.parseTime(timeText),
        title
      );
      if (parseResult.matched) {
        result.importedRows++;
      } else {
        result.skippedRows++;
      }
    }
    return result;
  }

  private static readUtf8File(uri: string): string {
    const file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
    try {
      const size = fileIo.statSync(file.fd).size;
      if (size <= 0) {
        throw new Error('账单文件为空');
      }
      if (size > AlipayBillImportService.MAX_FILE_SIZE) {
        throw new Error('账单文件超过 8MB，请分批导出后再导入');
      }
      const bytes = new ArrayBuffer(size);
      const readLength = fileIo.readSync(file.fd, bytes);
      return buffer.from(bytes).toString('utf8', 0, readLength);
    } finally {
      fileIo.closeSync(file);
    }
  }

  private static parseCsv(text: string): string[][] {
    const rows: string[][] = [];
    let row: string[] = [];
    let cell = '';
    let quoted = false;
    for (let index = 0; index < text.length; index++) {
      const char = text.charAt(index);
      if (char === '"') {
        if (quoted && index + 1 < text.length && text.charAt(index + 1) === '"') {
          cell += '"';
          index++;
        } else {
          quoted = !quoted;
        }
      } else if (char === ',' && !quoted) {
        row.push(cell.trim());
        cell = '';
      } else if ((char === '\n' || char === '\r') && !quoted) {
        if (char === '\r' && index + 1 < text.length && text.charAt(index + 1) === '\n') {
          index++;
        }
        row.push(cell.trim());
        rows.push(row);
        row = [];
        cell = '';
      } else {
        cell += char;
      }
    }
    if (cell.length > 0 || row.length > 0) {
      row.push(cell.trim());
      rows.push(row);
    }
    return rows;
  }

  private static findHeaderRow(rows: string[][]): number {
    for (let index = 0; index < rows.length; index++) {
      const normalized = rows[index].join('|').replace(/\s+/g, '');
      if (normalized.includes('交易时间') && normalized.includes('金额') &&
        (normalized.includes('收/支') || normalized.includes('收支'))) {
        return index;
      }
    }
    return -1;
  }

  private static buildColumnMap(header: string[]): AlipayColumnMap {
    return {
      time: AlipayBillImportService.findColumn(header, ['交易时间', '时间']),
      direction: AlipayBillImportService.findColumn(header, ['收/支', '收支']),
      amount: AlipayBillImportService.findColumn(header, ['金额']),
      counterparty: AlipayBillImportService.findColumn(header, ['交易对方', '对方']),
      description: AlipayBillImportService.findColumn(header, ['商品说明', '商品名称', '说明']),
      paymentMethod: AlipayBillImportService.findColumn(header, ['收/付款方式', '付款方式', '支付方式']),
      status: AlipayBillImportService.findColumn(header, ['交易状态', '状态']),
      remark: AlipayBillImportService.findColumn(header, ['备注'])
    };
  }

  private static findColumn(header: string[], names: string[]): number {
    for (let index = 0; index < header.length; index++) {
      const value = header[index].replace(/\s+/g, '');
      for (const name of names) {
        if (value === name || value.includes(name)) {
          return index;
        }
      }
    }
    return -1;
  }

  private static isBookkeepingRow(direction: string, amount: number, status: string): boolean {
    if (amount <= 0 || (!direction.includes('支出') && !direction.includes('收入'))) {
      return false;
    }
    return !status.includes('关闭') && !status.includes('失败') && !status.includes('撤销');
  }

  private static parseAmount(value: string): number {
    const match = /[0-9]+(?:\.[0-9]{1,2})?/.exec(value.replace(/,/g, ''));
    if (!match) {
      return 0;
    }
    return Math.round(Number(match[0]) * 100) / 100;
  }

  private static parseTime(value: string): number {
    const normalized = value.trim().replace(/\//g, '-');
    const timestamp = Date.parse(normalized);
    return Number.isNaN(timestamp) ? Date.now() : timestamp;
  }

  private static cell(row: string[], index: number): string {
    if (index < 0 || index >= row.length) {
      return '';
    }
    return row[index].trim();
  }

  private static isEmptyRow(row: string[]): boolean {
    return row.every((item: string) => item.trim().length === 0);
  }

  private static fileName(uri: string): string {
    const parts = uri.split('/');
    return parts.length > 0 ? parts[parts.length - 1] : '支付宝账单.csv';
  }
}
