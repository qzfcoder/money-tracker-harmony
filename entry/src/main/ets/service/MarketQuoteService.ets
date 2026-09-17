import { http } from '@kit.NetworkKit';
import { InvestmentType } from '../model/Investment';

interface EastMoneyQuoteData {
  f43: number;
  f57: string;
  f58: string;
}

interface EastMoneyQuoteResponse {
  rc: number;
  data?: EastMoneyQuoteData;
}

interface FundNavItem {
  FSRQ: string;
  DWJZ: string;
}

interface FundNavData {
  LSJZList: FundNavItem[];
}

interface FundNavResponse {
  ErrCode: number;
  Data?: FundNavData;
}

export class MarketQuote {
  code: string = '';
  name: string = '';
  price: number = 0;
  quoteTime: number = 0;
}

export class MarketQuoteService {
  static async fetch(type: InvestmentType, rawCode: string): Promise<MarketQuote> {
    const code = MarketQuoteService.normalizeCode(rawCode);
    if (!code) {
      throw new Error('请输入证券代码');
    }
    if (type === InvestmentType.FUND) {
      return await MarketQuoteService.fetchFund(code);
    }
    try {
      return await MarketQuoteService.fetchTencentSecurity(code);
    } catch (error) {
      return await MarketQuoteService.fetchSecurity(code);
    }
  }

  static normalizeCode(rawCode: string): string {
    return rawCode.trim().toUpperCase().replace(/[^0-9A-Z.]/g, '');
  }

  private static async fetchSecurity(code: string): Promise<MarketQuote> {
    const secId = MarketQuoteService.eastMoneySecId(code);
    const url = `https://push2.eastmoney.com/api/qt/stock/get?secid=${secId}&fields=f43,f57,f58`;
    const body = await MarketQuoteService.get(url);
    const response = JSON.parse(body) as EastMoneyQuoteResponse;
    if (response.rc !== 0 || !response.data || response.data.f43 <= 0) {
      throw new Error('暂未获取到行情');
    }
    const quote = new MarketQuote();
    quote.code = response.data.f57 || code;
    quote.name = response.data.f58 || code;
    quote.price = Math.round(response.data.f43) / 100;
    quote.quoteTime = Date.now();
    return quote;
  }

  private static async fetchTencentSecurity(code: string): Promise<MarketQuote> {
    const symbol = MarketQuoteService.tencentSymbol(code);
    const body = await MarketQuoteService.get(
      `https://web.ifzq.gtimg.cn/appstock/app/fqkline/get?param=${symbol},day,,,1,qfq&_=${Date.now()}`,
      'https://gu.qq.com/'
    );
    const marker = `"qt":{"${symbol}":[`;
    const start = body.indexOf(marker);
    const end = start >= 0 ? body.indexOf('],"market"', start + marker.length) : -1;
    if (start < 0 || end <= start) {
      throw new Error('股票行情格式异常');
    }
    const fields = JSON.parse(`[${body.substring(start + marker.length, end)}]`) as string[];
    const price = fields.length > 3 ? Number(fields[3]) : 0;
    if (Number.isNaN(price) || price <= 0) {
      throw new Error('暂未获取到股票行情');
    }
    const quote = new MarketQuote();
    quote.code = MarketQuoteService.pureSecurityCode(code);
    quote.name = fields.length > 1 && fields[1].trim().length > 0 ? fields[1] : quote.code;
    quote.price = Math.round(price * 10000) / 10000;
    quote.quoteTime = Date.now();
    return quote;
  }

  private static async fetchFund(code: string): Promise<MarketQuote> {
    const url = `https://api.fund.eastmoney.com/f10/lsjz?fundCode=${code}&pageIndex=1&pageSize=1&_=${Date.now()}`;
    const body = await MarketQuoteService.get(url, 'https://fundf10.eastmoney.com/');
    const response = JSON.parse(body) as FundNavResponse;
    const priceText = response.ErrCode === 0 && response.Data && response.Data.LSJZList.length > 0 ?
      response.Data.LSJZList[0].DWJZ : '';
    const price = Number(priceText);
    if (!priceText || Number.isNaN(price) || price <= 0) {
      throw new Error('暂未获取到基金净值');
    }
    const quote = new MarketQuote();
    quote.code = code;
    quote.name = code;
    quote.price = Math.round(price * 10000) / 10000;
    quote.quoteTime = Date.now();
    return quote;
  }

  private static eastMoneySecId(code: string): string {
    const pureCode = MarketQuoteService.pureSecurityCode(code);
    const upperCode = code.toUpperCase();
    if (upperCode.startsWith('SH') || upperCode.endsWith('.SH') || pureCode.startsWith('5') ||
      pureCode.startsWith('6') || pureCode.startsWith('9')) {
      return `1.${pureCode}`;
    }
    if (upperCode.startsWith('BJ') || upperCode.endsWith('.BJ') || pureCode.startsWith('4') || pureCode.startsWith('8')) {
      return `0.${pureCode}`;
    }
    return `0.${pureCode}`;
  }

  private static tencentSymbol(code: string): string {
    const pureCode = MarketQuoteService.pureSecurityCode(code);
    const upperCode = code.toUpperCase();
    if (upperCode.startsWith('BJ') || upperCode.endsWith('.BJ') || pureCode.startsWith('4') || pureCode.startsWith('8')) {
      return `bj${pureCode}`;
    }
    if (upperCode.startsWith('SH') || upperCode.endsWith('.SH') || pureCode.startsWith('5') ||
      pureCode.startsWith('6') || pureCode.startsWith('9')) {
      return `sh${pureCode}`;
    }
    return `sz${pureCode}`;
  }

  private static pureSecurityCode(code: string): string {
    return code.toUpperCase().replace(/^(SH|SZ|BJ)/, '').replace(/\.(SH|SZ|BJ)$/, '');
  }

  private static async get(url: string, referer: string = 'https://quote.eastmoney.com/'): Promise<string> {
    const request = http.createHttp();
    try {
      const response = await request.request(url, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 6000,
        readTimeout: 6000,
        header: {
          'User-Agent': 'Mozilla/5.0',
          'Referer': referer,
          'Cache-Control': 'no-cache, no-store',
          'Pragma': 'no-cache'
        }
      });
      if (response.responseCode < 200 || response.responseCode >= 300) {
        throw new Error(`行情服务返回 ${response.responseCode}`);
      }
      return response.result as string;
    } finally {
      request.destroy();
    }
  }
}
