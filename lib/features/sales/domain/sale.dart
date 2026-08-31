enum ImportSource { manual, api, csv, backup }

enum SaleStatus { completed, refunded, partiallyRefunded, cancelled }

class Sale {
  const Sale({
    required this.id,
    required this.title,
    required this.marketplace,
    required this.soldAt,
    required this.sellingPriceMinor,
    required this.purchaseCostMinor,
    this.feeMinor = 0,
    this.postageMinor = 0,
    this.packagingMinor = 0,
    this.otherCostMinor = 0,
    this.category = 'Other',
    this.notes = '',
    this.importSource = ImportSource.manual,
    this.status = SaleStatus.completed,
    this.externalAccountId,
    this.externalListingId,
    this.externalOrderId,
    this.externalTransactionId,
    this.importedAt,
    this.lastSyncedAt,
  });

  final String id;
  final String title;
  final String marketplace;
  final DateTime soldAt;
  final int sellingPriceMinor;
  final int purchaseCostMinor;
  final int feeMinor;
  final int postageMinor;
  final int packagingMinor;
  final int otherCostMinor;
  final String category;
  final String notes;
  final ImportSource importSource;
  final SaleStatus status;
  final String? externalAccountId;
  final String? externalListingId;
  final String? externalOrderId;
  final String? externalTransactionId;
  final DateTime? importedAt;
  final DateTime? lastSyncedAt;

  int get sellingCostsMinor =>
      feeMinor + postageMinor + packagingMinor + otherCostMinor;

  int get netProfitMinor {
    if (status == SaleStatus.cancelled || status == SaleStatus.refunded) {
      return 0;
    }
    return sellingPriceMinor - purchaseCostMinor - sellingCostsMinor;
  }

  double get margin =>
      sellingPriceMinor == 0 ? 0 : netProfitMinor / sellingPriceMinor * 100;

  double? get roi =>
      purchaseCostMinor == 0 ? null : netProfitMinor / purchaseCostMinor * 100;
}
