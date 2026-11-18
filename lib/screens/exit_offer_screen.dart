import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../services/access_service.dart';
import '../services/analytics_service.dart';
import '../theme/app_colors.dart';
import 'lifetime_purchase_screen.dart';

/// Oferta de saída (exitlag, desconto no 1º ano do anual), aberta pelo
/// questionário quando o usuário respondeu "Muito caro" e o servidor concedeu
/// a janela. Todos os valores vêm do ProductDetails da Play; o contador usa o
/// [expiresAt] devolvido pelo servidor, nunca um prazo contado no aparelho.
class ExitOfferScreen extends StatefulWidget {
  const ExitOfferScreen({super.key, required this.expiresAt});

  final DateTime expiresAt;

  @override
  State<ExitOfferScreen> createState() => _ExitOfferScreenState();
}

class _ExitOfferScreenState extends State<ExitOfferScreen> {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  // Evita registrar recusa/expiração depois de aceitar, assinar ou já ter
  // registrado outro desfecho.
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.expiresAt.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    // Já expirada ao abrir: fecha depois do primeiro quadro (não dá para
    // fechar a rota dentro do initState).
    if (_remaining <= Duration.zero) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _tick());
    }
    AccessService.instance.addListener(_onAccessChanged);
    final option = AccessService.instance.exitOfferOption;
    AnalyticsService.event('exit_offer_view', {
      'offer_tag': AccessService.exitOfferTag,
      'plan': option?.basePlanId,
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    AccessService.instance.removeListener(_onAccessChanged);
    super.dispose();
  }

  void _tick() {
    final remaining = widget.expiresAt.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      // Com a tela da Play aberta, espera a compra terminar antes de fechar.
      if (AccessService.instance.purchasePending) return;
      _expire();
      return;
    }
    if (mounted) setState(() => _remaining = remaining);
  }

  void _expire() {
    if (_closed) return;
    _closed = true;
    _timer?.cancel();
    AnalyticsService.event('exit_offer_expired', {
      'offer_tag': AccessService.exitOfferTag,
    });
    unawaited(AccessService.instance.refreshSubscriptionOffers());
    if (mounted) Navigator.of(context).pop();
  }

  void _onAccessChanged() {
    if (!mounted) return;
    // Assinou: a oferta cumpriu o papel; fecha sem registrar recusa.
    if (AccessService.instance.subscriptionActive && !_closed) {
      _closed = true;
      _timer?.cancel();
      Navigator.of(context).pop();
      return;
    }
    setState(() {});
  }

  void _decline(String source) {
    if (!_closed) {
      _closed = true;
      AnalyticsService.event('exit_offer_decline', {
        'offer_tag': AccessService.exitOfferTag,
        'source': source,
      });
    }
    Navigator.of(context).pop();
  }

  void _accept(SubscriptionOption option) {
    final access = AccessService.instance;
    AnalyticsService.event('exit_offer_accept', {
      'offer_tag': AccessService.exitOfferTag,
      'plan': option.basePlanId,
    });
    access.selectSubscription(option);
    access.buySubscription();
  }

  String get _countdown {
    final left = _remaining.isNegative ? Duration.zero : _remaining;
    final minutes = left.inMinutes.toString().padLeft(2, '0');
    final seconds = (left.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final access = AccessService.instance;
    final option = access.exitOfferOption;
    return PopScope(
      // Voltar do sistema também conta como recusa.
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && !_closed) {
          _closed = true;
          AnalyticsService.event('exit_offer_decline', {
            'offer_tag': AccessService.exitOfferTag,
            'source': 'back',
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.navy,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 24),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => _decline('close'),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: option == null ? _unavailable() : _offer(access, option),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A opção sumiu da Play (janela encerrada no servidor ou loja sem a
  /// oferta): só o link para sair.
  Widget _unavailable() => Column(
    children: [
      const SizedBox(height: 40),
      Text(
        tr.subscriptionPlansAvailable,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white70),
      ),
      const SizedBox(height: 16),
      TextButton(
        onPressed: () => _decline('unavailable'),
        child: Text(
          tr.exitOfferNoThanks,
          style: const TextStyle(color: Colors.white70),
        ),
      ),
    ],
  );

  Widget _offer(AccessService access, SubscriptionOption option) {
    final currency = option.currencyCode;
    final offerPrice = formatStorePrice(currency, option.priceMicros / 1e6);
    final renewalPrice = formatStorePrice(currency, option.renewalMicros / 1e6);
    final perMonth = formatStorePrice(currency, option.priceMicros / 12 / 1e6);
    final percent = option.discountPercent;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            tr.exitOfferBadge,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: .6,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          percent == null
              ? tr.exitOfferTitleGeneric
              : tr.exitOfferTitle(percent),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            height: 1.25,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          tr.exitOfferSubtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
                tr.exitOfferExpiresIn(_countdown),
                style: const TextStyle(
                  color: AppColors.goldLight,
                  fontWeight: FontWeight.w800,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr.exitOfferPlan,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tr.exitOfferFrom(renewalPrice),
                style: const TextStyle(
                  color: AppColors.muted,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(
                      offerPrice,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    tr.exitOfferFirstYear,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
              Text(
                tr.exitOfferPerMonth(perMonth),
                style: const TextStyle(
                  color: AppColors.blue,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Divider(height: 26),
              for (final benefit in [
                tr.benefitNoAds,
                tr.benefitVehicles,
                tr.benefitMaintenanceNoVideo,
                tr.benefitBackup,
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.blue,
                        size: 19,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          benefit,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton(
            onPressed: access.purchasePending ? null : () => _accept(option),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.navy,
            ),
            child: Text(
              access.purchasePending
                  ? tr.premiumWaitingPlay
                  : tr.exitOfferButton(offerPrice),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          tr.exitOfferRenewal(renewalPrice),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white60, fontSize: 11.5),
        ),
        if (access.storeMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            access.storeMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
        const SizedBox(height: 6),
        TextButton(
          onPressed: () => _decline('no_thanks'),
          child: Text(
            tr.exitOfferNoThanks,
            style: const TextStyle(
              color: Colors.white70,
              decoration: TextDecoration.underline,
              decorationColor: Colors.white70,
            ),
          ),
        ),
      ],
    );
  }
}
