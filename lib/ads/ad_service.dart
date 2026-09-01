import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

enum AdFormat { banner, native, interstitial }

abstract final class AdPlacements {
  static const salesNative = 'sales_native_1';
  static const insightsNative = 'insights_native_1';
  static const salesBanner = 'sales_banner';
  static const insightsBanner = 'insights_banner';
  static const sessionInterstitial = 'session_interstitial';
}

class AdService {
  AdService._();

  static Future<void> initialize() async {
    if (!_mobile) return;
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

  static Future<bool> canRequestAds() async {
    if (!_mobile) return false;
    return ConsentInformation.instance.canRequestAds();
  }

  static Future<bool> privacyOptionsRequired() async {
    if (!_mobile) return false;
    return await ConsentInformation.instance
            .getPrivacyOptionsRequirementStatus() ==
        PrivacyOptionsRequirementStatus.required;
  }

  static Future<void> showPrivacyOptions() async {
    if (!_mobile) return;
    await ConsentForm.showPrivacyOptionsForm((error) {});
  }

  static String? unitId(AdFormat format) {
    if (!_mobile) return null;
    final configured = switch (format) {
      AdFormat.banner =>
        Platform.isAndroid
            ? const String.fromEnvironment('ADMOB_ANDROID_BANNER_ID')
            : const String.fromEnvironment('ADMOB_IOS_BANNER_ID'),
      AdFormat.native =>
        Platform.isAndroid
            ? const String.fromEnvironment('ADMOB_ANDROID_NATIVE_ID')
            : const String.fromEnvironment('ADMOB_IOS_NATIVE_ID'),
      AdFormat.interstitial =>
        Platform.isAndroid
            ? const String.fromEnvironment('ADMOB_ANDROID_INTERSTITIAL_ID')
            : const String.fromEnvironment('ADMOB_IOS_INTERSTITIAL_ID'),
    };
    if (configured.isNotEmpty) return configured;
    if (!kDebugMode) return null;
    return switch (format) {
      AdFormat.banner =>
        Platform.isAndroid
            ? 'ca-app-pub-3940256099942544/9214589741'
            : 'ca-app-pub-3940256099942544/2435281174',
      AdFormat.native =>
        Platform.isAndroid
            ? 'ca-app-pub-3940256099942544/2247696110'
            : 'ca-app-pub-3940256099942544/3986624511',
      AdFormat.interstitial =>
        Platform.isAndroid
            ? 'ca-app-pub-3940256099942544/1033173712'
            : 'ca-app-pub-3940256099942544/4411468910',
    };
  }

  static Future<void> _initializeAdsIfAllowed() async {
    if (await ConsentInformation.instance.canRequestAds()) {
      await MobileAds.instance.initialize();
    }
  }

  static bool get _mobile => Platform.isAndroid || Platform.isIOS;
}
