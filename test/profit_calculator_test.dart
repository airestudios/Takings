import 'package:flutter_test/flutter_test.dart';
import 'package:profit_track/features/sales/domain/profit_calculator.dart';
import 'package:profit_track/features/sales/domain/sale.dart';

void main() {
  Sale sale({
    int revenue = 4000,
    int cost = 1200,
    int fees = 250,
    int postage = 350,
    int packaging = 0,
    SaleStatus status = SaleStatus.completed,
  }) {
    return Sale(
      id: '1',
      title: 'Item',
      marketplace: 'Vinted',
      soldAt: DateTime(2026),
      sellingPriceMinor: revenue,
      purchaseCostMinor: cost,
      feeMinor: fees,
      postageMinor: postage,
      packagingMinor: packaging,
      status: status,
    );
  }

  test('calculates net profit, margin and ROI in minor units', () {
    final result = sale();
    expect(result.netProfitMinor, 2200);
    expect(result.margin, closeTo(55, .0001));
    expect(result.roi, closeTo(183.333, .001));
  });

  test('handles zero revenue and zero purchase cost safely', () {
    final result = sale(revenue: 0, cost: 0, fees: 0, postage: 0);
    expect(result.margin, 0);
    expect(result.roi, isNull);
  });

  test('retains negative profit', () {
    expect(
      sale(revenue: 1000, cost: 1500, fees: 100, postage: 100).netProfitMinor,
      -700,
    );
  });

  test('does not count refunded or cancelled revenue', () {
    final sales = [
      sale(),
      sale(status: SaleStatus.refunded),
      sale(status: SaleStatus.cancelled),
    ];
    expect(ProfitCalculator.revenue(sales), 4000);
    expect(ProfitCalculator.netProfit(sales), 2200);
  });
}
