import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/access_service.dart';
import '../services/ads_service.dart';

class FreeUserBannerAd extends StatelessWidget {
  const FreeUserBannerAd({super.key});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: AdsService.instance,
    builder: (context, _) => AnimatedBuilder(
      animation: AccessService.instance,
      builder: (context, _) {
        if (AccessService.instance.hasAccess ||
            !AdsService.instance.canRequestAds) {
          return const SizedBox.shrink();
        }
        return const _LoadedBannerAd();
      },
    ),
  );
}

class _LoadedBannerAd extends StatefulWidget {
  const _LoadedBannerAd();

  @override
  State<_LoadedBannerAd> createState() => _LoadedBannerAdState();
}

class _LoadedBannerAdState extends State<_LoadedBannerAd> {
  BannerAd? _banner;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final banner = BannerAd(
      size: AdSize.banner,
      adUnitId: AdsService.instance.bannerAdUnitId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() => _banner = ad as BannerAd);
        },
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    );
    banner.load();
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banner = _banner;
    if (banner == null) return const SizedBox.shrink();
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        top: false,
        bottom: false,
        child: SizedBox(
          width: double.infinity,
          height: banner.size.height.toDouble(),
          child: Center(
            child: SizedBox(
              width: banner.size.width.toDouble(),
              height: banner.size.height.toDouble(),
              child: AdWidget(ad: banner),
            ),
          ),
        ),
      ),
    );
  }
}
