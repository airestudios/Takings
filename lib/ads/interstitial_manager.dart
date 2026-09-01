import 'dart:io';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:profit_track/ads/ad_event_recorder.dart';
import 'package:profit_track/ads/ad_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InterstitialManager {
  InterstitialManager._();

  static final instance = InterstitialManager._();
  static const minimumActions = 8;
  static const maximumPerDay = 2;
  static const cooldown = Duration(minutes: 30);
  InterstitialAd? ad;
  bool shownThisSession = false;

  Future<void> recordMeaningfulAction() async {
    final preferences = await SharedPreferences.getInstance();
    final actions = (preferences.getInt('ad_meaningful_actions') ?? 0) + 1;
    await preferences.setInt('ad_meaningful_actions', actions);
    if (actions >= minimumActions) await _preload();
  }

  Future<void> markSafeTransitionPending() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('ad_safe_transition_pending', true);
  }

  Future<bool> showPendingIfReady() async {
    final preferences = await SharedPreferences.getInstance();
    if (!(preferences.getBool('ad_safe_transition_pending') ?? false)) {
      return false;
    }
    if (!await eligible()) return false;
    await AdEventRecorder.record(
      'interstitial_eligible',
      AdPlacements.sessionInterstitial,
      'interstitial',
    );
    final shown = await showIfReady();
    if (shown) {
      await preferences.setBool('ad_safe_transition_pending', false);
    }
    return shown;
  }

  Future<bool> eligible() async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    final preferences = await SharedPreferences.getInstance();
    if (!(preferences.getBool('ad_first_session_complete') ?? false))
      return false;
    if (shownThisSession) return false;
    if ((preferences.getInt('ad_meaningful_actions') ?? 0) < minimumActions)
      return false;
    final now = DateTime.now();
    final dayKey = '${now.year}-${now.month}-${now.day}';
    if (preferences.getString('ad_interstitial_day') != dayKey) {
      await preferences.setString('ad_interstitial_day', dayKey);
      await preferences.setInt('ad_interstitials_today', 0);
    }
    if ((preferences.getInt('ad_interstitials_today') ?? 0) >= maximumPerDay)
      return false;
    final lastMillis = preferences.getInt('ad_last_interstitial');
    if (lastMillis != null &&
        now.difference(DateTime.fromMillisecondsSinceEpoch(lastMillis)) <
            cooldown)
      return false;
    return true;
  }

  Future<void> markFirstSessionComplete() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('ad_first_session_complete', true);
  }

  Future<bool> showIfReady() async {
    if (!await eligible()) return false;
    if (ad == null) {
      await _preload();
      return false;
    }
    final current = ad!;
    ad = null;
    current.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (value) {
        value.dispose();
        _preload();
      },
      onAdFailedToShowFullScreenContent: (value, error) {
        value.dispose();
        _preload();
      },
    );
    await current.show();
    shownThisSession = true;
    final preferences = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await preferences.setInt(
      'ad_last_interstitial',
      now.millisecondsSinceEpoch,
    );
    await preferences.setInt(
      'ad_interstitials_today',
      (preferences.getInt('ad_interstitials_today') ?? 0) + 1,
    );
    await preferences.setInt('ad_meaningful_actions', 0);
    await AdEventRecorder.record(
      'interstitial_shown',
      AdPlacements.sessionInterstitial,
      'interstitial',
    );
    return true;
  }

  Future<void> _preload() async {
    if (ad != null || !await eligible()) return;
    final unitId = AdService.unitId(AdFormat.interstitial);
    if (unitId == null || !await AdService.canRequestAds()) return;
    await InterstitialAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (value) {
          ad = value;
          AdEventRecorder.record(
            'ad_loaded',
            AdPlacements.sessionInterstitial,
            'interstitial',
          );
        },
        onAdFailedToLoad: (error) {
          ad = null;
          AdEventRecorder.record(
            'ad_failed',
            AdPlacements.sessionInterstitial,
            'interstitial',
          );
        },
      ),
    );
  }
}
