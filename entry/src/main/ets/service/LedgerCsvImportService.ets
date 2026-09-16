import { buffer } from '@kit.ArkTS';
import { common } from '@kit.AbilityKit';
import { fileIo, picker } from '@kit.CoreFileKit';
import { AppDatabase } from '../database/AppDatabase';
import { AccountModel } from '../model/Account';
import { CategoryModel } from '../model/Category';
import { RecordModel, RecordType } from '../model/Record';
import { AccountRepository } from '../repository/AccountRepository';
import { CategoryRepository } from '../repository/CategoryRepository';
import { RecordRepository } from '../repository/RecordRepository';

export class LedgerCsvImportResult {
  totalRows: number = 0;
  importedRows: number = 0;
  skippedRows: number = 0;
}

export class LedgerCsvImportService {
  private static readonly MAX_FILE_SIZE: number = 16 * 1024 * 1024;
  private recordRepository: RecordRepository = new RecordRepository();
  private categoryRepository: CategoryRepository = new CategoryRepository();
  private accountRepository: AccountRepository = new AccountRepository();

  constructor() {}

  async pickAndImport(context: common.UIAbilityContext): Promise<LedgerCsvImportResult> {
    const options = new picker.DocumentSelectOptions();
    options.maxSelectNumber = 1;
    options.fileSuffixFilters = ['CSV 账单文件|.csv'];
    const uris = await new picker.DocumentViewPicker(context).select(options);
    if (uris.length === 0) {
      throw new Error('未选择 CSV 文件');
    }
    return await this.importUri(uris[0]);
  }

  private async importUri(uri: string): Promise<LedgerCsvImportResult> {
    const rows = this.parseCsv(this.readUtf8File(uri));
    const headerIndex = this.findHeaderRow(rows);
    if (headerIndex < 0) {
      throw new Error('未识别到一页账 CSV 表头');
    }

    const header = rows[headerIndex];
    const dateIndex = this.findColumn(header, ['日期', '交易时间', '时间']);
    const typeIndex = this.findColumn(header, ['类型', '收支', '收/支', '交易类型']);
    const categoryIndex = this.findColumn(header, ['分类', '交易分类']);
    const amountIndex = this.findColumn(header, ['金额', '交易金额', '金额(元)', '收/付款金额']);
    const accountIndex = this.findColumn(header, ['账户', '支付方式', '收/付款方式', '付款方式', '收款方式']);
    const remarkIndex = this.findColumn(header, ['备注', '商品说明', '商品', '交易对方', '交易说明', '说明']);
    const secondRemarkIndex = this.findColumnExcept(header, ['商品说明', '商品', '交易对方', '交易说明', '说明'], remarkIndex);
    if (dateIndex < 0 || amountIndex < 0) {
      throw new Error('CSV 缺少日期或金额字段');
    }

    const categories = await this.categoryRepository.listAll();
    const accounts = await this.accountRepository.list();
    const result = new LedgerCsvImportResult();
    for (let index = headerIndex + 1; index < rows.length; index++) {
      const row = rows[index];
      if (this.isEmptyRow(row)) {
        continue;
      }
      result.totalRows++;
      const rawAmount = this.parseAmount(this.cell(row, amountIndex));
      const type = this.parseType(this.cell(row, typeIndex), rawAmount);
      const amount = Math.abs(rawAmount);
      const recordTime = this.parseTime(this.cell(row, dateIndex));
      if (!type || amount <= 0 || recordTime <= 0) {
        result.skippedRows++;
        continue;
      }
      if (type === RecordType.TRANSFER) {
        result.skippedRows++;
        continue;
      }
      const category = this.findCategory(categories, this.cell(row, categoryIndex), type);
      const account = this.findAccount(accounts, this.cell(row, accountIndex));
      const remark = this.mergeRemark(this.cell(row, remarkIndex), this.cell(row, secondRemarkIndex));
      if (!category || !account || await this.isDuplicate(type, amount, recordTime, account.id || 0, remark)) {
        result.skippedRows++;
        continue;
      }
      const record: RecordModel = {
        type,
        amount,
        categoryId: category.id || 0,
        accountId: account.id || 0,
        recordTime,
        ledgerName: '日常账本',
        remark,
        createTime: Date.now(),
        updateTime: Date.now()
      };
      await this.recordRepository.insert(record);
      result.importedRows++;
    }
    return result;
  }

