import 'package:flutter/material.dart';

import '../services/access_service.dart';
import '../services/auto_backup_service.dart';
import '../services/cloud_backup_service.dart';
import '../theme/app_colors.dart';
import 'lifetime_purchase_screen.dart';
import '../l10n/l10n.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final legacy = CloudBackupService();
  final auto = AutoBackupService.instance;
  List<BackupSummary> backups = const [];
  int cloudItems = 0;
  bool loading = true;
  bool working = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    final values = await Future.wait([
      legacy.listBackupsSafely(),
      auto.cloudItemCount(),
    ]);
    if (!mounted) return;
    setState(() {
      backups = values[0] as List<BackupSummary>;
      cloudItems = values[1] as int;
      loading = false;
    });
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
  );

  Future<void> backupNow() async {
    await auto.backupNow();
    if (!mounted) return;
    _message(auto.lastError ?? tr.backupDone);
    await load();
  }

  Future<void> restoreCloud() async {
    if (working) return;
    final confirmed = await _confirm(
      tr.backupRestoreCloudTitle,
      tr.backupRestoreCloudConfirm(cloudItems),
    );
    if (!confirmed || !mounted) return;
    setState(() => working = true);
    try {
      final count = await auto.restore();
      if (mounted) _message(tr.backupRestoredCount(count));
      await load();
    } on Object {
      if (mounted) _message(tr.backupRestoreError);
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<void> restoreLegacy(BackupSummary backup) async {
    if (working) return;
    RestoreImpact impact;
    try {
      impact = await legacy.previewRestore(backup.id);
    } on Object {
      if (mounted) _message(tr.backupReadError);
      return;
    }
    if (!mounted) return;
    final confirmed = await _confirm(
      tr.backupRestoreLegacyTitle,
      impact.total == 0
          ? tr.backupLegacyNothingNew
          : tr.backupLegacyImpact(impact.added, impact.updated),
    );
    if (!confirmed || !mounted) return;
    setState(() => working = true);
    try {
      await legacy.restoreMerge(backup.id);
      if (mounted) _message(tr.backupLegacyRestored);
      await load();
    } on Object {
      if (mounted) _message(tr.backupLegacyRestoreError);
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<bool> _confirm(String title, String text) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(text),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(tr.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(tr.restore),
            ),
          ],
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: AppColors.navy,
      foregroundColor: Colors.white,
      title: Text(tr.backupTitle),
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: load,
            child: AnimatedBuilder(
              animation: Listenable.merge([AccessService.instance, auto]),
              builder: (context, _) => ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (AccessService.instance.cloudBackupEnabled)
                    _AutoBackupCard(
                      lastBackupAt: auto.lastBackupAt,
                      running: auto.running,
                      error: auto.lastError,
                      onBackupNow: working || auto.running ? null : backupNow,
                    )
                  else
                    _PremiumBackupCard(
                      onTap: () => openPremium(context, PremiumFeature.backup),
                    ),
                  if (cloudItems > 0) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: working ? null : restoreCloud,
                        icon: working
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.cloud_download_outlined),
                        label: Text(
                          working
                              ? tr.backupRestoring
                              : tr.backupRestoreCloudButton(cloudItems),
                        ),
                      ),
                    ),
                  ],
                  if (backups.isNotEmpty) ...[
                    const SizedBox(height: 26),
                    Text(
                      tr.backupLegacyHeader,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tr.backupLegacyHint,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(height: 9),
                    for (final backup in backups)
                      _BackupTile(
                        backup: backup,
                        onRestore: working ? null : () => restoreLegacy(backup),
                      ),
                  ],
                ],
              ),
            ),
          ),
  );
}

class _AutoBackupCard extends StatelessWidget {
  const _AutoBackupCard({
    required this.lastBackupAt,
    required this.running,
    required this.error,
    required this.onBackupNow,
  });

  final DateTime? lastBackupAt;
  final bool running;
  final String? error;
  final VoidCallback? onBackupNow;

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
        Row(
          children: [
            Icon(
              error == null ? Icons.cloud_done_outlined : Icons.cloud_off,
              color: error == null ? Colors.green : Colors.orange,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tr.backupAutoActive,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          running
              ? tr.backupSending
              : error ??
                    (lastBackupAt == null
                        ? tr.backupFirstSoon
                        : tr.backupLastAt(_dateTime(lastBackupAt!))),
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 6),
        Text(
          tr.backupWhatIsSaved,
          style: const TextStyle(color: AppColors.muted, fontSize: 11.5),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            onPressed: onBackupNow,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.navy,
            ),
            icon: running
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_upload_outlined),
            label: Text(running ? tr.backupUploading : tr.backupNow),
          ),
        ),
      ],
    ),
  );
}

class _PremiumBackupCard extends StatelessWidget {
  const _PremiumBackupCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [AppColors.navy, AppColors.blue]),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        const Icon(
          Icons.cloud_upload_outlined,
          color: AppColors.gold,
          size: 38,
        ),
        const SizedBox(height: 10),
        Text(
          tr.backupIsPremium,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          tr.backupFreeExplain,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, height: 1.35),
        ),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: AppColors.navy,
          ),
          child: Text(tr.learnAboutPremium),
        ),
      ],
    ),
  );
}

class _BackupTile extends StatelessWidget {
  const _BackupTile({required this.backup, required this.onRestore});
  final BackupSummary backup;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE1E7EE)),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: AppColors.blue.withValues(alpha: .09),
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(Icons.cloud_done_outlined, color: AppColors.blue),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _dateTime(backup.createdAt),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                tr.backupLegacyTileInfo(
                  backup.totalRecords,
                  _sizeLabel(backup.sizeBytes),
                ),
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
        TextButton(onPressed: onRestore, child: Text(tr.restore)),
      ],
    ),
  );
}

String _dateTime(DateTime value) =>
    tr.dateAtTime(formatDate(value), formatTime(value));

String _sizeLabel(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
  return '${(kb / 1024).toStringAsFixed(1)} MB';
}
