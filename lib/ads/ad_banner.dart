import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:profit_track/ads/ad_event_recorder.dart';
import 'package:profit_track/ads/ad_service.dart';

class ProfitTrackAdBanner extends StatefulWidget {
  const ProfitTrackAdBanner({required this.placement, super.key});

  final String placement;

  @override
  State<ProfitTrackAdBanner> createState() => _ProfitTrackAdBannerState();
}

class _ProfitTrackAdBannerState extends State<ProfitTrackAdBanner> {
  BannerAd? ad;
  bool loaded = false;
  int? requestedWidth;

  @override
  void dispose() {
    ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid && !Platform.isIOS) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.truncate();
        if (width > 0 && requestedWidth != width) {
          requestedWidth = width;
          WidgetsBinding.instance.addPostFrameCallback((_) => _load(width));
        }
        if (!loaded || ad == null) return const SizedBox.shrink();
        return Center(
          child: SizedBox(
            width: ad!.size.width.toDouble(),
            height: ad!.size.height.toDouble(),
            child: AdWidget(ad: ad!),
          ),
        );
      },
    );
  }

  Future<void> _load(int width) async {
    ad?.dispose();
    loaded = false;
    final unitId = AdService.unitId(AdFormat.banner);
    if (unitId == null || !await AdService.canRequestAds()) return;
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (size == null || !mounted) return;
    await AdEventRecorder.record('ad_request', widget.placement, 'banner');
    final banner = BannerAd(
      size: size,
      adUnitId: unitId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (value) {
          AdEventRecorder.record('ad_loaded', widget.placement, 'banner');
          if (mounted) setState(() => loaded = true);
        },
        onAdImpression: (value) =>
            AdEventRecorder.record('ad_impression', widget.placement, 'banner'),
        onAdClicked: (value) =>
            AdEventRecorder.record('ad_clicked', widget.placement, 'banner'),
        onPaidEvent: (value, micros, precision, currency) =>
            AdEventRecorder.recordRevenue(
              placement: widget.placement,
              format: 'banner',
              micros: micros,
              currency: currency,
            ),
        onAdFailedToLoad: (value, error) {
          AdEventRecorder.record('ad_failed', widget.placement, 'banner');
          value.dispose();
        },
      ),
    );
    ad = banner;
    await banner.load();
  }
}
