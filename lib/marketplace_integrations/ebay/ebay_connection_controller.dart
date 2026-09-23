import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:profit_track/features/sales/application/sales_controller.dart';
import 'package:profit_track/marketplace_integrations/ebay/ebay_marketplace_service.dart';
import 'package:profit_track/marketplace_sync/marketplace_sync_service.dart';

final ebayMarketplaceServiceProvider = Provider<EbayMarketplaceService>(
  (ref) => EbayMarketplaceService(),
);

final ebayConnectionControllerProvider =
    AsyncNotifierProvider<EbayConnectionController, EbayConnectionInfo>(
      EbayConnectionController.new,
    );

class EbayConnectionController extends AsyncNotifier<EbayConnectionInfo> {
  late EbayMarketplaceService service;

  @override
  Future<EbayConnectionInfo> build() {
    service = ref.watch(ebayMarketplaceServiceProvider);
    return service.loadConnection();
  }

  Future<EbayConnectionInfo> connect() async {
    final previous = state.value ?? const EbayConnectionInfo.disconnected();
    state = AsyncData(previous.copyWith(busy: true));
    try {
      final connected = await service.connect();
      state = AsyncData(connected);
      return connected;
    } catch (_) {
      state = AsyncData(previous.copyWith(busy: false));
      rethrow;
    }
  }

  Future<MarketplaceSyncResult> sync() async {
    final previous = state.value ?? await service.loadConnection();
    state = AsyncData(previous.copyWith(busy: true));
    try {
      final result = await service.sync(
        ref.read(salesRepositoryProvider),
        since: previous.lastSyncedAt?.subtract(const Duration(days: 1)),
      );
      await ref.read(salesControllerProvider.notifier).load();
      final updated = await service.loadConnection();
      state = AsyncData(updated);
      return result;
    } catch (_) {
      state = AsyncData(previous.copyWith(busy: false));
      rethrow;
    }
  }

  Future<void> disconnect() async {
    final previous = state.value ?? const EbayConnectionInfo.disconnected();
    state = AsyncData(previous.copyWith(busy: true));
    try {
      await service.disconnect();
      state = const AsyncData(EbayConnectionInfo.disconnected());
    } catch (_) {
      state = AsyncData(previous.copyWith(busy: false));
      rethrow;
    }
  }
}
