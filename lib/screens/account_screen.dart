import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/promotion_eligibility.dart';
import '../services/access_service.dart';
import '../services/account_cloud_service.dart';
import '../services/authentication_service.dart';
import '../services/auto_backup_service.dart';
import '../theme/app_colors.dart';
import '../widgets/institutional_footer.dart';
import 'backup_screen.dart';
import 'login_screen.dart';
import 'support_screen.dart';
import '../l10n/l10n.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final cloud = AccountCloudService();
  final referralController = TextEditingController();
  String? ownCode;
  PromotionEligibility? eligibility;
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
      if (!mounted) return;
      setState(() {
        ownCode = values[0] as String;
        eligibility = values[1] as PromotionEligibility;
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
      if (mounted) message(tr.referralApplied);
    } on Object catch (_) {
      if (mounted) message(tr.referralApplyError);
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
      message(tr.adminPremiumUpdated);
    } on Object catch (_) {
      if (mounted) message(tr.adminPremiumUpdateError);
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
        title: Text(tr.accountTitle),
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
                      Text(
                        AccessService.freeModeEnabled
                            ? tr.accountSignInBackup
                            : tr.accountSignInReferral,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
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
                        child: Text(tr.loginWithGoogle),
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
                          user.displayName ?? tr.accountUser,
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
                          title: Text(
                            tr.supportTitle,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(tr.supportSubtitle),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (_) => const SupportScreen(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AnimatedBuilder(
                        animation: AutoBackupService.instance,
                        builder: (context, _) => _BackupCard(
                          isPremium: AccessService.instance.cloudBackupEnabled,
                          lastBackupAt: AutoBackupService.instance.lastBackupAt,
                          onTap: openBackup,
                        ),
                      ),
                      if (user.email?.toLowerCase() ==
                          'giles.softwares@gmail.com') ...[
                        const SizedBox(height: 12),
                        _AccountCard(
                          title: tr.adminTitle,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr.adminPremiumUntil(_date(premiumFreeUntil)),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: changePremiumDate,
                                  icon: const Icon(
                                    Icons.edit_calendar_outlined,
                                  ),
                                  label: Text(tr.adminChangeDate),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      // Indicações e ofertas só dão desconto na assinatura:
                      // ficam ocultas no modo gratuito.
                      if (!AccessService.freeModeEnabled) ...[
                        const SizedBox(height: 18),
                        _AccountCard(
                          title: tr.referralYourCode,
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
                                tooltip: tr.referralCopy,
                                onPressed: ownCode == null
                                    ? null
                                    : () async {
                                        await Clipboard.setData(
                                          ClipboardData(text: ownCode!),
                                        );
                                        if (mounted) message(tr.referralCopied);
                                      },
                                icon: const Icon(Icons.copy_rounded),
                              ),
                              IconButton(
                                tooltip: tr.referralInvite,
                                onPressed: ownCode == null
                                    ? null
                                    : () => SharePlus.instance.share(
                                        ShareParams(
                                          subject: 'MyCarApp',
                                          text: tr.referralShareText(
                                            ownCode!,
                                            'https://play.google.com/store/apps/details?id=com.gilesdesenvolvimento.mycarapp',
                                          ),
                                        ),
                                      ),
                                icon: const Icon(Icons.share_outlined),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _AccountCard(
                          title: tr.referralReceived,
                          child: Column(
                            children: [
                              TextField(
                                controller: referralController,
                                textCapitalization:
                                    TextCapitalization.characters,
                                decoration: InputDecoration(
                                  labelText: tr.referralCodeLabel,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: applying ? null : applyCode,
                                  child: Text(
                                    applying
                                        ? tr.referralApplying
                                        : tr.referralApply,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (eligibility?.bestOfferTag != null) ...[
                          const SizedBox(height: 12),
                          _AccountCard(
                            title: tr.bestOffer,
                            child: Text(
                              _offerName(eligibility!.bestOfferTag!),
                              style: const TextStyle(
                                color: AppColors.blue,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
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
                        label: Text(tr.signOut),
                      ),
                    ],
            ),
    );
  }
}

class _BackupCard extends StatelessWidget {
  const _BackupCard({
    required this.isPremium,
    required this.lastBackupAt,
    required this.onTap,
  });

  final bool isPremium;
  final DateTime? lastBackupAt;
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
          child: Row(
            children: [
              const Icon(
                Icons.cloud_upload_outlined,
                color: AppColors.gold,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr.backupIsPremium,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      tr.accountBackupPitch,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white70),
            ],
          ),
        ),
      );
    }

    final backupAt = lastBackupAt;
    final stale =
        backupAt == null || DateTime.now().difference(backupAt).inDays >= 7;
    return Card(
      elevation: 0,
      child: ListTile(
        leading: Icon(
          Icons.cloud_done_outlined,
          color: stale ? Colors.orange : Colors.green,
        ),
        title: Text(
          tr.backupTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          backupAt == null
              ? tr.backupAutoActive
              : stale
              ? tr.backupDaysAgo(DateTime.now().difference(backupAt).inDays)
              : tr.backupLastOn(_shortDate(backupAt)),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

String _shortDate(DateTime value) =>
    tr.dateAtTime(formatDayMonth(value), formatTime(value));

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
  'closed-test-3m-70' => tr.offerClosedTest3m,
  'closed-test-yr-70' => tr.offerClosedTestYear,
  'first-1000-annual-pl' => tr.offerFounders,
  'referral-yr-30' => tr.offerReferral,
  'referral-3m-50' => tr.offerReferralOld,
  _ => tr.offerSpecial,
};

String _date(DateTime? value) => value == null ? tr.notSet : formatDate(value);
