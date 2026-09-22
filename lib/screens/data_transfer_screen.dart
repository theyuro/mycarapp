import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../services/access_service.dart';
import '../services/data_transfer_service.dart';
import '../theme/app_colors.dart';
import 'lifetime_purchase_screen.dart';

class DataTransferScreen extends StatefulWidget {
  const DataTransferScreen({super.key});

  @override
  State<DataTransferScreen> createState() => _DataTransferScreenState();
}

class _DataTransferScreenState extends State<DataTransferScreen> {
  final transfer = DataTransferService();
  bool working = false;

  Future<void> export(String format) async {
    setState(() => working = true);
    try {
      final file = await transfer.exportVehicle(format);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'Exportação MyCarApp',
          text: 'Dados do veículo exportados pelo MyCarApp.',
        ),
      );
    } catch (error) {
      if (mounted) message(_friendlyError(error, 'Não foi possível exportar.'));
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
        title: const Text('Importar informações?'),
        content: const Text(
          'Um novo veículo será criado com os abastecimentos e manutenções do arquivo. Os dados atuais não serão sobrescritos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('IMPORTAR'),
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
          title: const Text('Importação concluída'),
          content: Text(
            '${summary.vehicleName}\n${summary.fuelings} abastecimento(s)\n${summary.maintenances} manutenção(ões)',
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
      if (mounted) message(_friendlyError(error, 'Não foi possível importar.'));
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
  Widget build(BuildContext context) {
    final unlocked = AccessService.instance.subscriptionActive;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: const Text('Exportar informações'),
      ),
      body: unlocked ? _content() : _locked(),
    );
  }

  Widget _locked() => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            size: 68,
            color: AppColors.gold,
          ),
          const SizedBox(height: 18),
          const Text(
            'Recurso exclusivo da assinatura',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Exporte ou transfira o histórico completo do veículo entre aparelhos.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => const SubscriptionScreen(),
              ),
            ),
            icon: const Icon(Icons.workspace_premium_outlined),
            label: const Text('CONHECER A ASSINATURA'),
          ),
        ],
      ),
    ),
  );

  Widget _content() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const _InfoCard(),
      const SizedBox(height: 14),
      _ActionCard(
        icon: Icons.table_view_outlined,
        title: 'Exportar CSV',
        subtitle: 'Formato leve, compatível com planilhas e com o MyCarApp.',
        onTap: working ? null : () => export('csv'),
      ),
      const SizedBox(height: 10),
      _ActionCard(
        icon: Icons.grid_on_rounded,
        title: 'Exportar Excel',
        subtitle: 'Planilha XLSX pronta para compartilhar ou arquivar.',
        onTap: working ? null : () => export('xlsx'),
      ),
      const SizedBox(height: 10),
      _ActionCard(
        icon: Icons.phone_android_rounded,
        title: 'Importar em outro aparelho',
        subtitle: 'Leia um CSV ou Excel criado pelo MyCarApp.',
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
    child: const Text(
      'A exportação utiliza o veículo ativo e inclui cadastro, abastecimentos e manutenções. Fotos e notas fiscais permanecem somente no aparelho por segurança.',
      style: TextStyle(color: AppColors.text, height: 1.4),
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
