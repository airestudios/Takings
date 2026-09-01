import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:profit_track/ads/ad_service.dart';
import 'package:profit_track/ads/interstitial_manager.dart';
import 'package:profit_track/app/profit_track_app.dart';
import 'package:profit_track/app/router.dart';
import 'package:profit_track/notifications/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  if (preferences.getBool('app_has_launched_before') ?? false) {
    await InterstitialManager.instance.markFirstSessionComplete();
  } else {
    await preferences.setBool('app_has_launched_before', true);
  }
  runApp(
    ProviderScope(
      overrides: [
        onboardingCompletedProvider.overrideWithValue(
          preferences.getBool('onboarding_completed') ?? false,
        ),
      ],
      child: const ProfitTrackApp(),
    ),
  );
  unawaited(NotificationService.instance.initialize());
  unawaited(AdService.initialize());
}
