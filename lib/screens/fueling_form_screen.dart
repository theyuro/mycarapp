import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/establishment.dart';
import '../models/fueling_record.dart';
import '../models/record_attachment.dart';
import '../models/vehicle.dart';
import '../services/ads_service.dart';
import '../services/app_review_service.dart';
import '../services/analytics_service.dart';
import '../services/establishment_storage_service.dart';
import '../services/free_plan_service.dart';
import '../services/fueling_storage_service.dart';
import '../services/image_pick_service.dart';
import '../services/notification_service.dart';
import '../services/receipt_ocr_service.dart';
import '../services/vehicle_storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/establishment_field.dart';
import '../widgets/receipt_attachments_field.dart';
import '../widgets/vehicle_type_icon.dart';
import 'lifetime_purchase_screen.dart';
import '../l10n/l10n.dart';
import '../l10n/labels.dart';

/// Resposta do diálogo de limite do gratuito (vídeo premiado ou Premium).
enum _LimitChoice { watch, premium, cancel }

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
  final storage = FuelingStorageService();
  final vehicleStorage = VehicleStorageService();
  final notificationService = NotificationService();
  final receiptOcr = ReceiptOcrService();
  final establishmentStorage = EstablishmentStorageService();

  late DateTime date;
  late String fuelType;
  bool fullTank = false;
  // Vem do cadastro do veículo; registros antigos mantêm a capacidade salva.
  double? tankCapacityLiters;
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
    if (record == null) {
      AdsService.instance.prepareInterstitial();
      // Gratuito acima da cota do mês: deixa o vídeo premiado carregando.
      unawaited(_preloadRewardedIfNeeded());
    }
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
    } else {
      mileage.text = widget.vehicle.mileage.toString();
    }
    tankCapacityLiters =
        widget.vehicle.tankCapacityLiters ?? record?.tankCapacityLiters;
    if (tankCapacityLiters == null) unawaited(_loadLegacyTankCapacity());
    unawaited(_loadStations());
  }

  Future<void> _loadLegacyTankCapacity() async {
    try {
      final capacity = await storage.lastTankCapacity(widget.vehicle.id);
      if (mounted && capacity != null) {
        setState(() => tankCapacityLiters = capacity);
      }
    } on Object {
      // Sem histórico: o consumo só é calculado após informar no cadastro.
    }
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

  String _editableNumber(double value) => formatInput(value);

  double? _parseNumber(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));

  String? _positiveNumber(String? value) {
    final number = _parseNumber(value ?? '');
    return number == null || number <= 0 ? tr.invalidValue : null;
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
    // Regras do gratuito: só para abastecimento novo, nunca para editar um
    // já salvo.
    if (widget.record == null && !await _checkFreeLimits()) return;
    if (!mounted) return;
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
      tankCapacityLiters: fullTank ? tankCapacityLiters : null,
      gaugeMarkedFull: fullTank && gaugeMarkedFull,
      notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
      attachments: attachments,
    );

    try {
      await storage.saveFueling(record);
      final recordMileage = record.mileage;
      if (recordMileage != null) {
        await vehicleStorage.raiseMileage(widget.vehicle.id, recordMileage);
      }
      final capacity = record.tankCapacityLiters;
      if (capacity != null && record.liters > capacity) {
        await notificationService.addUnique(
          key: 'fuel-overfill-${record.id}',
          title: tr.fuelingOverfillTitle,
          message: tr.fuelingOverfillMessage(
            formatDecimal(record.liters),
            formatDecimal(capacity),
          ),
          category: 'overfill',
        );
      }
      if (widget.record == null) {
        AdsService.instance.registerMainActivity();
        AppReviewService.instance.registerEvent();
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr.fuelingSaveError),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  /// Pré-carrega o vídeo premiado quando o abastecimento novo vai passar da
  /// cota gratuita do mês (mesma contagem de [_checkFreeLimits]).
  Future<void> _preloadRewardedIfNeeded() async {
    final plan = FreePlanService.instance;
    if (!plan.perUseNeedsRewarded) return;
    try {
      final fuelings = await storage.loadFuelings();
      final countThisMonth = plan.countInCurrentMonth(
        fuelings.map((item) => item.date),
      );
      plan.preloadRewardedIf(plan.fuelingNeedsRewarded(countThisMonth));
    } on Object {
      // Sem leitura dos abastecimentos: o vídeo carrega na hora, se pedido.
    }
  }

  /// Regras do plano gratuito para um abastecimento novo: o veículo precisa
  /// aceitar lançamentos novos e, acima da cota mensal, só com vídeo
  /// premiado. Devolve `true` quando pode salvar.
  Future<bool> _checkFreeLimits() async {
    final vehicles = await vehicleStorage.loadVehicles();
    if (!mounted) return false;
    if (!FreePlanService.instance.canRegisterForVehicle(
      vehicles,
      widget.vehicle.id,
    )) {
      await _showVehicleLockedDialog();
      return false;
    }
    final fuelings = await storage.loadFuelings();
    if (!mounted) return false;
    final countThisMonth = FreePlanService.instance.countInCurrentMonth(
      fuelings.map((item) => item.date),
    );
    if (FreePlanService.instance.fuelingWithinFreeQuota(countThisMonth)) {
      return true;
    }
    return _showFuelingLimitDialog(countThisMonth);
  }

  Future<void> _showVehicleLockedDialog() async {
    final seePremium = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr.freeLimitVehicleTitle),
        content: Text(tr.freeLimitVehicleText),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr.learnAboutPremium),
          ),
        ],
      ),
    );
    if (seePremium == true && mounted) {
      await openPremium(context, PremiumFeature.vehicles, 'limit_vehicles');
    }
  }

  Future<bool> _showFuelingLimitDialog(int countThisMonth) async {
    final choice = await showDialog<_LimitChoice>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr.freeLimitFuelingTitle),
        content: Text(tr.freeLimitFuelingText(countThisMonth)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _LimitChoice.cancel),
            child: Text(tr.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _LimitChoice.premium),
            child: Text(tr.learnAboutPremium),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _LimitChoice.watch),
            child: Text(tr.watchAndSave),
          ),
        ],
      ),
    );
    if (choice == _LimitChoice.premium) {
      if (mounted) {
        await openPremium(context, PremiumFeature.fuelings, 'limit_fuelings');
      }
      return false;
    }
    if (choice == _LimitChoice.watch) {
      final earned = await FreePlanService.instance.unlockFuelingWithRewarded();
      if (mounted && !earned) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr.rewardedNotEarned),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return earned;
    }
    return false;
  }

  Future<void> scanReceipt() async {
    if (!FreePlanService.instance.receiptScanAllowed) {
      await openPremium(context, PremiumFeature.receiptScan, 'fueling_form');
      return;
    }
    // Toque em "ler nota fiscal" (antes de abrir a câmera).
    AnalyticsService.tap('scan_receipt', screen: 'fueling_form');
    final photo = await ImagePickService.pick(
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
          SnackBar(
            content: Text(tr.ocrReadError),
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
      title: Text(tr.ocrReviewTitle),
      content: result.hasAnyValue
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _OcrLine(tr.ocrStation, result.station),
                _OcrLine(tr.fuel, fuelLabel(result.fuelType)),
                _OcrLine(
                  tr.ocrFueling,
                  result.liters == null
                      ? null
                      : '${_editableNumber(result.liters!)} L',
                ),
                _OcrLine(
                  tr.ocrTotalPrice,
                  result.totalPrice == null
                      ? null
                      : formatMoney(result.totalPrice!),
                ),
                _OcrLine(
                  tr.date,
                  result.date == null ? null : _formatDate(result.date!),
                ),
                const SizedBox(height: 10),
                Text(tr.ocrReviewHint),
              ],
            )
          : Text(tr.ocrNothing),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(tr.cancel),
        ),
        if (result.hasAnyValue)
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr.ocrFill),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: AppColors.navy,
      foregroundColor: Colors.white,
      title: Text(widget.record == null ? tr.fuelingNew : tr.fuelingEdit),
    ),
    body: Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoBanner(vehicle: widget.vehicle),
          const SizedBox(height: 16),
          _FormCard(
            title: tr.fuelingData,
            icon: Icons.local_gas_station_rounded,
            child: Column(
              children: [
                InkWell(
                  onTap: selectDate,
                  borderRadius: BorderRadius.circular(14),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: tr.date,
                      suffixIcon: const Icon(Icons.calendar_month_outlined),
                    ),
                    child: Text(_formatDate(date)),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: fuelType,
                  decoration: InputDecoration(labelText: tr.fuel),
                  items: fuelTypes
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(valueLabel(item)),
                        ),
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
                        decoration: InputDecoration(
                          labelText: tr.liters,
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
                        decoration: InputDecoration(
                          labelText: tr.totalValue,
                          prefixText: '$currencySymbol ',
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
                  decoration: InputDecoration(
                    labelText: tr.mileage,
                    suffixText: 'km',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return fullTank && gaugeMarkedFull
                          ? tr.fuelingMileageRequired
                          : null;
                    }
                    return int.tryParse(value) == null
                        ? tr.fuelingMileageInvalid
                        : null;
                  },
                ),
                const SizedBox(height: 6),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(tr.fullTank),
                  subtitle: Text(tr.fuelingFullTankHint),
                  value: fullTank,
                  activeThumbColor: AppColors.blue,
                  onChanged: (value) => setState(() {
                    fullTank = value;
                    if (!value) gaugeMarkedFull = false;
                  }),
                ),
                if (fullTank) ...[
                  if (tankCapacityLiters == null) ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tr.tankCapacityMissing,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(tr.fuelingGaugeFull),
                    subtitle: Text(tr.fuelingGaugeFullHint),
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
            title: tr.optionalInfo,
            icon: Icons.notes_rounded,
            child: Column(
              children: [
                EstablishmentField(
                  key: ValueKey(establishmentFieldGeneration),
                  label: tr.placeTypeStation,
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
                  decoration: InputDecoration(labelText: tr.notes),
                ),
              ],
            ),
          ),
          _FormCard(
            title: tr.receiptsSection,
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
              label: Text(saving ? tr.saving : tr.fuelingSave),
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
    child: Text('$label: ${value ?? tr.notIdentified}'),
  );
}

String _formatDate(DateTime date) => formatDate(date);

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
