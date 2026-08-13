import { fileIo } from '@kit.CoreFileKit';
import { CategoryRankItem } from '../viewmodel/StatisticsViewModel';
import { TrendPoint } from '../repository/RecordRepository';
import { NumberUtil } from './NumberUtil';

export class StatisticsPdfReport {
  rangeLabel: string = '';
  income: number = 0;
  expense: number = 0;
  balance: number = 0;
  categoryRanks: CategoryRankItem[] = [];
  trendPoints: TrendPoint[] = [];
}

export class StatisticsPdfExporter {
  static exportToUri(uri: string, report: StatisticsPdfReport): void {
    const file = fileIo.openSync(uri, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC);
    try {
      fileIo.writeSync(file.fd, StatisticsPdfExporter.createPdf(report));
    } finally {
      fileIo.closeSync(file);
    }
  }

  private static createPdf(report: StatisticsPdfReport): string {
    const content = StatisticsPdfExporter.createContent(report);
    const objects: string[] = [
      '<< /Type /Catalog /Pages 2 0 R >>',
      '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
      '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 5 0 R >> >> /Contents 4 0 R >>',
      `<< /Length ${content.length} >>\nstream\n${content}\nendstream`,
      '<< /Type /Font /Subtype /Type0 /BaseFont /STSong-Light /Encoding /UniGB-UCS2-H /DescendantFonts [6 0 R] >>',
      '<< /Type /Font /Subtype /CIDFontType0 /BaseFont /STSong-Light /CIDSystemInfo << /Registry (Adobe) /Ordering (GB1) /Supplement 2 >> /FontDescriptor 7 0 R >>',
      '<< /Type /FontDescriptor /FontName /STSong-Light /Flags 4 /Ascent 880 /Descent -120 /CapHeight 660 /StemV 80 /ItalicAngle 0 /MissingWidth 500 /FontBBox [-260 -200 1000 900] >>'
    ];

    let pdf = '%PDF-1.4\n';
    const offsets: number[] = [0];
    objects.forEach((object: string, index: number) => {
      offsets.push(pdf.length);
      pdf += `${index + 1} 0 obj\n${object}\nendobj\n`;
    });

    const xrefOffset = pdf.length;
    pdf += `xref\n0 ${objects.length + 1}\n`;
    pdf += '0000000000 65535 f \n';
    for (let index = 1; index < offsets.length; index++) {
      pdf += `${StatisticsPdfExporter.padOffset(offsets[index])} 00000 n \n`;
    }
    pdf += `trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\nstartxref\n${xrefOffset}\n%%EOF`;
    return pdf;
  }

  private static createContent(report: StatisticsPdfReport): string {
    const lines: string[] = [
      '一页账统计报表',
      `时间范围：${report.rangeLabel}`,
      `收入：${NumberUtil.money(report.income)}    支出：${NumberUtil.money(report.expense)}    结余：${NumberUtil.money(report.balance)}`,
      '',
      '分类支出排行'
    ];

    if (report.categoryRanks.length === 0) {
      lines.push('暂无分类支出数据');
    } else {
      report.categoryRanks.slice(0, 12).forEach((item: CategoryRankItem, index: number) => {
        lines.push(`${index + 1}. ${item.categoryName}    ${item.recordCount} 笔    ${item.percent}%    ${NumberUtil.money(item.amount)}`);
      });
    }

    lines.push('');
    lines.push('趋势明细');
    if (report.trendPoints.length === 0) {
      lines.push('暂无趋势数据');
    } else {
      report.trendPoints.slice(0, 18).forEach((item: TrendPoint) => {
        lines.push(`${item.label}    收入 ${NumberUtil.money(item.income)}    支出 ${NumberUtil.money(item.expense)}`);
      });
    }

    let content = 'BT\n/F1 18 Tf\n50 790 Td\n';
    lines.forEach((line: string, index: number) => {
      const fontSize = index === 0 ? 18 : 11;
      if (index > 0) {
        content += '0 -24 Td\n';
      }
      content += `/F1 ${fontSize} Tf\n${StatisticsPdfExporter.textCommand(line)}\n`;
    });
    content += 'ET';
    return content;
  }

  private static textCommand(text: string): string {
    return `<${StatisticsPdfExporter.toUtf16Hex(text)}> Tj`;
  }

  private static toUtf16Hex(text: string): string {
    let hex = 'FEFF';
    for (let index = 0; index < text.length; index++) {
      const code = text.charCodeAt(index);
      hex += StatisticsPdfExporter.toFourHex(code);
    }
    return hex;
  }

  private static toFourHex(value: number): string {
    let hex = value.toString(16).toUpperCase();
    while (hex.length < 4) {
      hex = `0${hex}`;
    }
    return hex;
  }

  private static padOffset(value: number): string {
    let text = `${value}`;
    while (text.length < 10) {
      text = `0${text}`;
    }
    return text;
  }
}
