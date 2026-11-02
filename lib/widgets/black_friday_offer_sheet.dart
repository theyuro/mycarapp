import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../screens/lifetime_purchase_screen.dart';
import '../services/access_service.dart';
import '../services/analytics_service.dart';
import '../services/black_friday_offer_service.dart';
import '../theme/app_colors.dart';
import 'responsive_sheet.dart';

bool _showing = false;

/// Mostra o convite de Black Friday (60% no 1º ano do anual) quando a
/// campanha está ativa e a fase atual ainda não esgotou seu limite de
/// exibições (ver [BlackFridayOfferService]). Some para quem já é Premium.
///
/// Chamado antes de [showPremiumAfterAdSheet] no fechamento do intersticial;
/// devolve `true` quando mostrou o convite, para o chamador não empilhar o
/// convite comum de Premium em seguida.
Future<bool> showBlackFridayOfferSheet(BuildContext context) async {
  if (_showing || !AccessService.instance.showsAds) return false;
  if (AccessService.freeModeEnabled) return false;
  final access = AccessService.instance;
  final option = access.blackFridayOption;
  if (option == null) return false;
  if (!await BlackFridayOfferService.instance.canShow()) return false;
  _showing = true;
  try {
    if (!context.mounted) return false;
    await BlackFridayOfferService.instance.markShown();
    AnalyticsService.event('black_friday_offer_view', {
      'phase': BlackFridayOfferService.instance.currentPhase?.name,
    });
    if (!context.mounted) return false;
    final accepted = await showResponsiveSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _BlackFridayOfferSheet(),
    );
    if (accepted == true && context.mounted) {
      access.selectSubscription(option);
      await openPremium(context, PremiumFeature.noAds, 'black_friday_sheet');
    } else {
      AnalyticsService.event('black_friday_offer_decline');
    }
    return true;
  } finally {
    _showing = false;
  }
}

class _BlackFridayOfferSheet extends StatefulWidget {
  const _BlackFridayOfferSheet();

  @override
  State<_BlackFridayOfferSheet> createState() =>
      _BlackFridayOfferSheetState();
}

class _BlackFridayOfferSheetState extends State<_BlackFridayOfferSheet> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _remaining = BlackFridayOfferService.instance.timeUntilEnd;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = BlackFridayOfferService.instance.timeUntilEnd;
      if (mounted) setState(() => _remaining = remaining);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _countdown {
    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    if (days > 0) return '${days}d ${hours}h';
    if (hours > 0) return '${hours}h ${minutes}min';
    final seconds = _remaining.inSeconds % 60;
    return '${minutes}min ${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final option = AccessService.instance.blackFridayOption;
    final percent = option?.discountPercent ?? 60;
    final lastChance =
        BlackFridayOfferService.instance.currentPhase == BlackFridayPhase.last;
    return Container(
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
        child: SingleChildScrollView(
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tr.blackFridayBadge,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .6,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                tr.blackFridayTitle(percent),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  height: 1.25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                lastChance
                    ? tr.blackFridayLastChanceSubtitle
                    : tr.blackFridaySubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.navyLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      color: AppColors.goldLight,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tr.blackFridayEndsIn(_countdown),
                      style: const TextStyle(
                        color: AppColors.goldLight,
                        fontWeight: FontWeight.w800,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              for (final benefit in [
                tr.benefitNoAds,
                tr.benefitVehicles,
                tr.benefitMaintenanceNoVideo,
                tr.benefitBackup,
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.gold,
                        size: 19,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          benefit,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.navy,
                  ),
                  child: Text(
                    tr.blackFridayButton(percent),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  tr.blackFridayNotNow,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
