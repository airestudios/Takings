import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._();

  static Future<void> initialize() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    final completed = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        await ConsentForm.loadAndShowConsentFormIfRequired((error) async {
          await _initializeAdsIfAllowed();
          if (!completed.isCompleted) completed.complete();
        });
      },
      (error) async {
        await _initializeAdsIfAllowed();
        if (!completed.isCompleted) completed.complete();
      },
    );
    return completed.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () {},
    );
  }

  static Future<void> _initializeAdsIfAllowed() async {
    if (await ConsentInformation.instance.canRequestAds()) {
      await MobileAds.instance.initialize();
    }
  }

  static String? get bannerUnitId {
    const configured = String.fromEnvironment('ADMOB_BANNER_ID');
    if (configured.isNotEmpty) return configured;
    if (!kDebugMode) return null;
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/6300978111';
    if (Platform.isIOS) return 'ca-app-pub-3940256099942544/2934735716';
    return null;
  }
}
