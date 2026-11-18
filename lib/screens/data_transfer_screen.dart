import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../services/analytics_service.dart';
import '../services/data_transfer_service.dart';
import '../services/free_plan_service.dart';
import '../theme/app_colors.dart';
import 'lifetime_purchase_screen.dart';
import '../l10n/l10n.dart';

class DataTransferScreen extends StatefulWidget {
  const DataTransferScreen({super.key});

  @override
  State<DataTransferScreen> createState() => _DataTransferScreenState();
}

class _DataTransferScreenState extends State<DataTransferScreen> {
  final transfer = DataTransferService();
  bool working = false;

  Future<void> export(String format) async {
    // Exportação em CSV/Excel é Premium; a importação continua livre.
    if (!FreePlanService.instance.exportAllowed) {
      await openPremium(context, PremiumFeature.export, 'limit_export');
      return;
    }
    // format é fixo no código ('csv' ou 'xlsx').
    AnalyticsService.tap('export_$format', screen: 'data_transfer');
    setState(() => working = true);
    try {
      final file = await transfer.exportVehicle(format);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: tr.exportSubject,
          text: tr.exportText,
        ),
      );
    } catch (error) {
      if (mounted) message(_friendlyError(error, tr.exportError));
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<void> import() async {
    final selected = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'xlsx'],
    );
    if (selected?.path == null || !mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr.importConfirmTitle),
        content: Text(tr.importConfirmText),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr.importAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => working = true);
    try {
      final summary = await transfer.importFile(selected!.path!);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(tr.importDone),
          content: Text(
            tr.importSummary(
              summary.vehicleName,
              summary.fuelings,
              summary.maintenances,
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) message(_friendlyError(error, tr.importError));
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  String _friendlyError(Object error, String fallback) {
    if (error is StateError) return error.message;
    if (error is FormatException) return error.message;
    return fallback;
  }

  void message(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: AppColors.navy,
      foregroundColor: Colors.white,
      title: Text(tr.exportTitle),
    ),
    body: _content(),
  );

  Widget _content() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const _InfoCard(),
      const SizedBox(height: 14),
      _ActionCard(
        icon: Icons.table_view_outlined,
        title: tr.exportCsv,
        subtitle: tr.exportCsvHint,
        onTap: working ? null : () => export('csv'),
      ),
      const SizedBox(height: 10),
      _ActionCard(
        icon: Icons.grid_on_rounded,
        title: tr.exportExcel,
        subtitle: tr.exportExcelHint,
        onTap: working ? null : () => export('xlsx'),
      ),
      const SizedBox(height: 10),
      _ActionCard(
        icon: Icons.phone_android_rounded,
        title: tr.importOtherDevice,
        subtitle: tr.importOtherDeviceHint,
        onTap: working ? null : import,
      ),
      if (working) ...[
        const SizedBox(height: 20),
        const Center(child: CircularProgressIndicator()),
      ],
    ],
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.goldLight,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(
      tr.exportInfo,
      style: const TextStyle(color: AppColors.text, height: 1.4),
    ),
  );
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    child: ListTile(
      contentPadding: const EdgeInsets.all(14),
      leading: Icon(icon, color: AppColors.blue, size: 30),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    ),
  );
}
