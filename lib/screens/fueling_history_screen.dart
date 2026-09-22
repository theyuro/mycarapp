import 'package:flutter/material.dart';

import '../models/fueling_record.dart';
import '../models/vehicle.dart';
import '../services/fueling_storage_service.dart';
import '../services/vehicle_storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/vehicle_type_icon.dart';
import 'fueling_form_screen.dart';

class FuelingHistoryScreen extends StatefulWidget {
  const FuelingHistoryScreen({super.key});

  @override
  State<FuelingHistoryScreen> createState() => _FuelingHistoryScreenState();
}

class _FuelingHistoryScreenState extends State<FuelingHistoryScreen> {
  final vehicleStorage = VehicleStorageService();
  final fuelingStorage = FuelingStorageService();
  Vehicle? vehicle;
  List<FuelingRecord> records = const [];
  Map<String, double> consumptionByRecord = const {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    try {
      final activeVehicle = await vehicleStorage.loadActiveVehicle();
      final allRecords = await fuelingStorage.loadFuelings();
      final vehicleRecords =
          activeVehicle == null
                ? <FuelingRecord>[]
                : allRecords
                      .where((record) => record.vehicleId == activeVehicle.id)
                      .toList()
            ..sort((a, b) => b.date.compareTo(a.date));
      if (!mounted) return;
      setState(() {
        vehicle = activeVehicle;
        records = vehicleRecords;
        consumptionByRecord = _calculateConsumption(vehicleRecords);
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
      showMessage('Não foi possível carregar o histórico.');
    }
  }

  Map<String, double> _calculateConsumption(List<FuelingRecord> source) {
    final chronological = [...source]..sort((a, b) => a.date.compareTo(b.date));
    final result = <String, double>{};
    int? previousFullMileage;
    double accumulatedLiters = 0;

    for (final record in chronological) {
      if (previousFullMileage != null) accumulatedLiters += record.liters;
      if (!record.fullTank ||
          !record.gaugeMarkedFull ||
          record.tankCapacityLiters == null ||
          record.mileage == null) {
        continue;
      }
      if (previousFullMileage != null &&
          record.mileage! > previousFullMileage &&
          accumulatedLiters > 0) {
        result[record.id] =
            (record.mileage! - previousFullMileage) / accumulatedLiters;
      }
      previousFullMileage = record.mileage;
      accumulatedLiters = 0;
    }
    return result;
  }

  Future<void> openForm([FuelingRecord? record]) async {
    final currentVehicle = vehicle;
    if (currentVehicle == null) {
      showMessage('Cadastre e selecione um veículo primeiro.');
      return;
    }
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            FuelingFormScreen(vehicle: currentVehicle, record: record),
      ),
    );
    if (changed == true) {
      await loadHistory();
      if (mounted && record == null) {
        showMessage('Abastecimento incluído', oneSecond: true);
      }
    }
  }

  Future<void> confirmDelete(FuelingRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir abastecimento?'),
        content: Text(
          'O registro de ${_formatDate(record.date)} será removido permanentemente.',
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
      await fuelingStorage.deleteFueling(record.id);
      await loadHistory();
      if (mounted) showMessage('Abastecimento excluído.');
    } catch (_) {
      if (mounted) showMessage('Não foi possível excluir o abastecimento.');
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
      title: const Text('Histórico de abastecimentos'),
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: vehicle == null ? null : () => openForm(),
      backgroundColor: AppColors.gold,
      foregroundColor: AppColors.navy,
      icon: const Icon(Icons.add),
      label: const Text('ABASTECER'),
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : vehicle == null
        ? const _NoVehicle()
        : RefreshIndicator(
            onRefresh: loadHistory,
            child: records.isEmpty
                ? _EmptyHistory(vehicle: vehicle!, onAdd: () => openForm())
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: records.length + 2,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _VehicleHeader(vehicle: vehicle!);
                      }
                      if (index == 1) {
                        return _HistorySummary(records: records);
                      }
                      final recordIndex = index - 2;
                      final record = records[recordIndex];
                      final showMonth =
                          recordIndex == 0 ||
                          !_sameMonth(
                            record.date,
                            records[recordIndex - 1].date,
                          );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showMonth) _MonthHeader(date: record.date),
                          _FuelingCard(
                            record: record,
                            consumption: consumptionByRecord[record.id],
                            onEdit: () => openForm(record),
                            onDelete: () => confirmDelete(record),
                          ),
                        ],
                      );
                    },
                  ),
          ),
  );
}

