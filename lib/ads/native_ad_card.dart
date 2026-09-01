import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:profit_track/ads/ad_event_recorder.dart';
import 'package:profit_track/ads/ad_service.dart';
import 'package:profit_track/app/theme.dart';

class NativeAdCard extends StatefulWidget {
  const NativeAdCard({required this.placement, super.key});

  final String placement;

  @override
  State<NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends State<NativeAdCard> {
  NativeAd? ad;
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded || ad == null) return const SizedBox.shrink();
    return Container(
      height: 118,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(10, 5, 10, 0),
            child: Text(
              'Sponsored',
              style: TextStyle(fontSize: 9, color: AppColors.slate),
            ),
          ),
          Expanded(child: AdWidget(ad: ad!)),
        ],
      ),
    );
  }

  Future<void> _load() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    final unitId = AdService.unitId(AdFormat.native);
    if (unitId == null || !await AdService.canRequestAds()) return;
    await AdEventRecorder.record('ad_request', widget.placement, 'native');
    final native = NativeAd(
      adUnitId: unitId,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: Colors.white,
        cornerRadius: 12,
      ),
      listener: NativeAdListener(
        onAdLoaded: (value) {
          AdEventRecorder.record('ad_loaded', widget.placement, 'native');
          if (mounted) setState(() => loaded = true);
        },
        onAdImpression: (value) =>
            AdEventRecorder.record('ad_impression', widget.placement, 'native'),
        onAdClicked: (value) =>
            AdEventRecorder.record('ad_clicked', widget.placement, 'native'),
        onPaidEvent: (value, micros, precision, currency) =>
            AdEventRecorder.recordRevenue(
              placement: widget.placement,
              format: 'native',
              micros: micros,
              currency: currency,
            ),
        onAdFailedToLoad: (value, error) {
          AdEventRecorder.record('ad_failed', widget.placement, 'native');
          value.dispose();
        },
      ),
    );
    ad = native;
    await native.load();
  }
}
