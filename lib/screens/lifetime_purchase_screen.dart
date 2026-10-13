import 'package:flutter/material.dart';

import '../services/access_service.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';
import '../l10n/l10n.dart';

class AccessGate extends StatelessWidget {
  const AccessGate({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: AccessService.instance,
    builder: (context, _) => AccessService.instance.hasAccess
        ? child
        : const SubscriptionScreen(blocking: true),
  );
}

/// Recurso Premium que levou o usuário à tela de assinatura; define o
/// título exibido no topo.
enum PremiumFeature {
  noAds(Icons.block_rounded),
  backup(Icons.cloud_upload_outlined),
  reports(Icons.bar_chart_rounded),
  updates(Icons.auto_awesome_rounded);

  const PremiumFeature(this.icon);
  final IconData icon;

  String get title => switch (this) {
    noAds => tr.featureNoAdsTitle,
    backup => tr.featureBackupTitle,
    reports => tr.featureReportsTitle,
    updates => tr.featureUpdatesTitle,
  };

  String get description => switch (this) {
    noAds => tr.featureNoAdsText,
    backup => tr.featureBackupText,
    reports => tr.featureReportsText,
    updates => tr.featureUpdatesText,
  };
}

Future<void> openPremium(BuildContext context, [PremiumFeature? feature]) =>
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SubscriptionScreen(feature: feature),
      ),
    );

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key, this.blocking = false, this.feature});
  final bool blocking;
  final PremiumFeature? feature;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: AccessService.instance,
    builder: (context, _) {
      final access = AccessService.instance;
      return PopScope(
        canPop: !blocking,
        child: Scaffold(
          appBar: blocking
              ? null
              : AppBar(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                  title: const Text('MyCarApp Premium'),
                ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(22),
              children: [
                const SizedBox(height: 18),
                Container(
                  width: 82,
                  height: 82,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.goldLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    access.subscriptionActive
                        ? Icons.workspace_premium_rounded
                        : feature?.icon ?? Icons.workspace_premium_rounded,
                    size: 45,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  access.subscriptionActive
                      ? tr.premiumYouArePremium
                      : feature?.title ?? tr.premiumFreePlan,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  access.subscriptionActive
                      ? tr.premiumActive
                      : feature?.description ?? tr.premiumFreeIntro,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, height: 1.4),
                ),
                const SizedBox(height: 24),
                const _BenefitsCard(),
                const SizedBox(height: 18),
                if (!access.subscriptionActive) ...[
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.navy, AppColors.blue],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'MYCARAPP PREMIUM',
                          style: TextStyle(
                            color: AppColors.goldLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          access.selectedSubscription?.price ??
                              (access.loadingStore
                                  ? tr.loading
                                  : tr.premiumPrices),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (access.selectedSubscription != null)
                          Text(
                            access.selectedSubscription!.priceDescription,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        if (access.subscriptionOptions.length > 1) ...[
                          const SizedBox(height: 14),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: access.subscriptionOptions
                                .map(
                                  (option) => ChoiceChip(
                                    selected:
                                        access.selectedSubscription == option,
                                    onSelected: (_) =>
                                        access.selectSubscription(option),
                                    selectedColor: AppColors.gold,
                                    backgroundColor: Colors.white,
                                    label: Text(
                                      option.isPromotional
                                          ? tr.premiumOptionOffer(option.title)
                                          : option.title,
                                      style: const TextStyle(
                                        color: AppColors.navy,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton.icon(
                            onPressed:
                                access.purchasePending ||
                                    (access.signedIn &&
                                        access.subscriptionProduct == null)
                                ? null
                                : access.signedIn
                                ? access.buySubscription
                                : () => _openLogin(context),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.gold,
                              foregroundColor: AppColors.navy,
                            ),
                            icon: access.purchasePending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.shopping_bag_outlined),
                            label: Text(
                              access.purchasePending
                                  ? tr.premiumWaitingPlay
                                  : access.signedIn
                                  ? tr.upsellSubscribe
                                  : tr.premiumSignInToSubscribe,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: access.purchasePending
                        ? null
                        : access.signedIn
                        ? access.restorePurchases
                        : () => _openLogin(context),
                    icon: const Icon(Icons.restore_rounded),
                    label: Text(tr.premiumRestore),
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
                const SizedBox(height: 16),
                Text(
                  tr.premiumBillingNote,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
                if (access.subscriptionActive && !blocking) ...[
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(tr.premiumBackToApp),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );

  static void _openLogin(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }
}

class _BenefitsCard extends StatelessWidget {
  const _BenefitsCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xFFE1E7EE)),
    ),
    child: Column(
      children: [
        _Benefit(icon: Icons.block_rounded, text: tr.benefitNoAds),
        _Benefit(icon: Icons.cloud_upload_outlined, text: tr.benefitBackup),
        _Benefit(icon: Icons.bar_chart_rounded, text: tr.featureReportsTitle),
        _Benefit(
          icon: Icons.auto_awesome_rounded,
          text: tr.featureUpdatesTitle,
        ),
      ],
    ),
  );
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
        const Icon(Icons.check_circle, color: Colors.green, size: 19),
      ],
    ),
  );
}
