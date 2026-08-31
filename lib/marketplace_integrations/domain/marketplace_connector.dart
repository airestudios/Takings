enum MarketplaceAvailability {
  available,
  connected,
  requiresApproval,
  unavailable,
}

enum MarketplaceOrderState { completed, refunded, partiallyRefunded, cancelled }

class MarketplaceCredentials {
  const MarketplaceCredentials({
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
  });

  final String accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;
}

class MarketplaceOrder {
  const MarketplaceOrder({
    required this.marketplace,
    required this.externalOrderId,
    required this.title,
    required this.soldAt,
    required this.sellingPriceMinor,
    required this.currencyCode,
    this.externalListingId,
    this.externalTransactionId,
    this.feeMinor,
    this.postageMinor,
    this.state = MarketplaceOrderState.completed,
  });

  final String marketplace;
  final String externalOrderId;
  final String? externalListingId;
  final String? externalTransactionId;
  final String title;
  final DateTime soldAt;
  final int sellingPriceMinor;
  final int? feeMinor;
  final int? postageMinor;
  final String currencyCode;
  final MarketplaceOrderState state;
}

class MarketplacePage<T> {
  const MarketplacePage({required this.items, this.nextCursor});

  final List<T> items;
  final String? nextCursor;
}

abstract interface class MarketplaceConnector {
  String get marketplaceId;
  MarketplaceAvailability get availability;
  Future<Uri> createAuthorizationUri({
    required Uri callbackUri,
    required String codeChallenge,
  });
  Future<MarketplaceCredentials> exchangeAuthorizationCode({
    required String code,
    required String codeVerifier,
  });
  Future<MarketplaceCredentials> refresh(MarketplaceCredentials credentials);
  Future<MarketplacePage<MarketplaceOrder>> fetchSoldOrders({
    String? cursor,
    DateTime? since,
  });
  Future<void> revoke(MarketplaceCredentials credentials);
}

abstract interface class MarketplaceAuthenticationService {
  Future<MarketplaceCredentials> connect(MarketplaceConnector connector);
  Future<void> disconnect(
    MarketplaceConnector connector, {
    required bool keepImportedSales,
  });
}

abstract interface class MarketplaceOrderMapper<T> {
  MarketplaceOrder map(T source);
}
