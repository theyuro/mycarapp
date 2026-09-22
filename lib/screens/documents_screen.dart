import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../models/app_document.dart';
import '../models/vehicle.dart';
import '../services/document_storage_service.dart';
import '../services/vehicle_storage_service.dart';
import '../theme/app_colors.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final storage = DocumentStorageService();
  final vehicleStorage = VehicleStorageService();
  Vehicle? vehicle;
  List<AppDocument> documents = const [];
  bool loading = true;
  String? importingType;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final results = await Future.wait<Object?>([
        vehicleStorage.loadActiveVehicle(),
        storage.loadDocuments(),
      ]);
      if (!mounted) return;
      setState(() {
        vehicle = results[0] as Vehicle?;
        documents = results[1] as List<AppDocument>;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
      message('Não foi possível carregar os documentos.');
    }
  }

  AppDocument? findDocument(String type, String? vehicleId) {
    for (final document in documents) {
      if (document.type == type && document.vehicleId == vehicleId) {
        return document;
      }
    }
    return null;
  }

  Future<void> import(String type, {String? vehicleId}) async {
    setState(() => importingType = type);
    try {
      final selected = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      if (selected == null) return;
      if (selected.path == null) {
        throw const FileSystemException('Arquivo indisponível.');
      }
      await storage.importPdf(
        sourcePath: selected.path!,
        originalName: selected.name,
        type: type,
        vehicleId: vehicleId,
      );
      await load();
      if (mounted) message('Documento anexado.', oneSecond: true);
    } on FormatException catch (error) {
      if (mounted) message(error.message);
    } catch (_) {
      if (mounted) message('Não foi possível anexar o PDF.');
    } finally {
      if (mounted) setState(() => importingType = null);
    }
  }

  Future<void> open(AppDocument document) async {
    if (!await File(document.path).exists()) {
      message('O arquivo não foi encontrado. Anexe o documento novamente.');
      return;
    }
    final result = await OpenFilex.open(document.path, type: 'application/pdf');
    if (result.type != ResultType.done && mounted) {
      message('Não há um leitor de PDF disponível no aparelho.');
    }
  }

  Future<void> remove(AppDocument document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir documento?'),
        content: const Text('A cópia armazenada no MyCarApp será removida.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('EXCLUIR'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await storage.deleteDocument(document);
    await load();
    if (mounted) message('Documento excluído.', oneSecond: true);
  }

  void message(String text, {bool oneSecond = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          behavior: SnackBarBehavior.floating,
          duration: oneSecond
              ? const Duration(seconds: 1)
              : const Duration(seconds: 3),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final cnh = findDocument('cnh', null);
    final vehicleDocument = findDocument('vehicle', vehicle?.id);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: const Text('Documentos'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 36),
              children: [
                const _PrivacyNotice(),
                const SizedBox(height: 16),
                _DocumentCard(
                  title: 'CNH-e',
                  subtitle: 'Carteira Nacional de Habilitação em PDF',
                  icon: Icons.badge_outlined,
                  document: cnh,
                  loading: importingType == 'cnh',
                  onImport: () => import('cnh'),
                  onOpen: cnh == null ? null : () => open(cnh),
                  onDelete: cnh == null ? null : () => remove(cnh),
                ),
                const SizedBox(height: 12),
                _DocumentCard(
                  title: 'Documento do veículo',
                  subtitle: vehicle == null
                      ? 'Selecione um veículo para anexar o CRLV-e'
                      : 'CRLV-e de ${vehicle!.nickname}',
                  icon: Icons.directions_car_filled_outlined,
                  document: vehicleDocument,
                  loading: importingType == 'vehicle',
                  onImport: vehicle == null
                      ? null
                      : () => import('vehicle', vehicleId: vehicle!.id),
                  onOpen: vehicleDocument == null
                      ? null
                      : () => open(vehicleDocument),
                  onDelete: vehicleDocument == null
                      ? null
                      : () => remove(vehicleDocument),
                ),
              ],
            ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.document,
    required this.loading,
    required this.onImport,
    required this.onOpen,
    required this.onDelete,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final AppDocument? document;
  final bool loading;
  final VoidCallback? onImport;
  final VoidCallback? onOpen;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE1E7EE)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.blue.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.blue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (document != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: Colors.redAccent,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    document!.originalName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: document == null ? onImport : onOpen,
                icon: loading
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        document == null
                            ? Icons.upload_file_rounded
                            : Icons.open_in_new_rounded,
                      ),
                label: Text(document == null ? 'ANEXAR PDF' : 'ABRIR PDF'),
              ),
            ),
            if (document != null) ...[
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Substituir PDF',
                onPressed: onImport,
                icon: const Icon(Icons.sync_rounded),
              ),
              IconButton(
                tooltip: 'Excluir',
                onPressed: onDelete,
                color: Colors.redAccent,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ],
        ),
      ],
    ),
  );
}

class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.goldLight,
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lock_outline_rounded, color: AppColors.navy),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Os PDFs são copiados para o armazenamento interno do MyCarApp e permanecem somente neste aparelho.',
            style: TextStyle(color: AppColors.text, fontSize: 12, height: 1.35),
          ),
        ),
      ],
    ),
  );
}
