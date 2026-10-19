import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/access_service.dart';
import '../services/analytics_service.dart';
import '../theme/app_colors.dart';
import '../widgets/subscription_survey_sheet.dart';
import 'login_screen.dart';
import '../l10n/l10n.dart';

/// Recurso Premium que levou o usuário à tela de assinatura; define o
/// título exibido no topo.
///
/// Reflete as regras do novo plano gratuito × Premium: cada valor cobre um
/// grupo de recursos (manutenção já inclui despesas e alertas) liberado por
/// assinatura, e não mais um teste local por tempo.
enum PremiumFeature {
  noAds(Icons.block_rounded),
  vehicles(Icons.directions_car_rounded),
  fuelings(Icons.local_gas_station_rounded),
  maintenance(Icons.build_rounded),
  receiptScan(Icons.document_scanner_rounded),
  stationRanking(Icons.leaderboard_rounded),
  periodReports(Icons.bar_chart_rounded),
  export(Icons.file_download_rounded),
  pdf(Icons.picture_as_pdf_rounded),
  backup(Icons.cloud_upload_outlined),
  sync(Icons.sync_rounded);

  const PremiumFeature(this.icon);
  final IconData icon;

  String get title => switch (this) {
    noAds => tr.featureNoAdsTitle,
    vehicles => tr.featureVehiclesTitle,
    fuelings => tr.featureFuelingsTitle,
    maintenance => tr.featureMaintenanceTitle,
    receiptScan => tr.featureReceiptScanTitle,
    stationRanking => tr.featureStationRankingTitle,
    periodReports => tr.featurePeriodReportsTitle,
    export => tr.featureExportTitle,
    pdf => tr.featurePdfTitle,
    backup => tr.featureBackupTitle,
    sync => tr.featureSyncTitle,
  };

  String get description => switch (this) {
    noAds => tr.featureNoAdsText,
    vehicles => tr.featureVehiclesText,
    fuelings => tr.featureFuelingsText,
    maintenance => tr.featureMaintenanceText,
    receiptScan => tr.featureReceiptScanText,
    stationRanking => tr.featureStationRankingText,
    periodReports => tr.featurePeriodReportsText,
    export => tr.featureExportText,
    pdf => tr.featurePdfText,
    backup => tr.featureBackupText,
    sync => tr.featureSyncText,
  };
}

/// Abre a tela de assinatura. [source] identifica de onde a abertura partiu
/// (para o evento `open_subscription` do Analytics) e é repassado à
/// [SubscriptionScreen], sem alterar o evento de Analytics já existente nela.
///
/// Parâmetros posicionais opcionais (e não nomeados) para manter as chamadas
/// existentes `openPremium(context, feature, 'origem')`.
Future<void> openPremium(
  BuildContext context, [
  PremiumFeature? feature,
  String source = 'unknown',
]) {
  // Abertura da tela de assinatura a partir de um recurso Premium.
  AnalyticsService.tap(
    'open_subscription',
    screen: source,
    params: {'feature': feature?.name},
  );
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => SubscriptionScreen(feature: feature, source: source),
      settings: const RouteSettings(name: 'subscription'),
    ),
  );
}

/// Opção de um período (anual ou mensal): a promocional (oferta vigente)
/// quando houver uma disponível, senão a simples. `null` quando a loja não
/// tem nenhum plano desse período carregado.
SubscriptionOption? _bestOption(
  List<SubscriptionOption> options, {
  required bool annual,
}) {
  SubscriptionOption? plain;
  SubscriptionOption? any;
  for (final option in options) {
    if (option.isAnnual != annual) continue;
    any ??= option;
    if (!option.isPromotional) {
      plain = option;
      break;
    }
  }
  return plain ?? any;
}

/// Plano anual a exibir: o já selecionado, se for anual (mantém o preço
/// coerente com o que será cobrado), senão o melhor plano anual disponível.
SubscriptionOption? _annualOption(AccessService access) {
  final selected = access.selectedSubscription;
  if (selected != null && selected.isAnnual) return selected;
  return _bestOption(access.subscriptionOptions, annual: true);
}

