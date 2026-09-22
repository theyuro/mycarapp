import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/establishment.dart';
import '../models/fueling_record.dart';
import '../models/record_attachment.dart';
import '../models/vehicle.dart';
import '../services/establishment_storage_service.dart';
import '../services/fueling_storage_service.dart';
import '../services/notification_service.dart';
import '../services/receipt_ocr_service.dart';
import '../theme/app_colors.dart';
import '../widgets/vehicle_type_icon.dart';
import '../widgets/establishment_field.dart';
import '../widgets/receipt_attachments_field.dart';

class FuelingFormScreen extends StatefulWidget {
  const FuelingFormScreen({super.key, required this.vehicle, this.record});

  final Vehicle vehicle;
  final FuelingRecord? record;

  @override
  State<FuelingFormScreen> createState() => _FuelingFormScreenState();
}

class _FuelingFormScreenState extends State<FuelingFormScreen> {
  final formKey = GlobalKey<FormState>();
  final liters = TextEditingController();
  final totalPrice = TextEditingController();
  final mileage = TextEditingController();
  final notes = TextEditingController();
  final tankCapacity = TextEditingController();
  final storage = FuelingStorageService();
  final notificationService = NotificationService();
  final receiptOcr = ReceiptOcrService();
  final establishmentStorage = EstablishmentStorageService();

  late DateTime date;
  late String fuelType;
  bool fullTank = false;
  bool gaugeMarkedFull = false;
  bool saving = false;
  bool scanningReceipt = false;
  List<RecordAttachment> attachments = const [];

  String stationText = '';
  String? establishmentId;
  int establishmentFieldGeneration = 0;
  List<Establishment> stations = const [];
  List<String> recentStationIds = const [];

