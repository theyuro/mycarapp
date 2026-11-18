import 'dart:io';

import 'package:flutter/material.dart';

import '../models/vehicle.dart';
import '../services/free_plan_service.dart';
import '../services/premium_upsell_service.dart';
import '../services/vehicle_storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/free_user_banner_ad.dart';
import '../widgets/premium_upsell_banner.dart';
import '../widgets/vehicle_type_icon.dart';
import 'lifetime_purchase_screen.dart';
import 'vehicle_registration_screen.dart';
import '../l10n/l10n.dart';
import '../l10n/labels.dart';

class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  final storage = VehicleStorageService();
  List<Vehicle> vehicles = const [];
  String? activeId;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadVehicles();
  }

  Future<void> loadVehicles() async {
    try {
      final loaded = await storage.loadVehicles();
      final active = await storage.loadActiveVehicle();
      if (!mounted) return;
      setState(() {
        vehicles = loaded;
        activeId = active?.id;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
      showMessage(tr.vehiclesLoadError);
    }
  }

  Future<void> openForm([Vehicle? vehicle]) async {
    // Limite de veículos do gratuito: só para cadastro novo, nunca para
    // editar um já existente.
    if (vehicle == null &&
        !FreePlanService.instance.canAddVehicle(vehicles.length)) {
      await openPremium(context, PremiumFeature.vehicles, 'limit_vehicles');
      return;
    }
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => VehicleRegistrationScreen(vehicle: vehicle),
        settings: const RouteSettings(name: 'vehicle_form'),
      ),
    );
    if (changed == true) {
      await loadVehicles();
      if (mounted && vehicle == null) {
        showMessage(tr.vehicleAdded, oneSecond: true);
      }
    }
  }

  Future<void> selectVehicle(Vehicle vehicle) async {
    await storage.setActiveVehicle(vehicle.id);
    if (!mounted) return;
    setState(() => activeId = vehicle.id);
    showMessage(tr.vehicleNowActive(vehicle.nickname));
  }

  Future<void> confirmDelete(Vehicle vehicle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr.vehicleDeleteTitle),
        content: Text(tr.vehicleDeleteText(vehicle.nickname)),
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
    try {
      await storage.deleteVehicle(vehicle.id);
      await loadVehicles();
      if (mounted) showMessage(tr.vehicleDeleted);
    } catch (_) {
      if (mounted) showMessage(tr.vehicleDeleteError);
    }
  }

  void showMessage(String message, {bool oneSecond = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: oneSecond
            ? const Duration(seconds: 1)
            : const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: AppColors.navy,
      foregroundColor: Colors.white,
      title: Text(tr.vehiclesTitle),
    ),
    // Anúncio no rodapé; o FAB flutua acima dele, com folga.
    bottomNavigationBar: const SafeArea(
      top: false,
      child: FreeUserBannerAd(placement: BannerPlacement.vehicles),
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => openForm(),
      backgroundColor: AppColors.gold,
      foregroundColor: AppColors.navy,
      icon: const Icon(Icons.add),
      label: Text(tr.newVehicle),
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : vehicles.isEmpty
        ? _EmptyVehicles(onAdd: () => openForm())
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
            itemCount: vehicles.length + 1,
            separatorBuilder: (_, index) =>
                SizedBox(height: index == 0 ? 0 : 12),
            itemBuilder: (_, index) {
              if (index == 0) {
                return const PremiumUpsellBanner(
                  placement: UpsellPlacement.vehicles,
                );
              }
              final vehicle = vehicles[index - 1];
              return _VehicleCard(
                vehicle: vehicle,
                isActive: vehicle.id == activeId,
                canRegister: FreePlanService.instance.canRegisterForVehicle(
                  vehicles,
                  vehicle.id,
                ),
                onSelect: () => selectVehicle(vehicle),
                onEdit: () => openForm(vehicle),
                onDelete: () => confirmDelete(vehicle),
              );
            },
          ),
  );
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.vehicle,
    required this.isActive,
    required this.canRegister,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  final Vehicle vehicle;
  final bool isActive;

  /// No gratuito, só o veículo cadastrado primeiro aceita lançamentos novos
  /// quando há mais de um cadastrado; os demais ficam só para consulta.
  final bool canRegister;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(
        color: isActive ? AppColors.gold : const Color(0xFFE1E7EE),
        width: isActive ? 1.5 : 1,
      ),
    ),
    child: InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _VehicleImage(vehicle: vehicle),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          vehicle.nickname,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      if (isActive)
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.gold,
                          size: 21,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${vehicle.typeLabel} • ${vehicle.brand} ${vehicle.model} • ${vehicle.year}',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${vehicle.mileage} km • ${valueLabel(vehicle.fuel)} • ${valueLabel(vehicle.transmission)}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  if (!canRegister) ...[
                    const SizedBox(height: 8),
                    _ViewOnlyNotice(
                      onTap: () => openPremium(
                        context,
                        PremiumFeature.vehicles,
                        'limit_vehicles',
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (!isActive)
                        TextButton(
                          onPressed: onSelect,
                          child: Text(tr.useThis),
                        ),
                      const Spacer(),
                      IconButton(
                        tooltip: tr.edit,
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: tr.delete,
                        onPressed: onDelete,
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Aviso de que este veículo não aceita lançamentos novos no gratuito (ver
/// FreePlanService.canRegisterForVehicle).
class _ViewOnlyNotice extends StatelessWidget {
  const _ViewOnlyNotice({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.orange.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        const Icon(Icons.visibility_outlined, color: Colors.orange, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            tr.vehicleViewOnlyBadge,
            style: const TextStyle(
              color: Colors.orange,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: Size.zero,
          ),
          child: Text(tr.learnAboutPremium, style: const TextStyle(fontSize: 11.5)),
        ),
      ],
    ),
  );
}

class _VehicleImage extends StatelessWidget {
  const _VehicleImage({required this.vehicle});
  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final photo = vehicle.photos.isEmpty ? null : vehicle.photos.first;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 78,
        height: 96,
        child: photo == null
            ? ColoredBox(
                color: AppColors.background,
                child: Icon(
                  vehicleTypeIcon(vehicle),
                  color: AppColors.blue,
                  size: 38,
                ),
              )
            : Image.file(
                File(photo.path),
                fit: BoxFit.cover,
                cacheWidth: (78 * pixelRatio).ceil(),
                cacheHeight: (96 * pixelRatio).ceil(),
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: AppColors.background,
                  child: Icon(Icons.broken_image_outlined),
                ),
              ),
      ),
    );
  }
}

class _EmptyVehicles extends StatelessWidget {
  const _EmptyVehicles({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.garage_outlined, size: 72, color: AppColors.blue),
          const SizedBox(height: 18),
          Text(
            tr.vehiclesEmptyTitle,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            tr.vehiclesEmptyText,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text(tr.addVehicle),
          ),
        ],
      ),
    ),
  );
}