  private async isDuplicate(type: RecordType, amount: number, recordTime: number, accountId: number, remark: string): Promise<boolean> {
    const result = await AppDatabase.getInstance().getStore().querySql(
      `SELECT id FROM t_record
       WHERE type = ? AND amount = ? AND account_id = ? AND record_time = ? AND remark = ?
       LIMIT 1`,
      [type, amount, accountId, recordTime, remark]
    );
    const duplicate = result.goToFirstRow();
    result.close();
    return duplicate;
  }

  private findCategory(categories: CategoryModel[], name: string, type: RecordType): CategoryModel | null {
    const exact = categories.find((item: CategoryModel) => item.type === type && item.name === name);
    if (exact) {
      return exact;
    }
    return categories.find((item: CategoryModel) => item.type === type) || null;
  }

  private findAccount(accounts: AccountModel[], name: string): AccountModel | null {
    const exact = accounts.find((item: AccountModel) => item.name === name);
    return exact || accounts[0] || null;
  }

  private parseType(value: string, amount: number): RecordType | undefined {
    if (value.includes('不计') || value.includes('转')) {
      return RecordType.TRANSFER;
    }
    if (value.includes('收入') || value === '收' || value.includes('+')) {
      return RecordType.INCOME;
    }
    if (value.includes('支出') || value === '支' || value.includes('-')) {
      return RecordType.EXPENSE;
    }
    if (amount < 0) {
      return RecordType.EXPENSE;
    }
    if (amount > 0) {
      return RecordType.INCOME;
    }
    return undefined;
  }

  private parseAmount(value: string): number {
    const normalized = value.replace(/,/g, '').replace(/[^\d.-]/g, '');
    const amount = Number(normalized);
    return Number.isNaN(amount) ? 0 : Math.round(amount * 100) / 100;
  }

  private parseTime(value: string): number {
    const normalized = value.trim()
      .replace(/[年/.]/g, '-')
      .replace(/月/g, '-')
      .replace(/日/g, '')
      .replace(/\s+/g, ' ');
    const time = Date.parse(normalized);
    return Number.isNaN(time) ? 0 : time;
  }

  private findHeaderRow(rows: string[][]): number {
    for (let index = 0; index < rows.length; index++) {
      const header = rows[index].join('|').replace(/\s+/g, '');
      if ((header.includes('日期') || header.includes('交易时间') || header.includes('时间')) && header.includes('金额')) {
        return index;
      }
    }
    return -1;
  }

  private findColumn(header: string[], names: string[]): number {
    for (let index = 0; index < header.length; index++) {
      const normalized = header[index].replace(/\s+/g, '');
      for (const name of names) {
        if (normalized.includes(name)) {
          return index;
        }
      }
    }
    return -1;
  }

  private findColumnExcept(header: string[], names: string[], excluded: number): number {
    for (let index = 0; index < header.length; index++) {
      if (index === excluded) {
        continue;
      }
      const normalized = header[index].replace(/\s+/g, '');
      for (const name of names) {
        if (normalized.includes(name)) {
          return index;
        }
      }
    }
    return -1;
  }

  private mergeRemark(first: string, second: string): string {
    const left = first.trim();
    const right = second.trim();
    if (left.length === 0) {
      return right;
    }
    if (right.length === 0 || left === right) {
      return left;
    }
    return `${left} ${right}`;
  }

  private readUtf8File(uri: string): string {
    const file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
    try {
      const size = fileIo.statSync(file.fd).size;
      if (size <= 0) {
        throw new Error('CSV 文件为空');
      }
      if (size > LedgerCsvImportService.MAX_FILE_SIZE) {
        throw new Error('CSV 文件超过 16MB');
      }
      const bytes = new ArrayBuffer(size);
      const readLength = fileIo.readSync(file.fd, bytes);
      return buffer.from(bytes).toString('utf8', 0, readLength).replace(/^\uFEFF/, '');
    } finally {
      fileIo.closeSync(file);
    }
  }

  private parseCsv(text: string): string[][] {
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

  private cell(row: string[], index: number): string {
    return index >= 0 && index < row.length ? row[index].trim() : '';
  }

  private isEmptyRow(row: string[]): boolean {
    return row.every((item: string) => item.trim().length === 0);
  }
}
