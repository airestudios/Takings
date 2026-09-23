import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:app_links/app_links.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:profit_track/features/sales/data/sales_repository.dart';
import 'package:profit_track/marketplace_integrations/domain/marketplace_connector.dart';
import 'package:profit_track/marketplace_sync/marketplace_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const _defaultBackendUrl = 'https://takings-ebay-airedesign.vercel.app';

class EbayConnectionInfo {
  const EbayConnectionInfo({
    required this.connected,
    this.lastSyncedAt,
    this.busy = false,
  });

  const EbayConnectionInfo.disconnected()
    : connected = false,
      lastSyncedAt = null,
      busy = false;

  final bool connected;
  final DateTime? lastSyncedAt;
  final bool busy;

  EbayConnectionInfo copyWith({
    bool? connected,
    DateTime? lastSyncedAt,
    bool? busy,
    bool clearLastSyncedAt = false,
  }) => EbayConnectionInfo(
    connected: connected ?? this.connected,
    lastSyncedAt: clearLastSyncedAt
        ? null
        : lastSyncedAt ?? this.lastSyncedAt,
    busy: busy ?? this.busy,
  );
}

class EbayMarketplaceService {
  EbayMarketplaceService({Dio? dio, FlutterSecureStorage? storage})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: const String.fromEnvironment(
                'EBAY_BACKEND_URL',
                defaultValue: _defaultBackendUrl,
              ),
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 30),
              headers: const {'accept': 'application/json'},
            ),
          ),
      _storage = storage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'ebay_access_token';
  static const _refreshTokenKey = 'ebay_refresh_token';
  static const _expiresAtKey = 'ebay_expires_at';
  static const _lastSyncKey = 'ebay_last_sync';

  final Dio _dio;
  final FlutterSecureStorage _storage;

  Future<EbayConnectionInfo> loadConnection() async {
    final credentials = await _loadCredentials();
    if (credentials == null) return const EbayConnectionInfo.disconnected();
    final preferences = await SharedPreferences.getInstance();
    return EbayConnectionInfo(
      connected: true,
      lastSyncedAt: DateTime.tryParse(
        preferences.getString(_lastSyncKey) ?? '',
      ),
    );
  }

  Future<EbayConnectionInfo> connect() async {
    final state = _randomToken(32);
    final appLinks = AppLinks();
    final callbackFuture = appLinks.uriLinkStream
        .firstWhere(_isEbayCallback)
        .timeout(const Duration(minutes: 5));
    final authorizationUri = Uri.parse(
      '${_dio.options.baseUrl}/api/ebay/start',
    ).replace(queryParameters: {'state': state});
    final launched = await launchUrl(
      authorizationUri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      throw const EbayConnectionException('Could not open eBay sign-in.');
    }

    final callback = await callbackFuture;
    if (callback.queryParameters['state'] != state) {
      throw const EbayConnectionException(
        'eBay sign-in could not be verified. Please try again.',
      );
    }
    final oauthError =
        callback.queryParameters['error_description'] ??
        callback.queryParameters['error'];
    if (oauthError != null) throw EbayConnectionException(oauthError);
    final code = callback.queryParameters['code'];
    if (code == null || code.isEmpty) {
      throw const EbayConnectionException(
        'eBay did not return a sign-in code.',
      );
    }

    final credentials = await _exchangeCode(code);
    await _saveCredentials(credentials);
    return const EbayConnectionInfo(connected: true);
  }

  Future<MarketplaceSyncResult> sync(
    SalesRepository repository, {
    DateTime? since,
  }) async {
    final credentials = await _validCredentials();
    final result = await MarketplaceSyncService(
      repository: repository,
      connector: _EbayOrdersConnector(this, credentials),
    ).sync(since: since);
    final now = DateTime.now();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_lastSyncKey, now.toIso8601String());
    return result;
  }

  Future<void> disconnect() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _expiresAtKey);
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_lastSyncKey);
  }

  Future<_EbayCredentials> _exchangeCode(String code) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/ebay/token',
        data: {'code': code},
      );
      return _credentialsFromJson(response.data ?? const {});
    } on DioException catch (error) {
      throw EbayConnectionException(_messageFrom(error));
    }
  }

  Future<_EbayCredentials> _validCredentials() async {
    final current = await _loadCredentials();
    if (current == null) {
      throw const EbayConnectionException('Connect eBay before syncing.');
    }
    if (current.expiresAt.isAfter(
      DateTime.now().add(const Duration(minutes: 2)),
    )) {
      return current;
    }
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/ebay/refresh',
        data: {'refreshToken': current.refreshToken},
      );
      final refreshed = _credentialsFromJson(
        response.data ?? const {},
        fallbackRefreshToken: current.refreshToken,
      );
      await _saveCredentials(refreshed);
      return refreshed;
    } on DioException catch (error) {
      throw EbayConnectionException(_messageFrom(error));
    }
  }

  Future<_EbayCredentials?> _loadCredentials() async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    final expiresAt = DateTime.tryParse(
      await _storage.read(key: _expiresAtKey) ?? '',
    );
    if (accessToken == null || refreshToken == null || expiresAt == null) {
      return null;
    }
    return _EbayCredentials(accessToken, refreshToken, expiresAt);
  }

  Future<void> _saveCredentials(_EbayCredentials credentials) async {
    await _storage.write(key: _accessTokenKey, value: credentials.accessToken);
    await _storage.write(
      key: _refreshTokenKey,
      value: credentials.refreshToken,
    );
    await _storage.write(
      key: _expiresAtKey,
      value: credentials.expiresAt.toIso8601String(),
    );
  }

  _EbayCredentials _credentialsFromJson(
    Map<String, dynamic> json, {
    String? fallbackRefreshToken,
  }) {
    final accessToken = json['access_token'] as String?;
    final refreshToken =
        json['refresh_token'] as String? ?? fallbackRefreshToken;
    final expiresIn = (json['expires_in'] as num?)?.toInt() ?? 7200;
    if (accessToken == null || refreshToken == null) {
      throw const EbayConnectionException(
        'eBay did not return valid account credentials.',
      );
    }
    return _EbayCredentials(
      accessToken,
      refreshToken,
      DateTime.now().add(Duration(seconds: expiresIn)),
    );
  }

  String _randomToken(int byteCount) {
    final random = Random.secure();
    return base64Url
        .encode(List<int>.generate(byteCount, (_) => random.nextInt(256)))
        .replaceAll('=', '');
  }

  bool _isEbayCallback(Uri uri) =>
      uri.scheme == 'takings' && uri.host == 'oauth' && uri.path == '/ebay';

  String _messageFrom(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['error'] is String) return data['error'] as String;
    return 'eBay could not be reached. Please try again.';
  }
}

