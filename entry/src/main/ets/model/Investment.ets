export enum InvestmentType {
  STOCK = 1,
  FUND = 2
}

export interface InvestmentPosition {
  id?: number;
  name: string;
  type: InvestmentType;
  securityCode: string;
  holdingQuantity: number;
  costPrice: number;
  currentPrice: number;
  color: string;
  sortOrder: number;
  quoteTime: number;
  createTime: number;
}
