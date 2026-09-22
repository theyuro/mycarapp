import 'package:flutter/material.dart';

import '../services/cloud_backup_service.dart';
import '../theme/app_colors.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final service = CloudBackupService();
  List<BackupSummary> backups = const [];
  bool loading = true;
  bool working = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final list = await service.listBackups();
      if (!mounted) return;
      setState(() {
        backups = list;
        loading = false;
      });
    } on Object {
      if (mounted) setState(() => loading = false);
    }
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
  );

  Future<void> backupNow() async {
    if (working) return;
    setState(() => working = true);
    try {
      await service.createBackup();
      if (mounted) _message('Backup criado com sucesso.');
      await load();
    } on Object {
      if (mounted) {
        _message('Não foi possível criar o backup. Verifique sua conexão.');
      }
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<void> restore(BackupSummary backup) async {
    if (working) return;
    RestoreImpact impact;
    try {
      impact = await service.previewRestore(backup.id);
    } on Object {
      if (mounted) {
        _message('Não foi possível ler este backup.');
      }
      return;
    }
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurar backup'),
        content: Text(
          impact.total == 0
              ? 'Este backup não tem nada além do que você já tem localmente.'
              : 'Isto vai adicionar ${impact.added} registro(s) novo(s) e '
                    'atualizar ${impact.updated} já existente(s). Nada é apagado. '
                    'Uma cópia do estado atual é criada automaticamente antes de restaurar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('RESTAURAR'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => working = true);
    try {
      await service.restoreMerge(backup.id);
      if (mounted) _message('Backup restaurado.');
      await load();
    } on Object {
      if (mounted) _message('Não foi possível restaurar este backup.');
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: AppColors.navy,
      foregroundColor: Colors.white,
      title: const Text('Backup e restauração'),
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: working ? null : backupNow,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.navy,
                    ),
                    icon: working
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload_outlined),
                    label: Text(
                      working ? 'TRABALHANDO...' : 'FAZER BACKUP AGORA',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Esta versão cobre veículos, abastecimentos, despesas, '
                  'manutenções e locais cadastrados. Fotos e documentos '
                  'anexados ainda não fazem parte do backup em nuvem.',
                  style: TextStyle(color: AppColors.muted, fontSize: 11.5),
                ),
                const SizedBox(height: 22),
                if (backups.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Text(
                      'Nenhum backup ainda. Toque em "Fazer backup agora" para criar o primeiro.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted),
                    ),
                  )
                else ...[
                  const Text(
                    'CÓPIAS DISPONÍVEIS',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .6,
                    ),
                  ),
                  const SizedBox(height: 9),
                  for (final backup in backups)
                    _BackupTile(
                      backup: backup,
                      onRestore: working ? null : () => restore(backup),
                    ),
                ],
              ],
            ),
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
                '${backup.totalRecords} registro(s) • ${_sizeLabel(backup.sizeBytes)}',
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
        TextButton(onPressed: onRestore, child: const Text('RESTAURAR')),
      ],
    ),
  );
}

String _dateTime(DateTime value) {
  final date =
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  final time =
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  return '$date às $time';
}

String _sizeLabel(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
  return '${(kb / 1024).toStringAsFixed(1)} MB';
}
