import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../services/access_service.dart';
import '../services/ads_config.dart';
import '../services/ads_service.dart';

/// Se a oferta "assista a um vídeo e fique sem anúncios em tela cheia" pode
/// aparecer: só para quem vê anúncios e com o Rewarded ligado no Remote
/// Config.
bool get rewardedOfferAvailable =>
    AccessService.instance.showsAds &&
    AdsConfig.instance.rewardedEnabled &&
    AdsService.instance.canRequestAds;

/// Horas restantes do período sem anúncios em tela cheia, arredondadas para
/// cima (ex.: 2h10 restantes aparecem como 3h).
int adFreeRemainingHours() {
  final remaining = AdsService.instance.adFreeRemaining;
  if (remaining == null) return 0;
  return (remaining.inMinutes / 60).ceil().clamp(1, 999);
}

/// Exibe o vídeo premiado e avisa o resultado numa SnackBar. A recompensa
/// só vale se o usuário assistir até o fim (decidido pelo AdsService).
Future<void> watchRewardedForAdFree(BuildContext context) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  void show(String text) {
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  final result = await AdsService.instance.showRewarded();
  switch (result) {
    case RewardedResult.earned:
      show(tr.rewardedEarned(adFreeRemainingHours()));
    case RewardedResult.notEarned:
      show(tr.rewardedNotEarned);
    case RewardedResult.unavailable:
      // O AdsService já disparou um novo carregamento.
      show(tr.rewardedUnavailable);
  }
}
