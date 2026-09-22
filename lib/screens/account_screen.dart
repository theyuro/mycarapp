import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/promotion_eligibility.dart';
import '../services/account_cloud_service.dart';
import '../services/authentication_service.dart';
import '../services/access_service.dart';
import '../services/cloud_backup_service.dart';
import '../theme/app_colors.dart';
import '../widgets/institutional_footer.dart';
import 'backup_screen.dart';
import 'login_screen.dart';
import 'support_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final cloud = AccountCloudService();
  final backupService = CloudBackupService();
  final referralController = TextEditingController();
  String? ownCode;
  PromotionEligibility? eligibility;
  List<BackupSummary> backups = const [];
  bool loading = true;
  bool applying = false;
  DateTime? premiumFreeUntil = AccessService.instance.premiumFreeUntil;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (cloud.currentUser == null) {
      setState(() => loading = false);
      return;
    }
    try {
      final values = await Future.wait([
        cloud.ensureProfile(),
        cloud.getPromotionEligibility(),
      ]);
      final backupList = await backupService.listBackupsSafely();
      if (!mounted) return;
      setState(() {
        ownCode = values[0] as String;
        eligibility = values[1] as PromotionEligibility;
        backups = backupList;
        loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> openBackup() async {
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute<void>(builder: (_) => const BackupScreen()));
    if (mounted) await load();
  }

  Future<void> applyCode() async {
    if (referralController.text.trim().isEmpty || applying) return;
    setState(() => applying = true);
    try {
      await cloud.applyReferralCode(referralController.text);
      await AccessService.instance.refreshSubscriptionOffers();
      await load();
      if (mounted)
        message(
          'Código aplicado! O benefício será ativado após o primeiro pagamento.',
        );
    } on Object catch (_) {
      if (mounted)
        message(
          'Não foi possível aplicar esse código. Verifique e tente novamente.',
        );
    } finally {
      if (mounted) setState(() => applying = false);
    }
  }

  void message(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
  );

  Future<void> changePremiumDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate:
          premiumFreeUntil ?? DateTime.now().add(const Duration(days: 14)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (selected == null) return;
    final until = DateTime(
      selected.year,
      selected.month,
      selected.day,
      23,
      59,
      59,
    );
    try {
      await cloud.updatePremiumFreeUntil(until);
      if (!mounted) return;
      setState(() => premiumFreeUntil = until);
      message('Acesso Premium gratuito atualizado.');
    } on Object catch (_) {
      if (mounted) message('Não foi possível atualizar o período.');
    }
  }

  @override
  void dispose() {
    referralController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = cloud.currentUser;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: const Text('Minha conta'),
      ),
      bottomNavigationBar: const SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: InstitutionalFooter(dark: false),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: user == null
                  ? [
                      const Icon(
                        Icons.account_circle_outlined,
                        size: 72,
                        color: AppColors.blue,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Entre para usar indicações e descontos',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: () =>
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute<void>(
                                builder: (_) => const LoginScreen(),
                              ),
                              (_) => false,
                            ),
                        child: const Text('ENTRAR COM GOOGLE'),
                      ),
                    ]
                  : [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundImage: user.photoURL == null
                              ? null
                              : NetworkImage(user.photoURL!),
                          child: user.photoURL == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(
                          user.displayName ?? 'Usuário',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(user.email ?? ''),
                      ),
                      Card(
                        elevation: 0,
                        child: ListTile(
                          leading: const Icon(
                            Icons.support_agent_rounded,
                            color: AppColors.blue,
                          ),
                          title: const Text(
                            'Ajuda, feedback e bugs',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: const Text(
                            'Envie e acompanhe seus chamados',
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (_) => const SupportScreen(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _BackupCard(
                        isPremium: AccessService.instance.subscriptionActive,
                        lastBackup: backups.isEmpty ? null : backups.first,
                        onTap: openBackup,
                      ),
                      if (user.email?.toLowerCase() ==
                          'giles.softwares@gmail.com') ...[
                        const SizedBox(height: 12),
                        _AccountCard(
                          title: 'Administração do teste',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Premium gratuito até ${_date(premiumFreeUntil)}',
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: changePremiumDate,
                                  icon: const Icon(
                                    Icons.edit_calendar_outlined,
                                  ),
                                  label: const Text('ALTERAR DATA'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      _AccountCard(
                        title: 'Seu código de indicação',
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                ownCode ?? '—',
                                style: const TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Copiar código',
                              onPressed: ownCode == null
                                  ? null
                                  : () async {
                                      await Clipboard.setData(
                                        ClipboardData(text: ownCode!),
                                      );
                                      if (mounted) message('Código copiado.');
                                    },
                              icon: const Icon(Icons.copy_rounded),
                            ),
                            IconButton(
                              tooltip: 'Convidar um amigo',
                              onPressed: ownCode == null
                                  ? null
                                  : () => SharePlus.instance.share(
                                      ShareParams(
                                        subject: 'MyCarApp',
                                        text:
                                            'Uso o MyCarApp pra controlar os gastos do carro. '
                                            'Baixa com meu código de indicação $ownCode e '
                                            'ganha desconto na assinatura: '
                                            'https://play.google.com/store/apps/details?id=com.gilesdesenvolvimento.mycarapp',
                                      ),
                                    ),
                              icon: const Icon(Icons.share_outlined),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _AccountCard(
                        title: 'Recebeu um código?',
                        child: Column(
                          children: [
                            TextField(
                              controller: referralController,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(
                                labelText: 'Código de indicação',
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: applying ? null : applyCode,
                                child: Text(
                                  applying ? 'APLICANDO...' : 'APLICAR CÓDIGO',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (eligibility?.bestOfferTag != null) ...[
                        const SizedBox(height: 12),
                        _AccountCard(
                          title: 'Melhor oferta disponível',
                          child: Text(
                            _offerName(eligibility!.bestOfferTag!),
                            style: const TextStyle(
                              color: AppColors.blue,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await AuthenticationService.instance.signOut();
                          if (!context.mounted) return;
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute<void>(
                              builder: (_) => const LoginScreen(),
                            ),
                            (_) => false,
                          );
                        },
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('SAIR DA CONTA'),
                      ),
                    ],
            ),
    );
  }
}

class _BackupCard extends StatelessWidget {
  const _BackupCard({
    required this.isPremium,
    required this.lastBackup,
    required this.onTap,
  });

  final bool isPremium;
  final BackupSummary? lastBackup;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (!isPremium) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.navy, AppColors.blue],
            ),
            borderRadius: BorderRadius.circular(17),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.cloud_upload_outlined,
                color: AppColors.gold,
                size: 28,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Backup em nuvem é Premium',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Proteja seu histórico contra perda ao trocar de aparelho.',
                      style: TextStyle(color: Colors.white70, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.white70),
            ],
          ),
        ),
      );
    }

    final backup = lastBackup;
    final stale = backup == null
        ? true
        : DateTime.now().difference(backup.createdAt).inDays >= 7;
    return Card(
      elevation: 0,
      child: ListTile(
        leading: Icon(
          Icons.cloud_done_outlined,
          color: stale ? Colors.orange : Colors.green,
        ),
        title: const Text(
          'Backup e restauração',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          backup == null
              ? 'Nenhum backup ainda'
              : stale
              ? 'Último backup há ${DateTime.now().difference(backup.createdAt).inDays} dia(s)'
              : 'Último backup em ${_shortDate(backup.createdAt)}',
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

String _shortDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')} às '
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xFFE1E7EE)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

String _offerName(String tag) => switch (tag) {
  'closed-test-3m-70' => '70% de desconto por 3 meses',
  'closed-test-yr-70' => '70% de desconto no primeiro ano',
  'first-1000-annual-pl' => '50% de desconto no primeiro ano',
  'referral-3m-50' => '50% de desconto por 3 meses',
  _ => 'Oferta especial MyCarApp',
};

String _date(DateTime? value) => value == null
    ? 'não definida'
    : '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
