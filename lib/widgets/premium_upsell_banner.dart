import 'package:flutter/material.dart';

import '../screens/lifetime_purchase_screen.dart';
import '../services/access_service.dart';
import '../services/premium_upsell_service.dart';
import '../theme/app_colors.dart';
import '../l10n/l10n.dart';

/// Banner convidando o usuário gratuito a assinar o Premium. Fica no fluxo
/// do conteúdo (nunca modal), pode ser dispensado e some para assinantes.
/// A mensagem depende da tela; na tela inicial ela alterna por dia entre os
/// benefícios do Premium.
class PremiumUpsellBanner extends StatefulWidget {
  const PremiumUpsellBanner({
    super.key,
    required this.placement,
    this.margin = const EdgeInsets.only(bottom: 14),
  });

  final UpsellPlacement placement;
  final EdgeInsetsGeometry margin;

  @override
  State<PremiumUpsellBanner> createState() => _PremiumUpsellBannerState();
}

class _PremiumUpsellBannerState extends State<PremiumUpsellBanner> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    final show = await PremiumUpsellService.instance.canShow(widget.placement);
    if (mounted) setState(() => _visible = show);
  }

  Future<void> _dismiss() async {
    setState(() => _visible = false);
    await PremiumUpsellService.instance.dismiss(widget.placement);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: AccessService.instance,
    builder: (context, _) {
      if (!_visible || AccessService.instance.premiumUnlocked) {
        return const SizedBox.shrink();
      }
      final message = _messageFor(widget.placement);
      return Container(
        margin: widget.margin,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.navy, AppColors.blue],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gold.withValues(alpha: .4)),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => openPremium(context, message.feature),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
              child: Row(
                children: [
                  Icon(message.feature.icon, color: AppColors.gold, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          message.text,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    tr.upsellSubscribe,
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    tooltip: tr.dismiss,
                    onPressed: _dismiss,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white54,
                      size: 18,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _UpsellMessage {
  const _UpsellMessage(this.feature, this.title, this.text);
  final PremiumFeature feature;
  final String title;
  final String text;
}

List<_UpsellMessage> get _homeRotation => [
  _UpsellMessage(PremiumFeature.noAds, tr.upsellNoAdsTitle, tr.upsellNoAdsText),
  _UpsellMessage(
    PremiumFeature.backup,
    tr.upsellBackupTitle,
    tr.upsellBackupText,
  ),
  _UpsellMessage(
    PremiumFeature.reports,
    tr.upsellReportsTitle,
    tr.upsellReportsText,
  ),
  _UpsellMessage(
    PremiumFeature.updates,
    tr.upsellUpdatesTitle,
    tr.upsellUpdatesText,
  ),
];

_UpsellMessage _messageFor(UpsellPlacement placement) => switch (placement) {
  UpsellPlacement.home =>
    _homeRotation[DateTime.now().difference(DateTime(2026)).inDays %
        _homeRotation.length],
  UpsellPlacement.vehicles => _UpsellMessage(
    PremiumFeature.backup,
    tr.upsellVehiclesTitle,
    tr.upsellVehiclesText,
  ),
  UpsellPlacement.establishments => _UpsellMessage(
    PremiumFeature.noAds,
    tr.upsellAdsTitle,
    tr.upsellAdsText,
  ),
  UpsellPlacement.fuelingHistory => _UpsellMessage(
    PremiumFeature.backup,
    tr.upsellFuelingTitle,
    tr.upsellFuelingText,
  ),
  UpsellPlacement.maintenance => _UpsellMessage(
    PremiumFeature.backup,
    tr.upsellMaintenanceTitle,
    tr.upsellMaintenanceText,
  ),
  UpsellPlacement.expenses => _UpsellMessage(
    PremiumFeature.reports,
    tr.upsellExpensesTitle,
    tr.upsellExpensesText,
  ),
};
