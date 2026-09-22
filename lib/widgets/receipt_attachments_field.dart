import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';

import '../models/record_attachment.dart';
import '../theme/app_colors.dart';

class ReceiptAttachmentsField extends StatelessWidget {
  const ReceiptAttachmentsField({
    super.key,
    required this.attachments,
    required this.onChanged,
    this.onScanReceipt,
    this.scanning = false,
  });

  final List<RecordAttachment> attachments;
  final ValueChanged<List<RecordAttachment>> onChanged;
  final VoidCallback? onScanReceipt;
  final bool scanning;

  Future<void> _camera(BuildContext context) async {
    final photo = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 82,
      maxWidth: 2048,
      maxHeight: 2048,
    );
    if (photo == null) return;
    _add(photo.path, photo.name, 'image');
  }

  Future<void> _file(BuildContext context) async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
    );
    if (file?.path == null) return;
    final isPdf = file!.name.toLowerCase().endsWith('.pdf');
    _add(file.path!, file.name, isPdf ? 'pdf' : 'image');
  }

  void _add(String path, String name, String type) {
    onChanged([
      ...attachments,
      RecordAttachment(
        path: path,
        name: name,
        type: type,
        createdAt: DateTime.now(),
      ),
    ]);
  }

  Future<void> _open(BuildContext context, RecordAttachment attachment) async {
    if (!await File(attachment.path).exists()) {
      if (context.mounted) _message(context, 'O anexo não foi encontrado.');
      return;
    }
    final result = await OpenFilex.open(attachment.path);
    if (result.type != ResultType.done && context.mounted) {
      _message(context, 'Não foi possível abrir este anexo.');
    }
  }

  void _message(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (attachments.isNotEmpty) ...[
        ...attachments.asMap().entries.map(
          (entry) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              dense: true,
              leading: Icon(
                entry.value.isPdf
                    ? Icons.picture_as_pdf_rounded
                    : Icons.image_outlined,
                color: entry.value.isPdf ? Colors.redAccent : AppColors.blue,
              ),
              title: Text(
                entry.value.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => _open(context, entry.value),
              trailing: IconButton(
                tooltip: 'Remover anexo',
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  final updated = [...attachments]..removeAt(entry.key);
                  onChanged(updated);
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
      ],
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _camera(context),
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('TIRAR FOTO'),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _file(context),
              icon: const Icon(Icons.attach_file_rounded),
              label: const Text('ANEXAR'),
            ),
          ),
        ],
      ),
      if (onScanReceipt != null) ...[
        const SizedBox(height: 9),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: scanning ? null : onScanReceipt,
            icon: scanning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.document_scanner_outlined),
            label: Text(
              scanning ? 'LENDO NOTA...' : 'LER NOTA E PREENCHER DADOS',
            ),
          ),
        ),
      ],
      const SizedBox(height: 6),
      const Text(
        'Imagens e arquivos PDF são aceitos.',
        style: TextStyle(color: AppColors.muted, fontSize: 11),
      ),
    ],
  );
}
