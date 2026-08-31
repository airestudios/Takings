import 'package:profit_track/features/sales/domain/sale.dart';

abstract final class ProfitCalculator {
  static int revenue(Iterable<Sale> sales) => sales
      .where(
        (sale) =>
            sale.status == SaleStatus.completed ||
            sale.status == SaleStatus.partiallyRefunded,
      )
      .fold(0, (total, sale) => total + sale.sellingPriceMinor);

  static int netProfit(Iterable<Sale> sales) =>
      sales.fold(0, (total, sale) => total + sale.netProfitMinor);

  static double margin(Iterable<Sale> sales) {
    final revenueMinor = revenue(sales);
    return revenueMinor == 0 ? 0 : netProfit(sales) / revenueMinor * 100;
  }
}
