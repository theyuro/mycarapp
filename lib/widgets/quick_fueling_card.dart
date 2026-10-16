import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/fueling_record.dart';
import '../models/vehicle.dart';
import '../services/ads_service.dart';
import '../services/fueling_storage_service.dart';
import '../services/vehicle_storage_service.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../screens/fueling_form_screen.dart';
import '../l10n/l10n.dart';

class QuickFuelingCard extends StatefulWidget {
  const QuickFuelingCard({super.key});

  @override
  State<QuickFuelingCard> createState() => _QuickFuelingCardState();
}

class _QuickFuelingCardState extends State<QuickFuelingCard> {
  final litersController = TextEditingController();
  final priceController = TextEditingController();
  final vehicleStorage = VehicleStorageService();
  final fuelingStorage = FuelingStorageService();
  final notificationService = NotificationService();
  Vehicle? vehicle;
  bool loadingVehicle = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    loadVehicle();
    litersController.addListener(_prepareInterstitial);
  }

  // O card fica na tela inicial: o intersticial só é pré-carregado quando o
  // usuário começa a digitar, não a cada abertura do app.
  void _prepareInterstitial() {
    if (litersController.text.isEmpty) return;
    litersController.removeListener(_prepareInterstitial);
    AdsService.instance.prepareInterstitial();
  }

  @override
  void dispose() {
    litersController.removeListener(_prepareInterstitial);
    litersController.dispose();
    priceController.dispose();
    super.dispose();
  }

  Future<void> loadVehicle() async {
    try {
      final activeVehicle = await vehicleStorage.loadActiveVehicle();
      if (!mounted) return;
      setState(() {
        vehicle = activeVehicle;
        loadingVehicle = false;
      });
    } catch (_) {
      if (mounted) setState(() => loadingVehicle = false);
    }
  }

  double? parseNumber(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));

  Future<void> addFueling() async {
    FocusScope.of(context).unfocus();
    final liters = parseNumber(litersController.text);
    final price = parseNumber(priceController.text);

    if (vehicle == null) {
      showMessage(tr.fuelingNeedVehicle);
      return;
    }
    if (liters == null || liters <= 0 || price == null || price <= 0) {
      showMessage(tr.fuelingNeedLitersAndPrice);
      return;
    }

    setState(() => saving = true);
    final now = DateTime.now();
    final record = FuelingRecord(
      id: '${now.microsecondsSinceEpoch}',
      vehicleId: vehicle!.id,
      liters: liters,
      totalPrice: price,
      date: now,
    );

    try {
      await fuelingStorage.addFueling(record);
      final previous = await fuelingStorage.loadFuelings();
      final capacities =
          previous
              .where(
                (item) =>
                    item.vehicleId == vehicle!.id &&
                    item.id != record.id &&
                    item.tankCapacityLiters != null,
              )
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));
      final capacity = capacities.isEmpty
          ? null
          : capacities.first.tankCapacityLiters;
      if (capacity != null && liters > capacity) {
        await notificationService.addUnique(
          key: 'fuel-overfill-${record.id}',
          title: tr.fuelingOverfillTitle,
          message: tr.fuelingOverfillMessage(
            formatDecimal(liters),
            formatDecimal(capacity),
          ),
          category: 'overfill',
        );
      }
      if (!mounted) return;
      litersController.clear();
      priceController.clear();
      showMessage(tr.quickFuelingAdded);
      AdsService.instance.registerMainActivity();
      // Volta a observar o campo para o próximo abastecimento rápido.
      litersController
        ..removeListener(_prepareInterstitial)
        ..addListener(_prepareInterstitial);
    } catch (_) {
      if (mounted) showMessage(tr.fuelingSaveError);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> openCompleteFueling() async {
    final activeVehicle = vehicle;
    if (activeVehicle == null) {
      showMessage(tr.fuelingNeedVehicle);
      return;
    }
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => FuelingFormScreen(vehicle: activeVehicle),
      ),
    );
    if (saved == true && mounted) {
      showMessage(tr.fuelingAdded);
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.gold.withValues(alpha: .5)),
      boxShadow: [
        BoxShadow(
          color: AppColors.navy.withValues(alpha: .06),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.goldLight,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.local_gas_station_rounded,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                tr.quickFuelingTitle,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
            ),
            if (loadingVehicle)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (vehicle != null)
              Flexible(
                child: Text(
                  vehicle!.nickname,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: litersController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                ],
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: tr.liters,
                  hintText: '0,00',
                  suffixText: 'L',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                ],
                onSubmitted: (_) => addFueling(),
                decoration: InputDecoration(
                  labelText: tr.amountPaid,
                  hintText: '0,00',
                  prefixText: '$currencySymbol ',
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 52,
              height: 52,
              child: FilledButton(
                onPressed: saving || loadingVehicle ? null : addFueling,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.navy,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: saving
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_rounded, size: 29),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: loadingVehicle ? null : openCompleteFueling,
            icon: const Icon(Icons.post_add_rounded),
            label: Text(tr.fullFueling),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.blue,
              side: BorderSide(color: AppColors.blue.withValues(alpha: .35)),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