/// Plano mensal a exibir; mesma regra de [_annualOption].
SubscriptionOption? _monthlyOption(AccessService access) {
  final selected = access.selectedSubscription;
  if (selected != null && !selected.isAnnual) return selected;
  return _bestOption(access.subscriptionOptions, annual: false);
}

/// Preço formatado na moeda devolvida pela Google Play (não a do aparelho).
String _formatPrice(String currencyCode, double amount) =>
    NumberFormat.currency(
      locale: tr.localeName == 'pt' ? 'pt_BR' : 'en_US',
      name: currencyCode,
    ).format(amount);

/// Versão pública de [_formatPrice], usada pela oferta de saída
/// (exit_offer_screen.dart) para formatar os valores do ProductDetails.
String formatStorePrice(String currencyCode, double amount) =>
    _formatPrice(currencyCode, amount);

/// Percentual economizado assinando o anual em vez do mensal, com base nos
/// preços de renovação (sem considerar ofertas temporárias). `null` quando
/// não há economia ou falta algum dos dois planos.
int? _savePercent(SubscriptionOption? annual, SubscriptionOption? monthly) {
  if (annual == null || monthly == null || monthly.renewalMicros <= 0) {
    return null;
  }
  final ratio = annual.renewalMicros / (12 * monthly.renewalMicros);
  final percent = ((1 - ratio) * 100).round();
  return percent > 0 ? percent : null;
}