class _EbayOrdersConnector implements MarketplaceConnector {
  _EbayOrdersConnector(this.service, this.credentials);

  final EbayMarketplaceService service;
  _EbayCredentials credentials;

  @override
  String get marketplaceId => 'ebay';

  @override
  MarketplaceAvailability get availability => MarketplaceAvailability.connected;

  @override
  Future<MarketplacePage<MarketplaceOrder>> fetchSoldOrders({
    String? cursor,
    DateTime? since,
  }) async {
    credentials = await service._validCredentials();
    try {
      final response = await service._dio.get<Map<String, dynamic>>(
        '/api/ebay/orders',
        queryParameters: {
          'limit': 100,
          'offset': int.tryParse(cursor ?? '') ?? 0,
          if (since != null) 'since': since.toUtc().toIso8601String(),
        },
        options: Options(
          headers: {'authorization': 'Bearer ${credentials.accessToken}'},
        ),
      );
      final body = response.data ?? const {};
      final rows =
          (body['items'] as List?)?.whereType<Map>().toList() ?? const [];
      final items = rows
          .map((row) => Map<String, dynamic>.from(row))
          .where((row) => (row['title'] as String? ?? '').trim().isNotEmpty)
          .map(_orderFromJson)
          .toList();
      return MarketplacePage(
        items: items,
        nextCursor: body['nextOffset']?.toString(),
      );
    } on DioException catch (error) {
      throw EbayConnectionException(service._messageFrom(error));
    }
  }

  MarketplaceOrder _orderFromJson(Map<String, dynamic> json) {
    final state = switch (json['state'] as String? ?? 'completed') {
      'refunded' => MarketplaceOrderState.refunded,
      'partiallyRefunded' => MarketplaceOrderState.partiallyRefunded,
      'cancelled' => MarketplaceOrderState.cancelled,
      _ => MarketplaceOrderState.completed,
    };
    return MarketplaceOrder(
      marketplace: 'eBay',
      externalOrderId: json['externalOrderId'].toString(),
      externalListingId: json['externalListingId']?.toString(),
      externalTransactionId: json['externalTransactionId']?.toString(),
      title: (json['title'] as String).trim(),
      soldAt:
          DateTime.tryParse(json['soldAt'] as String? ?? '') ?? DateTime.now(),
      sellingPriceMinor: (json['sellingPriceMinor'] as num?)?.toInt() ?? 0,
      feeMinor: (json['feeMinor'] as num?)?.toInt(),
      postageMinor: (json['postageMinor'] as num?)?.toInt(),
      currencyCode: json['currencyCode'] as String? ?? 'GBP',
      state: state,
    );
  }

  @override
  Future<Uri> createAuthorizationUri({
    required Uri callbackUri,
    required String codeChallenge,
  }) async => throw UnsupportedError('Use EbayMarketplaceService.connect');

  @override
  Future<MarketplaceCredentials> exchangeAuthorizationCode({
    required String code,
    required String codeVerifier,
  }) async => throw UnsupportedError('Use EbayMarketplaceService.connect');

  @override
  Future<MarketplaceCredentials> refresh(
    MarketplaceCredentials credentials,
  ) async => throw UnsupportedError('Token refresh is automatic');

  @override
  Future<void> revoke(MarketplaceCredentials credentials) =>
      service.disconnect();
}

class _EbayCredentials {
  const _EbayCredentials(this.accessToken, this.refreshToken, this.expiresAt);

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
}

class EbayConnectionException implements Exception {
  const EbayConnectionException(this.message);

  final String message;

  @override
  String toString() => message;
}
