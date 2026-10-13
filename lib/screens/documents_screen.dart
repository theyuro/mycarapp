import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../models/app_document.dart';
import '../models/vehicle.dart';
import '../services/document_storage_service.dart';
import '../services/vehicle_storage_service.dart';
import '../theme/app_colors.dart';
import '../l10n/l10n.dart';

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
      message(tr.docsLoadError);
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
        throw FileSystemException(tr.fileUnavailable);
      }
      await storage.importPdf(
        sourcePath: selected.path!,
        originalName: selected.name,
        type: type,
        vehicleId: vehicleId,
      );
      await load();
      if (mounted) message(tr.docAttached, oneSecond: true);
    } on FormatException catch (error) {
      if (mounted) message(error.message);
    } catch (_) {
      if (mounted) message(tr.docAttachError);
    } finally {
      if (mounted) setState(() => importingType = null);
    }
  }

  Future<void> open(AppDocument document) async {
    if (!await File(document.path).exists()) {
      message(tr.docFileMissing);
      return;
    }
    final result = await OpenFilex.open(document.path, type: 'application/pdf');
    if (result.type != ResultType.done && mounted) {
      message(tr.docNoPdfReader);
    }
  }

  Future<void> remove(AppDocument document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr.docDeleteTitle),
        content: Text(tr.docDeleteText),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text(tr.deleteAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await storage.deleteDocument(document);
    await load();
    if (mounted) message(tr.docDeleted, oneSecond: true);
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
        title: Text(tr.docsTitle),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 36),
              children: [
                const _PrivacyNotice(),
                const SizedBox(height: 16),
                _DocumentCard(
                  title: tr.docDriverLicense,
                  subtitle: tr.docDriverLicenseHint,
                  icon: Icons.badge_outlined,
                  document: cnh,
                  loading: importingType == 'cnh',
                  onImport: () => import('cnh'),
                  onOpen: cnh == null ? null : () => open(cnh),
                  onDelete: cnh == null ? null : () => remove(cnh),
                ),
                const SizedBox(height: 12),
                _DocumentCard(
                  title: tr.docVehicle,
                  subtitle: vehicle == null
                      ? tr.docSelectVehicle
                      : tr.docVehicleOf(vehicle!.nickname),
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
                label: Text(document == null ? tr.docAttachPdf : tr.docOpenPdf),
              ),
            ),
            if (document != null) ...[
              const SizedBox(width: 8),
              IconButton(
                tooltip: tr.docReplacePdf,
                onPressed: onImport,
                icon: const Icon(Icons.sync_rounded),
              ),
              IconButton(
                tooltip: tr.delete,
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
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.lock_outline_rounded, color: AppColors.navy),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            tr.docsStorageNote,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );
}
