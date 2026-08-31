import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:profit_track/ads/ad_service.dart';

class ProfitTrackAdBanner extends StatefulWidget {
  const ProfitTrackAdBanner({super.key});

  @override
  State<ProfitTrackAdBanner> createState() => _ProfitTrackAdBannerState();
}

class _ProfitTrackAdBannerState extends State<ProfitTrackAdBanner> {
  BannerAd? ad;
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    final unitId = AdService.bannerUnitId;
    if (unitId == null || !await ConsentInformation.instance.canRequestAds()) {
      return;
    }
    final banner = BannerAd(
      size: AdSize.banner,
      adUnitId: unitId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (value) {
          if (mounted) setState(() => loaded = true);
        },
        onAdFailedToLoad: (value, error) {
          value.dispose();
        },
      ),
    );
    ad = banner;
    await banner.load();
  }

  @override
  void dispose() {
    ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded || ad == null) return const SizedBox.shrink();
    return Center(
      child: SizedBox(
        width: ad!.size.width.toDouble(),
        height: ad!.size.height.toDouble(),
        child: AdWidget(ad: ad!),
      ),
    );
  }
}
