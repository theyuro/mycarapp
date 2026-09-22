import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';

import '../screens/account_screen.dart';
import '../services/recommendation_banner_service.dart';
import '../theme/app_colors.dart';

/// Banner de recomendação (Seção 5 do guia de planejamento): convite
/// discreto e dispensável para avaliar o app ou indicar um amigo, exibido
/// no fluxo de conteúdo — nunca como pop-up modal, nunca para usuário novo
/// nem no meio de uma tarefa. Todas as regras de frequência e dispensa
/// ficam em [RecommendationBannerService]; este widget só decide **qual**
/// tipo mostrar e reage ao toque.
class RecommendationBanner extends StatefulWidget {
  const RecommendationBanner({super.key});

  @override
  State<RecommendationBanner> createState() => _RecommendationBannerState();
}

class _RecommendationBannerState extends State<RecommendationBanner> {
  RecommendationBannerType? _type;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    final service = RecommendationBannerService.instance;
    await service.initialize();

    RecommendationBannerType? chosen;
    if (await service.canShow(RecommendationBannerType.rating)) {
      chosen = RecommendationBannerType.rating;
    } else if (await service.canShow(RecommendationBannerType.referral)) {
      chosen = RecommendationBannerType.referral;
    }

    if (chosen != null) service.markShown(chosen);
    if (mounted) setState(() => _type = chosen);
  }

  Future<void> _primaryAction() async {
    final type = _type;
    if (type == null || _busy) return;
    setState(() => _busy = true);
    try {
      switch (type) {
        case RecommendationBannerType.rating:
          try {
            final review = InAppReview.instance;
            if (await review.isAvailable()) {
              await review.requestReview();
            } else {
              await review.openStoreListing();
            }
          } on Object {
            // API da loja indisponível: não bloquear o usuário por isso.
          }
        case RecommendationBannerType.referral:
          if (mounted) {
            await Navigator.of(context).push<void>(
              MaterialPageRoute<void>(builder: (_) => const AccountScreen()),
            );
          }
      }
      await RecommendationBannerService.instance.hidePermanently(type);
    } finally {
      if (mounted) setState(() => _type = null);
    }
  }

  Future<void> _dismiss() async {
    final type = _type;
    if (type == null) return;
    await RecommendationBannerService.instance.dismiss(type);
    if (mounted) setState(() => _type = null);
  }

  @override
  Widget build(BuildContext context) {
    final type = _type;
    if (type == null) return const SizedBox.shrink();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Container(
        key: ValueKey(type),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gold.withValues(alpha: .4)),
        ),
        child: Row(
          children: [
            Icon(_iconFor(type), color: AppColors.gold, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _textFor(type),
                style: const TextStyle(color: Colors.white, fontSize: 12.5),
              ),
            ),
            TextButton(
              onPressed: _busy ? null : _primaryAction,
              style: TextButton.styleFrom(foregroundColor: AppColors.gold),
              child: Text(
                _ctaFor(type),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              tooltip: 'Dispensar',
              onPressed: _busy ? null : _dismiss,
              icon: const Icon(
                Icons.close_rounded,
                color: Colors.white54,
                size: 18,
              ),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}

IconData _iconFor(RecommendationBannerType type) => switch (type) {
  RecommendationBannerType.rating => Icons.star_outline_rounded,
  RecommendationBannerType.referral => Icons.favorite_outline_rounded,
};

String _textFor(RecommendationBannerType type) => switch (type) {
  RecommendationBannerType.rating =>
    'Gostando de acompanhar seus gastos? Conta pra gente na Play Store.',
  RecommendationBannerType.referral =>
    'Curtiu o MyCarApp? Indique um amigo e ganhe desconto na assinatura.',
};

String _ctaFor(RecommendationBannerType type) => switch (type) {
  RecommendationBannerType.rating => 'AVALIAR',
  RecommendationBannerType.referral => 'INDICAR',
};
