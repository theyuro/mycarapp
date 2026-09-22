import 'package:flutter/material.dart';

import '../services/access_service.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';

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

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key, this.blocking = false});
  final bool blocking;

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
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    size: 45,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  access.subscriptionActive
                      ? 'Você é Premium'
                      : 'Você está no plano gratuito',
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
                      ? 'Sua assinatura do MyCarApp está ativa.'
                      : 'Continue cuidando de 1 veículo gratuitamente ou libere todos os recursos.',
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
                                  ? 'Carregando...'
                                  : 'Preço a definir'),
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
                                          ? '${option.title} · oferta'
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
                                  ? 'AGUARDANDO GOOGLE PLAY...'
                                  : access.signedIn
                                  ? 'ASSINAR'
                                  : 'ENTRAR PARA ASSINAR',
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
                    label: const Text('RESTAURAR ASSINATURA'),
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
                const Text(
                  'Pagamento processado pela Google Play. A assinatura tem renovação automática e pode ser cancelada pela Play Store.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                ),
                if (access.subscriptionActive && !blocking) ...[
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('VOLTAR AO APP'),
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
    child: const Column(
      children: [
        _Benefit(
          icon: Icons.garage_outlined,
          text: 'Cadastre e gerencie vários veículos',
        ),
        _Benefit(
          icon: Icons.local_gas_station_outlined,
          text: 'Experiência sem anúncios',
        ),
        _Benefit(
          icon: Icons.build_circle_outlined,
          text: 'Relatórios, históricos e projeções avançadas',
        ),
        _Benefit(
          icon: Icons.bar_chart_rounded,
          text: 'Rankings e comparativos',
        ),
        _Benefit(
          icon: Icons.import_export_rounded,
          text: 'Exportação e backup das informações',
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