/// Preço mensal equivalente do plano anual, pronto para um texto como
/// "a partir de R$ X/mês" (ver [AppLocalizations.afterAdPriceFrom]). `null`
/// quando a loja ainda não tem nenhum plano anual carregado.
String? monthlyEquivalentPrice(AccessService access) {
  final annual = _bestOption(access.subscriptionOptions, annual: true);
  if (annual == null) return null;
  return _formatPrice(annual.currencyCode, annual.renewalMicros / 12 / 1e6);
}

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({
    super.key,
    this.blocking = false,
    this.feature,
    this.source = 'unknown',
  });
  final bool blocking;
  final PremiumFeature? feature;

  /// De onde a tela foi aberta (ver [openPremium]); guardado para uso futuro
  /// em eventos de Analytics desta tela.
  final String source;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: AccessService.instance,
    builder: (context, _) {
      final access = AccessService.instance;
      final annual = _annualOption(access);
      final monthly = _monthlyOption(access);
      final selected = access.selectedSubscription;
      final isAnnualSelected = selected?.isAnnual ?? true;
      return PopScope(
        canPop: !blocking,
        // Fechamento da tela (voltar ou "voltar ao app"), com o plano final.
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) return;
          AnalyticsService.tap(
            'subscription_close',
            screen: 'subscription',
            params: {
              'feature': feature?.name,
              'result': access.subscriptionActive ? 'premium' : 'free',
            },
          );
          // Fechou sem assinar (X, "Agora não" ou voltar): questionário de
          // saída, no máximo 1 vez a cada 7 dias. Aberto pelo Navigator,
          // que continua montado depois que esta tela sai.
          if (!access.subscriptionActive && !blocking) {
            maybeShowSubscriptionSurvey(Navigator.of(context));
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                _Header(
                  showClose: !blocking,
                  restoreEnabled: !access.purchasePending,
                  onRestore: access.signedIn
                      ? access.restorePurchases
                      : () => _openLogin(context),
                  title: access.subscriptionActive
                      ? tr.premiumYouArePremium
                      : feature?.title ?? tr.premiumFreePlan,
                  description: access.subscriptionActive
                      ? tr.premiumActive
                      : feature?.description ?? tr.premiumFreeIntro,
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    children: [
                      _BenefitsCard(feature: feature),
                      if (!access.subscriptionActive) ...[
                        const SizedBox(height: 18),
                        if (access.loadingStore)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 30),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (annual == null && monthly == null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              tr.subscriptionPlansAvailable,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.muted),
                            ),
                          )
                        else ...[
                          if (annual != null)
                            _PlanCard(
                              selected: isAnnualSelected,
                              title: tr.planAnnual,
                              priceBig: tr.perMonth(
                                _formatPrice(
                                  annual.currencyCode,
                                  annual.renewalMicros / 12 / 1e6,
                                ),
                              ),
                              priceSmall: tr.perYear(
                                _formatPrice(
                                  annual.currencyCode,
                                  annual.renewalMicros / 1e6,
                                ),
                              ),
                              trialBadge: annual.hasFreeTrial,
                              savePercent: _savePercent(annual, monthly),
                              onTap: () => _select(access, annual),
                            ),
                          if (monthly != null) ...[
                            const SizedBox(height: 12),
                            _PlanCard(
                              selected: !isAnnualSelected,
                              title: tr.planMonthly,
                              priceBig: tr.perMonth(
                                _formatPrice(
                                  monthly.currencyCode,
                                  monthly.renewalMicros / 1e6,
                                ),
                              ),
                              priceSmall: tr.subscriptionBilledMonthly,
                              onTap: () => _select(access, monthly),
                            ),
                          ],
                        ],
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: FilledButton(
                            onPressed:
                                access.purchasePending ||
                                    (access.signedIn &&
                                        access.subscriptionProduct == null)
                                ? null
                                : access.signedIn
                                ? () {
                                    _logPlan('subscribe', selected);
                                    access.buySubscription();
                                  }
                                : () => _openLogin(context),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.gold,
                              foregroundColor: AppColors.navy,
                            ),
                            child: Text(_buttonLabel(access, selected)),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _billingNote(selected),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                      if (access.storeMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          access.storeMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (access.subscriptionActive && !blocking) ...[
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(tr.premiumBackToApp),
                        ),
                      ],
                      if (!access.subscriptionActive && !blocking) ...[
                        const SizedBox(height: 10),
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              tr.notNow,
                              style: const TextStyle(
                                color: AppColors.blue,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  void _select(AccessService access, SubscriptionOption option) {
    // Só registra quando a opção muda de fato (evita repetir ao reselecionar
    // o mesmo cartão).
    if (access.selectedSubscription != option) {
      _logPlan('subscription_plan', option);
    }
    access.selectSubscription(option);
  }

  String _buttonLabel(AccessService access, SubscriptionOption? selected) {
    if (access.purchasePending) return tr.premiumWaitingPlay;
    if (!access.signedIn) return tr.premiumSignInToSubscribe;
    if (selected == null) return tr.upsellSubscribe;
    if (selected.hasFreeTrial) return tr.subscriptionStartFreeTrial;
    if (!selected.isAnnual) {
      return tr.subscriptionSubscribeMonthly(
        _formatPrice(selected.currencyCode, selected.renewalMicros / 1e6),
      );
    }
    return tr.upsellSubscribe;
  }

  String _billingNote(SubscriptionOption? option) {
    if (option == null || !option.hasFreeTrial) return tr.subscriptionBillingAuto;
    final price = _formatPrice(
      option.currencyCode,
      option.renewalMicros / 1e6,
    );
    return '${tr.subscriptionBillingTrial(price)} ${tr.subscriptionBillingAuto}';
  }

  /// Plano escolhido (ou assinado): só identificadores da Google Play.
  void _logPlan(String element, SubscriptionOption? option) =>
      AnalyticsService.tap(
        element,
        screen: 'subscription',
        params: {
          'feature': feature?.name,
          'plan': option?.basePlanId,
          'period': option?.billingPeriod,
          'offer_tag': option == null || option.offerTags.isEmpty
              ? null
              : option.offerTags.first,
          'is_trial': option?.hasFreeTrial,
        },
      );

  void _openLogin(BuildContext context) {
    // pushAndRemoveUntil não aciona onPopInvokedWithResult, então não há
    // duplicidade com o subscription_close registrado lá.
    AnalyticsService.tap(
      'subscription_close',
      screen: 'subscription',
      params: {'feature': feature?.name, 'result': 'login'},
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const LoginScreen(),
        settings: const RouteSettings(name: 'login'),
      ),
      (_) => false,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.showClose,
    required this.restoreEnabled,
    required this.onRestore,
    required this.title,
    required this.description,
  });

  final bool showClose;
  final bool restoreEnabled;
  final VoidCallback onRestore;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: AppColors.navy,
    padding: const EdgeInsets.fromLTRB(4, 4, 12, 24),
    child: Column(
      children: [
        Row(
          children: [
            if (showClose)
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              )
            else
              const SizedBox(width: 48, height: 48),
            const Spacer(),
            TextButton(
              onPressed: restoreEnabled ? onRestore : null,
              child: Text(
                tr.subscriptionRestore,
                style: const TextStyle(
                  color: AppColors.goldLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        Container(
          width: 72,
          height: 72,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Image.asset('assets/mycarapp_icon.png', fit: BoxFit.cover),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, height: 1.4),
        ),
      ],
    ),
  );
}

/// Um benefício real do Premium, mostrado no [_BenefitsCard]. [matches]
/// associa o item a um ou mais [PremiumFeature] para que ele suba ao topo da
/// lista quando foi esse o recurso que abriu a tela.
class _BenefitItem {
  const _BenefitItem(this.icon, this.text, this.matches);
  final IconData icon;
  final String text;
  final Set<PremiumFeature> matches;
}

List<_BenefitItem> _benefitItems() => [
  _BenefitItem(Icons.block_rounded, tr.benefitNoAds, {PremiumFeature.noAds}),
  _BenefitItem(Icons.directions_car_rounded, tr.benefitVehicles, {
    PremiumFeature.vehicles,
  }),
  _BenefitItem(Icons.build_rounded, tr.benefitMaintenanceNoVideo, {
    PremiumFeature.maintenance,
    PremiumFeature.fuelings,
  }),
  _BenefitItem(Icons.document_scanner_rounded, tr.benefitReceiptScan, {
    PremiumFeature.receiptScan,
  }),
  _BenefitItem(Icons.leaderboard_rounded, tr.benefitStationRanking, {
    PremiumFeature.stationRanking,
  }),
  _BenefitItem(Icons.file_download_rounded, tr.benefitExport, {
    PremiumFeature.export,
    PremiumFeature.pdf,
    PremiumFeature.periodReports,
  }),
  _BenefitItem(Icons.cloud_upload_outlined, tr.benefitBackup, {
    PremiumFeature.backup,
    PremiumFeature.sync,
  }),
];

class _BenefitsCard extends StatelessWidget {
  const _BenefitsCard({this.feature});
  final PremiumFeature? feature;

  @override
  Widget build(BuildContext context) {
    final items = _benefitItems();
    final matchIndex = feature == null
        ? -1
        : items.indexWhere((item) => item.matches.contains(feature));
    if (matchIndex > 0) items.insert(0, items.removeAt(matchIndex));
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE1E7EE)),
      ),
      child: Column(
        children: [
          for (final item in items)
            _Benefit(icon: item.icon, text: item.text),
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Icon(icon, color: AppColors.blue, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Icon(Icons.check_circle, color: AppColors.blue, size: 19),
      ],
    ),
  );
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.selected,
    required this.title,
    required this.priceBig,
    required this.priceSmall,
    required this.onTap,
    this.trialBadge = false,
    this.savePercent,
  });

  final bool selected;
  final String title;
  final String priceBig;
  final String priceSmall;
  final VoidCallback onTap;
  final bool trialBadge;
  final int? savePercent;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? AppColors.blue : const Color(0xFFE1E7EE),
          width: selected ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.text,
                  ),
                ),
                if (trialBadge || savePercent != null) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (trialBadge)
                        _Badge(
                          text: tr.subscriptionFreeTrialBadge,
                          background: AppColors.gold,
                          foreground: AppColors.navy,
                        ),
                      if (savePercent != null)
                        _Badge(
                          text: tr.subscriptionSaveBadge(savePercent!),
                          background: AppColors.blue.withValues(alpha: .12),
                          foreground: AppColors.blue,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                priceBig,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                priceSmall,
                style: const TextStyle(color: AppColors.muted, fontSize: 11.5),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.text,
    required this.background,
    required this.foreground,
  });
  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: foreground,
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}
