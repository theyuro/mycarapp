import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/establishment.dart';
import '../models/maintenance_record.dart';
import '../models/record_attachment.dart';
import '../models/vehicle.dart';
import '../services/access_service.dart';
import '../services/ads_service.dart';
import '../services/app_review_service.dart';
import '../services/establishment_storage_service.dart';
import '../services/free_plan_service.dart';
import '../services/maintenance_storage_service.dart';
import '../services/calendar_service.dart';
import '../services/notification_service.dart';
import '../services/vehicle_storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/vehicle_type_icon.dart';
import '../widgets/establishment_field.dart';
import '../widgets/receipt_attachments_field.dart';
import 'lifetime_purchase_screen.dart';
import '../l10n/l10n.dart';
import '../l10n/labels.dart';

/// Resposta do diálogo de limite do gratuito (vídeo premiado ou Premium).
enum _LimitChoice { watch, premium, cancel }

class MaintenanceFormScreen extends StatefulWidget {
  const MaintenanceFormScreen({
    super.key,
    required this.vehicle,
    this.record,
    this.initialCompleted = true,
  });

  final Vehicle vehicle;
  final MaintenanceRecord? record;
  final bool initialCompleted;

  @override
  State<MaintenanceFormScreen> createState() => _MaintenanceFormScreenState();
}

class _MaintenanceFormScreenState extends State<MaintenanceFormScreen> {
  static const categories = [
    'Óleo e filtros',
    'Motor',
    'Freios',
    'Suspensão',
    'Pneus',
    'Câmbio',
    'Ar-condicionado',
    'Elétrica',
    'Direção',
    'Correias',
    'Revisão',
    'Outros',
  ];

  final formKey = GlobalKey<FormState>();
  final service = TextEditingController();
  final mileage = TextEditingController();
  final laborCost = TextEditingController();
  final partsCost = TextEditingController();
  final notes = TextEditingController();
  final nextMileage = TextEditingController();
  final storage = MaintenanceStorageService();
  final calendar = CalendarService();
  final notificationService = NotificationService();
  final establishmentStorage = EstablishmentStorageService();
  final vehicleStorage = VehicleStorageService();

  late String category;
  late DateTime date;
  DateTime? nextDate;
  bool saving = false;
  late bool isCompleted;
  bool addToCalendar = false;
  List<RecordAttachment> attachments = const [];

