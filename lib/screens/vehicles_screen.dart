import 'dart:io';

import 'package:flutter/material.dart';

import '../models/vehicle.dart';
import '../services/access_service.dart';
import '../services/vehicle_storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/vehicle_type_icon.dart';
import 'vehicle_registration_screen.dart';
import 'lifetime_purchase_screen.dart';

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
      showMessage('Não foi possível carregar os veículos.');
    }
  }

  Future<void> openForm([Vehicle? vehicle]) async {
    if (vehicle == null &&
        vehicles.isNotEmpty &&
        !AccessService.instance.subscriptionActive) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => const SubscriptionScreen()),
      );
      return;
    }
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => VehicleRegistrationScreen(vehicle: vehicle),
      ),
    );
    if (changed == true) {
      await loadVehicles();
      if (mounted && vehicle == null) {
        showMessage('Veículo incluído', oneSecond: true);
      }
    }
  }

  Future<void> selectVehicle(Vehicle vehicle) async {
    await storage.setActiveVehicle(vehicle.id);
    if (!mounted) return;
    setState(() => activeId = vehicle.id);
    showMessage('${vehicle.nickname} é o veículo ativo.');
  }

  Future<void> confirmDelete(Vehicle vehicle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir veículo?'),
        content: Text(
          'O cadastro e as fotos de ${vehicle.nickname} serão apagados do aparelho. Os abastecimentos já registrados serão preservados.',
        ),
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
    try {
      await storage.deleteVehicle(vehicle.id);
      await loadVehicles();
      if (mounted) showMessage('Veículo excluído.');
    } catch (_) {
      if (mounted) showMessage('Não foi possível excluir o veículo.');
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
      title: const Text('Meus veículos'),
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => openForm(),
      backgroundColor: AppColors.gold,
      foregroundColor: AppColors.navy,
      icon: const Icon(Icons.add),
      label: Text(
        vehicles.isNotEmpty && !AccessService.instance.subscriptionActive
            ? 'MAIS VEÍCULOS · PREMIUM'
            : 'NOVO VEÍCULO',
      ),
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : vehicles.isEmpty
        ? _EmptyVehicles(onAdd: () => openForm())
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
            itemCount: vehicles.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, index) {
              final vehicle = vehicles[index];
              return _VehicleCard(
                vehicle: vehicle,
                isActive: vehicle.id == activeId,
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
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  final Vehicle vehicle;
  final bool isActive;
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
                    '${vehicle.mileage} km • ${vehicle.fuel} • ${vehicle.transmission}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (!isActive)
                        TextButton(
                          onPressed: onSelect,
                          child: const Text('USAR ESTE'),
                        ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Editar',
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Excluir',
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
          const Text(
            'Nenhum veículo cadastrado',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cadastre seu primeiro carro ou moto para começar a registrar abastecimentos.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('CADASTRAR VEÍCULO'),
          ),
        ],
      ),
    ),
  );
}