class _VehicleHeader extends StatelessWidget {
  const _VehicleHeader({required this.vehicle});
  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [AppColors.navy, AppColors.blue]),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        Icon(vehicleTypeIcon(vehicle), color: AppColors.gold, size: 34),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vehicle.nickname,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${vehicle.brand} ${vehicle.model} • ${vehicle.year}',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _HistorySummary extends StatelessWidget {
  const _HistorySummary({required this.records});
  final List<FuelingRecord> records;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final thisMonth = records.where(
      (record) =>
          record.date.year == now.year && record.date.month == now.month,
    );
    final monthTotal = thisMonth.fold<double>(
      0,
      (total, record) => total + record.totalPrice,
    );
    final totalLiters = records.fold<double>(
      0,
      (total, record) => total + record.liters,
    );
    final totalSpent = records.fold<double>(
      0,
      (total, record) => total + record.totalPrice,
    );
    final averagePrice = totalLiters == 0 ? 0.0 : totalSpent / totalLiters;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.8,
      children: [
        _SummaryTile(
          label: 'Gasto no mês',
          value: _currency(monthTotal),
          icon: Icons.payments_outlined,
        ),
        _SummaryTile(
          label: 'Preço médio',
          value: '${_currency(averagePrice)}/L',
          icon: Icons.show_chart_rounded,
        ),
        _SummaryTile(
          label: 'Total abastecido',
          value: '${_decimal(totalLiters)} L',
          icon: Icons.local_gas_station_outlined,
        ),
        _SummaryTile(
          label: 'Registros',
          value: '${records.length}',
          icon: Icons.receipt_long_outlined,
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: const Color(0xFFE1E7EE)),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.blue, size: 24),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 24, 2, 10),
    child: Text(
      '${_monthName(date.month).toUpperCase()} ${date.year}',
      style: const TextStyle(
        color: AppColors.muted,
        fontSize: 13,
        fontWeight: FontWeight.w800,
        letterSpacing: .7,
      ),
    ),
  );
}

class _FuelingCard extends StatelessWidget {
  const _FuelingCard({
    required this.record,
    required this.onEdit,
    required this.onDelete,
    this.consumption,
  });
  final FuelingRecord record;
  final double? consumption;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(17),
      side: const BorderSide(color: Color(0xFFE1E7EE)),
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(15, 14, 8, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.goldLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_gas_station_rounded,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        record.fuelType ?? 'Combustível',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      _currency(record.totalPrice),
                      style: const TextStyle(
                        color: AppColors.blue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  '${_formatDate(record.date)} • ${_decimal(record.liters)} L • ${_currency(record.pricePerLiter)}/L',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                if (record.mileage != null || record.station != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    [
                      if (record.mileage != null) '${record.mileage} km',
                      if (record.station != null) record.station!,
                    ].join(' • '),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (record.fullTank || consumption != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (record.fullTank)
                        const _Tag(
                          icon: Icons.water_drop_outlined,
                          label: 'Tanque cheio',
                        ),
                      if (consumption != null)
                        _Tag(
                          icon: Icons.speed_rounded,
                          label: '${_decimal(consumption!)} km/L',
                        ),
                    ],
                  ),
                ],
                if (record.notes != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    record.notes!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.text, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                onEdit();
              } else {
                onDelete();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Editar')),
              PopupMenuItem(value: 'delete', child: Text('Excluir')),
            ],
          ),
        ],
      ),
    ),
  );
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.blue.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.blue),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.blue,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.vehicle, required this.onAdd});
  final Vehicle vehicle;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(30),
    children: [
      const SizedBox(height: 60),
      const Icon(
        Icons.local_gas_station_outlined,
        size: 76,
        color: AppColors.blue,
      ),
      const SizedBox(height: 18),
      Text(
        'Nenhum abastecimento de ${vehicle.nickname}',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      const Text(
        'Registre litros, valor, quilometragem e tanque cheio para acompanhar gastos e consumo.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.muted),
      ),
      const SizedBox(height: 20),
      FilledButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add),
        label: const Text('NOVO ABASTECIMENTO'),
      ),
    ],
  );
}

class _NoVehicle extends StatelessWidget {
  const _NoVehicle();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(30),
      child: Text(
        'Cadastre e selecione um veículo para visualizar o histórico.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.muted, fontSize: 16),
      ),
    ),
  );
}

bool _sameMonth(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

String _decimal(double value) => value.toStringAsFixed(2).replaceAll('.', ',');

String _currency(double value) => 'R\$ ${_decimal(value)}';

String _monthName(int month) => const [
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
][month - 1];