  String workshopText = '';
  String? establishmentId;
  int establishmentFieldGeneration = 0;
  List<Establishment> workshops = const [];
  List<String> recentWorkshopIds = const [];

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    if (record == null) {
      AdsService.instance.prepareInterstitial();
      // Gratuito: toda manutenção nova pede vídeo; já deixa carregando.
      FreePlanService.instance.preloadRewardedIf(
        FreePlanService.instance.perUseNeedsRewarded,
      );
    }
    isCompleted = record?.isCompleted ?? widget.initialCompleted;
    category = record?.category ?? categories.first;
    if (!categories.contains(category)) category = categories.last;
    date =
        record?.date ??
        (isCompleted
            ? DateTime.now()
            : DateTime.now().add(const Duration(days: 30)));
    nextDate = record?.nextDate;
    service.text = record?.service ?? '';
    mileage.text = record != null
        ? (record.mileage == 0 ? '' : record.mileage.toString())
        : (isCompleted ? widget.vehicle.mileage.toString() : '');
    workshopText = record?.workshop ?? '';
    establishmentId = record?.establishmentId;
    laborCost.text = _editableCost(record?.laborCost);
    partsCost.text = _editableCost(record?.partsCost);
    notes.text = record?.notes ?? '';
    nextMileage.text = record?.nextMileage?.toString() ?? '';
    attachments = [...?record?.attachments];
    unawaited(_loadWorkshops());
  }

  Future<void> _loadWorkshops() async {
    try {
      final results = await Future.wait([
        establishmentStorage.loadActiveEstablishments(
          type: EstablishmentType.oficina,
        ),
        storage.loadMaintenances(),
      ]);
      final establishments = results[0] as List<Establishment>;
      final maintenances = results[1] as List<MaintenanceRecord>;
      final usage = <String, int>{};
      final lastUsed = <String, DateTime>{};
      for (final item in maintenances) {
        final id = item.establishmentId;
        if (id == null || item.vehicleId != widget.vehicle.id) continue;
        usage[id] = (usage[id] ?? 0) + 1;
        final current = lastUsed[id];
        if (current == null || item.date.isAfter(current)) {
          lastUsed[id] = item.date;
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
        workshops = establishments;
        recentWorkshopIds = recent.take(3).toList();
      });
    } on Object {
      // Sem oficinas cadastradas ainda: o campo funciona como texto livre.
    }
  }

  String _editableCost(double? value) =>
      value == null || value == 0 ? '' : formatInput(value);

  double? _parseCost(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));

  Future<void> pickDate({required bool next}) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: next ? (nextDate ?? DateTime.now()) : date,
      firstDate: next || !isCompleted ? DateTime.now() : DateTime(1980),
      lastDate: next || !isCompleted ? DateTime(2100) : DateTime.now(),
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (next) {
        nextDate = selected;
      } else {
        date = selected;
      }
    });
  }

  String? validateCost(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = _parseCost(value);
    return parsed == null || parsed < 0 ? tr.invalidValueShort : null;
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    // Regras do gratuito: só para registro novo, nunca para editar um já
    // salvo.
    if (widget.record == null && !await _checkFreeLimits()) return;
    if (!mounted) return;
    setState(() => saving = true);
    final now = DateTime.now();
    final record = MaintenanceRecord(
      id: widget.record?.id ?? '${now.microsecondsSinceEpoch}',
      vehicleId: widget.vehicle.id,
      service: service.text.trim(),
      category: category,
      date: date,
      mileage: int.tryParse(mileage.text) ?? 0,
      workshop: workshopText.trim().isEmpty ? null : workshopText.trim(),
      establishmentId: establishmentId,
      laborCost: _parseCost(laborCost.text) ?? 0,
      partsCost: _parseCost(partsCost.text) ?? 0,
      notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
      nextMileage: nextMileage.text.trim().isEmpty
          ? null
          : int.parse(nextMileage.text),
      nextDate: nextDate,
      isCompleted: isCompleted,
      attachments: attachments,
    );
    try {
      await storage.saveMaintenance(record);
    } on Object catch (error, stackTrace) {
      debugPrint('Erro ao salvar manutenção: $error\n$stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr.maintSaveError)));
      setState(() => saving = false);
      return;
    }

    final calendarDate = isCompleted ? nextDate : date;
    var reminderWarning = false;
    if (calendarDate != null) {
      try {
        await notificationService.scheduleMaintenance(
          id: record.id,
          date: calendarDate,
          service: record.service,
        );
      } on Object catch (error, stackTrace) {
        reminderWarning = true;
        debugPrint('Erro ao agendar lembrete: $error\n$stackTrace');
      }
    }
    if (addToCalendar && calendarDate != null) {
      try {
        await calendar.addAllDayMaintenance(
          date: calendarDate,
          service: record.service,
          category: valueLabel(record.category),
        );
      } on Object catch (error, stackTrace) {
        reminderWarning = true;
        debugPrint('Erro ao abrir agenda: $error\n$stackTrace');
      }
    }
    if (widget.record == null) {
      AdsService.instance.registerMainActivity();
      AppReviewService.instance.registerEvent();
    }
    if (!mounted) return;
    if (reminderWarning) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr.maintSavedCalendarError)));
    }
    Navigator.of(context).pop(true);
  }

  /// Regras do plano gratuito para uma manutenção nova: o veículo precisa
  /// aceitar lançamentos novos e, sem Premium, cada registro novo é liberado
  /// por vídeo premiado. Devolve `true` quando pode salvar.
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
    if (AccessService.instance.premiumUnlocked) return true;
    return _showMaintenanceLimitDialog();
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

  Future<bool> _showMaintenanceLimitDialog() async {
    final choice = await showDialog<_LimitChoice>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr.freeLimitMaintenanceTitle),
        content: Text(tr.freeLimitMaintenanceText),
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
        await openPremium(
          context,
          PremiumFeature.maintenance,
          'limit_maintenance',
        );
      }
      return false;
    }
    if (choice == _LimitChoice.watch) {
      final earned =
          await FreePlanService.instance.unlockMaintenanceWithRewarded();
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

  @override
  void dispose() {
    service.dispose();
    mileage.dispose();
    laborCost.dispose();
    partsCost.dispose();
    notes.dispose();
    nextMileage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: AppColors.navy,
      foregroundColor: Colors.white,
      title: Text(
        widget.record == null
            ? (isCompleted ? tr.maintDone : tr.maintNext)
            : tr.maintEdit,
      ),
    ),
    body: Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _VehicleBanner(vehicle: widget.vehicle),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: true,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(tr.maintDoneShort),
              ),
              ButtonSegment(
                value: false,
                icon: const Icon(Icons.event_outlined),
                label: Text(tr.maintUpcoming),
              ),
            ],
            selected: {isCompleted},
            onSelectionChanged: widget.record == null
                ? (value) => setState(() {
                    isCompleted = value.first;
                    date = isCompleted
                        ? DateTime.now()
                        : DateTime.now().add(const Duration(days: 30));
                  })
                : null,
          ),
          const SizedBox(height: 16),
          _Section(
            icon: Icons.build_circle_outlined,
            title: isCompleted ? tr.maintServiceDone : tr.maintServicePlanned,
            child: Column(
              children: [
                TextFormField(
                  controller: service,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: tr.maintServiceDescription,
                    hintText: tr.maintServiceExample,
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? tr.maintServiceRequired
                      : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: InputDecoration(labelText: tr.category),
                  items: categories
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(valueLabel(item)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => category = value!),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _DateField(
                        label: isCompleted
                            ? tr.maintDateDone
                            : tr.maintDatePlanned,
                        date: date,
                        onTap: () => pickDate(next: false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: mileage,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: isCompleted
                              ? tr.mileage
                              : tr.maintKmPlanned,
                          suffixText: 'km',
                        ),
                        validator: (value) {
                          if (!isCompleted &&
                              (value == null || value.trim().isEmpty)) {
                            return null;
                          }
                          final parsed = int.tryParse(value ?? '');
                          if (parsed == null) return tr.maintKmRequired;
                          if (!isCompleted &&
                              parsed <= widget.vehicle.mileage) {
                            return tr.maintKmGreater;
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                if (isCompleted) ...[
                  const SizedBox(height: 14),
                  EstablishmentField(
                    key: ValueKey(establishmentFieldGeneration),
                    label: tr.maintShop,
                    type: EstablishmentType.oficina,
                    establishments: workshops,
                    recentIds: recentWorkshopIds,
                    initialText: workshopText,
                    initialEstablishmentId: establishmentId,
                    onTextChanged: (value) => workshopText = value,
                    onEstablishmentSelected: (value) =>
                        establishmentId = value?.id,
                    onCreateEstablishment: (name) async {
                      final created = await establishmentStorage.createQuick(
                        name: name,
                        type: EstablishmentType.oficina,
                      );
                      if (mounted) {
                        setState(() => workshops = [...workshops, created]);
                      }
                      return created;
                    },
                  ),
                ],
              ],
            ),
          ),
          if (isCompleted)
            _Section(
              icon: Icons.payments_outlined,
              title: tr.maintCosts,
              child: Row(
                children: [
                  Expanded(
                    child: _CostField(
                      controller: laborCost,
                      label: tr.maintLabor,
                      validator: validateCost,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CostField(
                      controller: partsCost,
                      label: tr.maintParts,
                      validator: validateCost,
                    ),
                  ),
                ],
              ),
            ),
          if (isCompleted)
            _Section(
              icon: Icons.event_repeat_rounded,
              title: tr.maintNext,
              child: Column(
                children: [
                  TextFormField(
                    controller: nextMileage,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: tr.maintNextKm,
                      suffixText: 'km',
                    ),
                  ),
                  const SizedBox(height: 14),
                  _DateField(
                    label: tr.maintNextDate,
                    date: nextDate,
                    onTap: () => pickDate(next: true),
                    onClear: nextDate == null
                        ? null
                        : () => setState(() => nextDate = null),
                  ),
                ],
              ),
            ),
          if (!isCompleted || nextDate != null)
            _Section(
              icon: Icons.calendar_month_outlined,
              title: tr.maintCalendar,
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: addToCalendar,
                activeThumbColor: AppColors.blue,
                onChanged: (value) => setState(() => addToCalendar = value),
                title: Text(tr.maintAddToCalendar),
                subtitle: Text(tr.maintCalendarHint),
              ),
            ),
          _Section(
            icon: Icons.receipt_long_outlined,
            title: tr.receiptsSection,
            child: ReceiptAttachmentsField(
              attachments: attachments,
              onChanged: (value) => setState(() => attachments = value),
            ),
          ),
          _Section(
            icon: Icons.notes_rounded,
            title: tr.notes,
            child: TextFormField(
              controller: notes,
              textCapitalization: TextCapitalization.sentences,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(hintText: tr.maintNotesHint),
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
              icon: const Icon(Icons.save_outlined),
              label: Text(
                saving
                    ? tr.saving
                    : isCompleted
                    ? tr.maintSave
                    : tr.maintSaveNext,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    ),
  );
}

class _CostField extends StatelessWidget {
  const _CostField({
    required this.controller,
    required this.label,
    required this.validator,
  });
  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
    decoration: InputDecoration(
      labelText: label,
      prefixText: '$currencySymbol ',
    ),
    validator: validator,
  );
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
    this.onClear,
  });
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: onClear == null
            ? const Icon(Icons.calendar_month_outlined)
            : IconButton(onPressed: onClear, icon: const Icon(Icons.close)),
      ),
      child: Text(date == null ? tr.notSetFem : _date(date!)),
    ),
  );
}

class _VehicleBanner extends StatelessWidget {
  const _VehicleBanner({required this.vehicle});
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
        Text(
          vehicle.nickname,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.child,
  });
  final IconData icon;
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    elevation: 0,
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

String _date(DateTime value) => formatDate(value);
