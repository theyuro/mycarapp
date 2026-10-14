import 'package:flutter/material.dart';

import '../screens/lifetime_purchase_screen.dart';
import '../services/access_service.dart';
import '../services/ads_config.dart';
import '../services/ads_service.dart';
import '../theme/app_colors.dart';
import '../l10n/l10n.dart';
import 'rewarded_ad_free.dart';

bool _showing = false;

/// O que o usuário escolheu no convite.
enum _AfterAdChoice { subscribe, rewarded, notNow }

/// Convite para assinar o Premium, mostrado logo depois que o usuário fecha
/// um anúncio intersticial. Some para quem já é Premium.
///
/// Aparece só de vez em quando: precisa estar ligado no Remote Config e ter
/// passado o intervalo mínimo desde o último convite. Nos demais
/// intersticiais o usuário volta direto para o app.
Future<void> showPremiumAfterAdSheet(BuildContext context) async {
  if (_showing || !AccessService.instance.showsAds) return;
  if (AccessService.freeModeEnabled) return;
  _showing = true;
  try {
    if (!await AdsService.instance.premiumAfterAdDue()) return;
    if (!context.mounted) return;
    await AdsService.instance.markPremiumAfterAdShown();
    if (!context.mounted) return;
    final choice = await showModalBottomSheet<_AfterAdChoice>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PremiumAfterAdSheet(),
    );
    if (!context.mounted) return;
    if (choice == _AfterAdChoice.subscribe) {
      await openPremium(context);
    } else if (choice == _AfterAdChoice.rewarded) {
      await watchRewardedForAdFree(context);
    }
  } finally {
    _showing = false;
  }
}

class _PremiumAfterAdSheet extends StatelessWidget {
  const _PremiumAfterAdSheet();

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.navy, AppColors.blue],
      ),
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            const Icon(
              Icons.workspace_premium_rounded,
              color: AppColors.gold,
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              tr.afterAdTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tr.afterAdSubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            for (final feature in PremiumFeature.values)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Icon(feature.icon, color: AppColors.gold, size: 21),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        feature.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Text(
              tr.premiumPrices,
              style: const TextStyle(
                color: AppColors.goldLight,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () =>
                    Navigator.of(context).pop(_AfterAdChoice.subscribe),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.navy,
                ),
                child: Text(tr.afterAdSubscribe),
              ),
            ),
            // Alternativa gratuita: um vídeo premiado dá algumas horas sem
            // anúncios em tela cheia (os banners continuam).
            if (rewardedOfferAvailable) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pop(_AfterAdChoice.rewarded),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.ondemand_video_rounded, size: 20),
                  label: Text(
                    tr.afterAdRewarded(AdsConfig.instance.rewardedAdFreeHours),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
            TextButton(
              onPressed: () => Navigator.of(context).pop(_AfterAdChoice.notNow),
              child: Text(
                tr.notNow,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
