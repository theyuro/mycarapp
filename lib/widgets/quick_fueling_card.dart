import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/fueling_record.dart';
import '../models/vehicle.dart';
import '../services/fueling_storage_service.dart';
import '../services/vehicle_storage_service.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../screens/fueling_form_screen.dart';

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
  }

  @override
  void dispose() {
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
      showMessage('Cadastre um veículo antes do primeiro abastecimento.');
      return;
    }
    if (liters == null || liters <= 0 || price == null || price <= 0) {
      showMessage('Informe os litros e o valor pago.');
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
          title: 'Abastecimento inadequado',
          message:
              '${liters.toStringAsFixed(2).replaceAll('.', ',')} L informados para um tanque de ${capacity.toStringAsFixed(2).replaceAll('.', ',')} L.',
          category: 'overfill',
        );
      }
      if (!mounted) return;
      litersController.clear();
      priceController.clear();
      showMessage('Abastecimento rápido incluído');
    } catch (_) {
      if (mounted) showMessage('Não foi possível salvar o abastecimento.');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> openCompleteFueling() async {
    final activeVehicle = vehicle;
    if (activeVehicle == null) {
      showMessage('Cadastre um veículo antes do primeiro abastecimento.');
      return;
    }
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => FuelingFormScreen(vehicle: activeVehicle),
      ),
    );
    if (saved == true && mounted) {
      showMessage('Abastecimento incluído');
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
            const Expanded(
              child: Text(
                'Abastecimento rápido',
                style: TextStyle(
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
                decoration: const InputDecoration(
                  labelText: 'Litros',
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
                decoration: const InputDecoration(
                  labelText: 'Valor pago',
                  hintText: '0,00',
                  prefixText: 'R\$ ',
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
            label: const Text('ABASTECIMENTO COMPLETO'),
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
