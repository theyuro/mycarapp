import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../screens/lifetime_purchase_screen.dart';
import '../services/access_service.dart';
import '../services/ads_service.dart';
import '../services/app_review_service.dart';
import '../services/recommendation_banner_service.dart';
import '../theme/app_colors.dart';
import '../l10n/l10n.dart';

const leilaoFacilitadoUrl = 'https://leilaofacilitado.com.br';

/// Peças próprias exibidas no lugar do banner do AdMob.
enum HouseAdType { auction, premium, rating }

/// Anúncio próprio no rodapé, para quando o AdMob não entrega banner (sem
/// internet, sem consentimento ou sem anúncio disponível). Não precisa de
/// rede para aparecer e alterna entre o Leilão Facilitado, o Premium e o
/// pedido de avaliação.
class HouseAdBanner extends StatefulWidget {
  const HouseAdBanner({super.key, required this.placement});

  final BannerPlacement placement;

  @override
  State<HouseAdBanner> createState() => _HouseAdBannerState();
}

class _HouseAdBannerState extends State<HouseAdBanner> {
  // Compartilhado entre as telas: cada banner criado mostra a próxima peça,
  // em vez de todas as telas repetirem a mesma.
  static int _next = DateTime.now().day;

  HouseAdType? _type;

  @override
  void initState() {
    super.initState();
    unawaited(_choose());
  }

  Future<void> _choose() async {
    final recommendations = RecommendationBannerService.instance;
    await recommendations.initialize();
    final options = [
      HouseAdType.auction,
      if (!AccessService.instance.premiumUnlocked) HouseAdType.premium,
      if (!recommendations.isHiddenForever(RecommendationBannerType.rating))
        HouseAdType.rating,
    ];
    final type = options[_next++ % options.length];
    if (!mounted) return;
    setState(() => _type = type);
    _log('house_ad_impression', type);
  }

  void _log(String event, HouseAdType type) {
    try {
      unawaited(
        FirebaseAnalytics.instance.logEvent(
          name: event,
          parameters: {'type': type.name, 'placement': widget.placement.name},
        ),
      );
    } on Object {
      // Firebase indisponível.
    }
  }

  Future<void> _open() async {
    final type = _type;
    if (type == null) return;
    _log('house_ad_tap', type);
    switch (type) {
      case HouseAdType.auction:
        final uri = Uri.parse(leilaoFacilitadoUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      case HouseAdType.premium:
        await openPremium(context, PremiumFeature.noAds, 'house_ad');
      case HouseAdType.rating:
        // Botão: abre direto a página da Play (ver AppReviewService).
        await AppReviewService.instance.openStoreListing();
        await RecommendationBannerService.instance.hidePermanently(
          RecommendationBannerType.rating,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = _type;
    if (type == null) return const SizedBox.shrink();
    return HouseAdTile(type: type, onTap: _open);
  }
}

/// Visual de uma peça do [HouseAdBanner], sem regras nem efeitos.
class HouseAdTile extends StatelessWidget {
  const HouseAdTile({super.key, required this.type, required this.onTap});

  final HouseAdType type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, text, cta) = switch (type) {
      HouseAdType.auction => (
        Icons.gavel_rounded,
        tr.houseAdAuctionText,
        tr.houseAdAuctionCta,
      ),
      HouseAdType.premium => (
        Icons.workspace_premium_rounded,
        tr.upsellNoAdsText,
        tr.upsellSubscribe,
      ),
      HouseAdType.rating => (
        Icons.star_outline_rounded,
        tr.recoRatingText,
        tr.recoRate,
      ),
    };
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      // Mesma margem do banner do AdMob, para a troca não mexer no layout.
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Material(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: SizedBox(
              height: 50,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(icon, color: AppColors.gold, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      cta,
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
