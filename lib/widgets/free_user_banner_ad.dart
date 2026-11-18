import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/access_service.dart';
import '../services/ads_service.dart';
import 'house_ad_banner.dart';

// As telas só precisam deste import para escolher a posição do banner.
export '../services/ads_service.dart' show BannerPlacement;

/// Banner adaptativo ancorado no rodapé, para quem vê anúncios. Cada tela
/// informa a sua [placement], que define o bloco de anúncio no AdMob.
///
/// O período sem anúncios do vídeo premiado não esconde o banner: ele vale
/// só para anúncios em tela cheia.
///
/// Sem banner do AdMob (offline, sem consentimento ou sem anúncio), o espaço
/// mostra o [HouseAdBanner].
class FreeUserBannerAd extends StatelessWidget {
  const FreeUserBannerAd({super.key, required this.placement});

  final BannerPlacement placement;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: AdsService.instance,
    builder: (context, _) => AnimatedBuilder(
      animation: AccessService.instance,
      builder: (context, _) {
        if (!AccessService.instance.showsAds) return const SizedBox.shrink();
        if (AdsService.instance.adsUnavailable) {
          return HouseAdBanner(placement: placement);
        }
        if (!AdsService.instance.canRequestAds) return const SizedBox.shrink();
        return _LoadedBannerAd(placement: placement);
      },
    ),
  );
}

class _LoadedBannerAd extends StatefulWidget {
  const _LoadedBannerAd({required this.placement});

  final BannerPlacement placement;

  @override
  State<_LoadedBannerAd> createState() => _LoadedBannerAdState();
}

class _LoadedBannerAdState extends State<_LoadedBannerAd> {
  // Após uma falha, tenta de novo depois deste intervalo em vez de desistir
  // até a tela ser recriada.
  static const _retryDelay = Duration(seconds: 60);

  BannerAd? _banner;
  // O último pedido falhou (sem internet ou sem anúncio): mostra o anúncio
  // próprio até um banner carregar.
  bool _failed = false;
  Timer? _retry;
  // O tamanho adaptativo depende da largura vinda do MediaQuery, que só está
  // disponível em didChangeDependencies; o pedido é feito uma vez só.
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) return;
    _requested = true;
    unawaited(_load());
  }

  /// Largura útil da tela em dp (sem as áreas laterais do recorte), truncada,
  /// como pede o banner adaptativo.
  int _adWidth() {
    final media = MediaQuery.of(context);
    return (media.size.width - media.padding.horizontal).truncate();
  }

  Future<void> _load() async {
    final width = _adWidth();
    // Na 9.x o SDK sugere getLargeAnchoredAdaptiveBannerAdSize (banner mais
    // alto); mantido o ancorado padrão, que ocupa menos espaço no rodapé.
    final adaptive =
        // ignore: deprecated_member_use
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (!mounted) return;
    final banner = BannerAd(
      // Sem tamanho adaptativo para este aparelho, volta ao banner padrão.
      size: adaptive ?? AdSize.banner,
      adUnitId: AdsService.instance.bannerAdUnitId(widget.placement),
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          final previous = _banner;
          setState(() {
            _banner = ad as BannerAd;
            _failed = false;
          });
          previous?.dispose();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          AdsService.instance.reportAdIssue(
            'banner_load',
            '${widget.placement.name} '
                'code=${error.code} domain=${error.domain} ${error.message}',
          );
          if (!mounted) return;
          if (_banner == null) setState(() => _failed = true);
          _retry?.cancel();
          _retry = Timer(_retryDelay, () {
            if (mounted) unawaited(_load());
          });
        },
      ),
    );
    unawaited(banner.load());
  }

  @override
  void dispose() {
    _retry?.cancel();
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banner = _banner;
    if (banner == null) {
      return _failed
          ? HouseAdBanner(placement: widget.placement)
          : const SizedBox.shrink();
    }
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      // Margem vertical para afastar o anúncio de botões vizinhos (barra
      // inferior, FAB) e evitar cliques acidentais.
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
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
      ),
    );
  }
}