  static const fuelTypes = <String>[
    'Gasolina',
    'Etanol',
    'Diesel',
    'GNV',
    'Elétrico',
    'Outro',
  ];

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    date = record?.date ?? DateTime.now();
    fuelType = _initialFuelType(record?.fuelType ?? widget.vehicle.fuel);
    fullTank = record?.fullTank ?? false;
    gaugeMarkedFull = record?.gaugeMarkedFull ?? false;
    if (record != null) {
      attachments = [...record.attachments];
      liters.text = _editableNumber(record.liters);
      totalPrice.text = _editableNumber(record.totalPrice);
      mileage.text = record.mileage?.toString() ?? '';
      stationText = record.station ?? '';
      establishmentId = record.establishmentId;
      notes.text = record.notes ?? '';
      tankCapacity.text = record.tankCapacityLiters == null
          ? ''
          : _editableNumber(record.tankCapacityLiters!);
    } else {
      mileage.text = widget.vehicle.mileage.toString();
    }
    unawaited(_loadStations());
  }

  Future<void> _loadStations() async {
    try {
      final results = await Future.wait([
        establishmentStorage.loadActiveEstablishments(
          type: EstablishmentType.posto,
        ),
        storage.loadFuelings(),
      ]);
      final establishments = results[0] as List<Establishment>;
      final fuelings = results[1] as List<FuelingRecord>;
      final usage = <String, int>{};
      final lastUsed = <String, DateTime>{};
      for (final fueling in fuelings) {
        final id = fueling.establishmentId;
        if (id == null || fueling.vehicleId != widget.vehicle.id) continue;
        usage[id] = (usage[id] ?? 0) + 1;
        final current = lastUsed[id];
        if (current == null || fueling.date.isAfter(current)) {
          lastUsed[id] = fueling.date;
        }
      }
      final recent = usage.keys.toList()
        ..sort((a, b) {
          final countCompare = usage[b]!.compareTo(usage[a]!);
          if (countCompare != 0) return countCompare;
          return lastUsed[b]!.compareTo(lastUsed[a]!);
        });
      if (!mounted) return;
      setState(() {
        stations = establishments;
        recentStationIds = recent.take(3).toList();
      });
    } on Object {
      // Sem estabelecimentos cadastrados ainda: o campo funciona como texto
      // livre normalmente.
    }
  }

  String _initialFuelType(String value) {
    if (fuelTypes.contains(value)) return value;
    if (value == 'Flex') return 'Gasolina';
    return 'Outro';
  }

  String _editableNumber(double value) =>
      value.toStringAsFixed(2).replaceAll('.', ',');

  double? _parseNumber(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));

  String? _positiveNumber(String? value) {
    final number = _parseNumber(value ?? '');
    return number == null || number <= 0 ? 'Informe um valor válido' : null;
  }

  Future<void> selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(1980),
      lastDate: DateTime.now(),
    );
    if (selected != null && mounted) setState(() => date = selected);
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => saving = true);
    final now = DateTime.now();
    final record = FuelingRecord(
      id: widget.record?.id ?? '${now.microsecondsSinceEpoch}',
      vehicleId: widget.vehicle.id,
      liters: _parseNumber(liters.text)!,
      totalPrice: _parseNumber(totalPrice.text)!,
      date: date,
      mileage: mileage.text.trim().isEmpty ? null : int.parse(mileage.text),
      fuelType: fuelType,
      station: stationText.trim().isEmpty ? null : stationText.trim(),
      establishmentId: establishmentId,
      fullTank: fullTank,
      tankCapacityLiters: fullTank ? _parseNumber(tankCapacity.text) : null,
      gaugeMarkedFull: fullTank && gaugeMarkedFull,
      notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
      attachments: attachments,
    );

    try {
      await storage.saveFueling(record);
      final capacity = record.tankCapacityLiters;
      if (capacity != null && record.liters > capacity) {
        await notificationService.addUnique(
          key: 'fuel-overfill-${record.id}',
          title: 'Abastecimento inadequado',
          message:
              '${record.liters.toStringAsFixed(2).replaceAll('.', ',')} L informados para um tanque de ${capacity.toStringAsFixed(2).replaceAll('.', ',')} L.',
          category: 'overfill',
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível salvar o abastecimento.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> scanReceipt() async {
    final photo = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 86,
      maxWidth: 2048,
      maxHeight: 2048,
    );
    if (photo == null || !mounted) return;
    setState(() => scanningReceipt = true);
    try {
      final result = await receiptOcr.recognize(photo.path);
      if (!mounted) return;
      final apply = await _confirmOcr(result);
      if (!mounted || apply != true) return;
      setState(() {
        attachments = [
          ...attachments,
          RecordAttachment(
            path: photo.path,
            name: photo.name,
            type: 'image',
            createdAt: DateTime.now(),
          ),
        ];
        if (result.station != null) {
          stationText = result.station!;
          establishmentId = null;
          establishmentFieldGeneration++;
        }
        if (result.liters != null)
          liters.text = _editableNumber(result.liters!);
        if (result.totalPrice != null) {
          totalPrice.text = _editableNumber(result.totalPrice!);
        }
        if (result.fuelType != null && fuelTypes.contains(result.fuelType)) {
          fuelType = result.fuelType!;
        }
        if (result.date != null) date = result.date!;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível ler a nota. Tente outra foto.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => scanningReceipt = false);
    }
  }

  Future<bool?> _confirmOcr(ReceiptOcrResult result) => showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Conferir dados reconhecidos'),
      content: result.hasAnyValue
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _OcrLine('Posto', result.station),
                _OcrLine('Combustível', result.fuelType),
                _OcrLine(
                  'Abastecimento',
                  result.liters == null
                      ? null
                      : '${_editableNumber(result.liters!)} L',
                ),
                _OcrLine(
                  'Preço total',
                  result.totalPrice == null
                      ? null
                      : 'R\$ ${_editableNumber(result.totalPrice!)}',
                ),
                _OcrLine(
                  'Data',
                  result.date == null ? null : _formatDate(result.date!),
                ),
                const SizedBox(height: 10),
                const Text('Revise os campos antes de salvar.'),
              ],
            )
          : const Text(
              'Nenhum dado foi reconhecido. Tente fotografar novamente com boa luz e a nota inteira visível.',
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('CANCELAR'),
        ),
        if (result.hasAnyValue)
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('PREENCHER'),
          ),
      ],
    ),
  );

  @override
  void dispose() {
    liters.dispose();
    totalPrice.dispose();
    mileage.dispose();
    notes.dispose();
    tankCapacity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: AppColors.navy,
      foregroundColor: Colors.white,
      title: Text(
        widget.record == null ? 'Novo abastecimento' : 'Editar abastecimento',
      ),
    ),
    body: Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoBanner(vehicle: widget.vehicle),
          const SizedBox(height: 16),
          _FormCard(
            title: 'Dados do abastecimento',
            icon: Icons.local_gas_station_rounded,
            child: Column(
              children: [
                InkWell(
                  onTap: selectDate,
                  borderRadius: BorderRadius.circular(14),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Data',
                      suffixIcon: Icon(Icons.calendar_month_outlined),
                    ),
                    child: Text(_formatDate(date)),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: fuelType,
                  decoration: const InputDecoration(labelText: 'Combustível'),
                  items: fuelTypes
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => fuelType = value!),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: liters,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Litros',
                          suffixText: 'L',
                        ),
                        validator: _positiveNumber,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: totalPrice,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Valor total',
                          prefixText: 'R\$ ',
                        ),
                        validator: _positiveNumber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: mileage,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Quilometragem',
                    suffixText: 'km',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return fullTank && gaugeMarkedFull
                          ? 'Obrigatória para o cálculo'
                          : null;
                    }
                    return int.tryParse(value) == null
                        ? 'Informe uma quilometragem válida'
                        : null;
                  },
                ),
                const SizedBox(height: 6),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tanque cheio'),
                  subtitle: const Text(
                    'Necessário para calcular o consumo com precisão',
                  ),
                  value: fullTank,
                  activeThumbColor: AppColors.blue,
                  onChanged: (value) => setState(() {
                    fullTank = value;
                    if (!value) gaugeMarkedFull = false;
                  }),
                ),
                if (fullTank) ...[
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: tankCapacity,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Capacidade total do tanque',
                      suffixText: 'L',
                      helperText: 'Consulte o manual do veículo',
                    ),
                    validator: (value) {
                      if (!fullTank) return null;
                      final capacity = _parseNumber(value ?? '');
                      if (capacity == null || capacity <= 0) {
                        return 'Informe a capacidade do tanque';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 6),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('O marcador indicou tanque cheio?'),
                    subtitle: const Text(
                      'Somente confirmações reais entram no consumo estimado',
                    ),
                    value: gaugeMarkedFull,
                    activeColor: AppColors.blue,
                    onChanged: (value) =>
                        setState(() => gaugeMarkedFull = value ?? false),
                  ),
                ],
              ],
            ),
          ),
          _FormCard(
            title: 'Informações opcionais',
            icon: Icons.notes_rounded,
            child: Column(
              children: [
                EstablishmentField(
                  key: ValueKey(establishmentFieldGeneration),
                  label: 'Posto de combustível',
                  type: EstablishmentType.posto,
                  establishments: stations,
                  recentIds: recentStationIds,
                  initialText: stationText,
                  initialEstablishmentId: establishmentId,
                  onTextChanged: (value) => stationText = value,
                  onEstablishmentSelected: (value) =>
                      establishmentId = value?.id,
                  onCreateEstablishment: (name) async {
                    final created = await establishmentStorage.createQuick(
                      name: name,
                      type: EstablishmentType.posto,
                    );
                    if (mounted) {
                      setState(() => stations = [...stations, created]);
                    }
                    return created;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: notes,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Observações'),
                ),
              ],
            ),
          ),
          _FormCard(
            title: 'Nota fiscal e comprovantes',
            icon: Icons.receipt_long_outlined,
            child: ReceiptAttachmentsField(
              attachments: attachments,
              onChanged: (value) => setState(() => attachments = value),
              onScanReceipt: scanReceipt,
              scanning: scanningReceipt,
            ),
          ),
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: saving ? null : save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.navy,
              ),
              icon: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(saving ? 'SALVANDO...' : 'SALVAR ABASTECIMENTO'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    ),
  );
}

class _OcrLine extends StatelessWidget {
  const _OcrLine(this.label, this.value);

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text('$label: ${value ?? 'Não identificado'}'),
  );
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.vehicle});
  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.navy,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Icon(vehicleTypeIcon(vehicle), color: AppColors.gold),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vehicle.nickname,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${vehicle.brand} ${vehicle.model}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: Color(0xFFE5EAF0)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.blue),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    ),
  );
}
