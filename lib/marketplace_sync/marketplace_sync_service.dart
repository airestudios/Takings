import 'package:profit_track/features/sales/data/sales_repository.dart';
import 'package:profit_track/features/sales/domain/sale.dart';
import 'package:profit_track/marketplace_integrations/domain/marketplace_connector.dart';
import 'package:uuid/uuid.dart';

class MarketplaceSyncResult {
  const MarketplaceSyncResult({
    required this.imported,
    required this.skipped,
    required this.needsPurchaseCost,
  });

  final int imported;
  final int skipped;
  final int needsPurchaseCost;
}

class MarketplaceSyncService {
  MarketplaceSyncService({required this.repository, required this.connector});

  final SalesRepository repository;
  final MarketplaceConnector connector;

  Future<MarketplaceSyncResult> sync({DateTime? since}) async {
    final existing = await repository.getAll();
    final transactionKeys = existing
        .where((sale) => sale.externalTransactionId != null)
        .map((sale) => '${sale.marketplace}:${sale.externalTransactionId}')
        .toSet();
    final orderKeys = existing
        .where((sale) => sale.externalOrderId != null)
        .map(
          (sale) =>
              '${sale.marketplace}:${sale.externalOrderId}:${sale.externalListingId ?? ''}',
        )
        .toSet();
    var imported = 0;
    var skipped = 0;
    var needsCost = 0;
    String? cursor;
    do {
      final page = await connector.fetchSoldOrders(
        cursor: cursor,
        since: since,
      );
      for (final order in page.items) {
        final transactionKey = order.externalTransactionId == null
            ? null
            : '${order.marketplace}:${order.externalTransactionId}';
        final orderKey =
            '${order.marketplace}:${order.externalOrderId}:${order.externalListingId ?? ''}';
        if ((transactionKey != null &&
                transactionKeys.contains(transactionKey)) ||
            orderKeys.contains(orderKey)) {
          skipped++;
          continue;
        }
        final now = DateTime.now();
        await repository.save(
          Sale(
            id: const Uuid().v4(),
            title: order.title,
            marketplace: order.marketplace,
            soldAt: order.soldAt,
            sellingPriceMinor: order.sellingPriceMinor,
            purchaseCostMinor: 0,
            feeMinor: order.feeMinor ?? 0,
            postageMinor: order.postageMinor ?? 0,
            importSource: ImportSource.api,
            status: switch (order.state) {
              MarketplaceOrderState.completed => SaleStatus.completed,
              MarketplaceOrderState.refunded => SaleStatus.refunded,
              MarketplaceOrderState.partiallyRefunded =>
                SaleStatus.partiallyRefunded,
              MarketplaceOrderState.cancelled => SaleStatus.cancelled,
            },
            externalListingId: order.externalListingId,
            externalOrderId: order.externalOrderId,
            externalTransactionId: order.externalTransactionId,
            importedAt: now,
            lastSyncedAt: now,
          ),
        );
        if (transactionKey != null) transactionKeys.add(transactionKey);
        orderKeys.add(orderKey);
        imported++;
        needsCost++;
      }
      cursor = page.nextCursor;
    } while (cursor != null);
    return MarketplaceSyncResult(
      imported: imported,
      skipped: skipped,
      needsPurchaseCost: needsCost,
    );
  }
}
