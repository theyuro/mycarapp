import 'package:flutter/material.dart';

import '../models/maintenance_record.dart';
import '../models/vehicle.dart';
import '../services/maintenance_storage_service.dart';
import '../services/vehicle_storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/vehicle_type_icon.dart';
import 'maintenance_form_screen.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});
  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  final storage = MaintenanceStorageService();
  final vehicleStorage = VehicleStorageService();
  Vehicle? vehicle;
  List<MaintenanceRecord> records = const [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final active = await vehicleStorage.loadActiveVehicle();
      final all = await storage.loadMaintenances();
      final filtered =
          active == null
                ? <MaintenanceRecord>[]
                : all.where((item) => item.vehicleId == active.id).toList()
            ..sort((a, b) => b.date.compareTo(a.date));
      if (!mounted) return;
      setState(() {
        vehicle = active;
        records = filtered;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
      message('Não foi possível carregar as manutenções.');
    }
  }

  Future<void> openForm({
    MaintenanceRecord? record,
    bool completed = true,
  }) async {
    final active = vehicle;
    if (active == null) {
      message('Cadastre e selecione um veículo primeiro.');
      return;
    }
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => MaintenanceFormScreen(
          vehicle: active,
          record: record,
          initialCompleted: completed,
        ),
      ),
    );
    if (changed == true) {
      await load();
      if (mounted && record == null) {
        message(
          completed
              ? 'Manutenção realizada incluída'
              : 'Próxima manutenção incluída',
        );
      }
    }
  }

  Future<void> remove(MaintenanceRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir manutenção?'),
        content: Text('${record.service} será removida permanentemente.'),
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
      await storage.deleteMaintenance(record.id);
      await load();
      if (mounted) message('Manutenção excluída.');
    } catch (_) {
      if (mounted) message('Não foi possível excluir a manutenção.');
    }
  }

  void message(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 1),
    ),
  );

  void chooseMaintenanceType() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.blue,
                ),
                title: const Text('Manutenção realizada'),
                subtitle: const Text('Registrar serviço, oficina e custos'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  openForm(completed: true);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.event_outlined,
                  color: AppColors.gold,
                ),
                title: const Text('Próxima manutenção'),
                subtitle: const Text('Planejar mesmo sem possuir histórico'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  openForm(completed: false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completed = records.where((item) => item.isCompleted).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final upcoming = records.where((item) => !item.isCompleted).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          title: const Text('Manutenções'),
          bottom: const TabBar(
            indicatorColor: AppColors.gold,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(text: 'REALIZADAS'),
              Tab(text: 'PRÓXIMAS'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: vehicle == null ? null : chooseMaintenanceType,
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.navy,
          icon: const Icon(Icons.add),
          label: const Text('NOVA MANUTENÇÃO'),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : vehicle == null
            ? const _NoVehicle()
            : TabBarView(
                children: [
                  _MaintenanceList(
                    header: _Header(vehicle: vehicle!),
                    summary: _Summary(records: completed, vehicle: vehicle!),
                    emptyText: 'Nenhuma manutenção realizada',
                    onRefresh: load,
                    children: completed
                        .map(
                          (record) => _MaintenanceCard(
                            record: record,
                            vehicle: vehicle!,
                            onEdit: () => openForm(record: record),
                            onDelete: () => remove(record),
                          ),
                        )
                        .toList(),
                  ),
                  _MaintenanceList(
                    header: _Header(vehicle: vehicle!),
                    emptyText: 'Nenhuma próxima manutenção planejada',
                    onRefresh: load,
                    children: upcoming
                        .map(
                          (record) => _UpcomingCard(
                            record: record,
                            vehicle: vehicle!,
                            onEdit: () =>
                                openForm(record: record, completed: false),
                            onDelete: () => remove(record),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
      ),
    );
  }
}

class _MaintenanceList extends StatelessWidget {
  const _MaintenanceList({
    required this.header,
    required this.emptyText,
    required this.onRefresh,
    required this.children,
    this.summary,
  });
  final Widget header;
  final Widget? summary;
  final String emptyText;
  final Future<void> Function() onRefresh;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: onRefresh,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        header,
        if (summary != null) ...[const SizedBox(height: 12), summary!],
        const SizedBox(height: 20),
        if (children.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 54, horizontal: 20),
            child: Column(
              children: [
                const Icon(
                  Icons.event_note_outlined,
                  size: 58,
                  color: AppColors.blue,
                ),
                const SizedBox(height: 14),
                Text(
                  emptyText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          )
        else
          ...children,
      ],
    ),
  );
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({
    required this.record,
    required this.vehicle,
    required this.onEdit,
    required this.onDelete,
  });
  final MaintenanceRecord record;
  final Vehicle vehicle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final overdue =
        record.date.isBefore(
          DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
          ),
        ) ||
        (record.mileage > 0 && vehicle.mileage >= record.mileage);
    final color = overdue ? Colors.redAccent : AppColors.blue;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: .12),
          child: Icon(Icons.event_outlined, color: color),
        ),
        title: Text(
          record.service,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          [
            record.category,
            _date(record.date),
            if (record.mileage > 0) '${record.mileage} km',
          ].join(' • '),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Editar')),
            PopupMenuItem(value: 'delete', child: Text('Excluir')),
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.records, required this.vehicle});
  final List<MaintenanceRecord> records;
  final Vehicle vehicle;
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final month = records
        .where((r) => r.date.year == now.year && r.date.month == now.month)
        .fold<double>(0, (sum, r) => sum + r.totalCost);
    final total = records.fold<double>(0, (sum, r) => sum + r.totalCost);
    final alerts = records
        .where((r) => _status(r, vehicle) != _MaintenanceStatus.ok)
        .length;
    return Row(
      children: [
        Expanded(
          child: _Metric(
            label: 'Este mês',
            value: _money(month),
            icon: Icons.calendar_month_outlined,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _Metric(
            label: 'Total',
            value: _money(total),
            icon: Icons.payments_outlined,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _Metric(
            label: 'Alertas',
            value: '$alerts',
            icon: Icons.notifications_active_outlined,
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 13),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE1E7EE)),
    ),
    child: Column(
      children: [
        Icon(icon, color: AppColors.blue, size: 21),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 10),
        ),
      ],
    ),
  );
}

class _MaintenanceCard extends StatelessWidget {
  const _MaintenanceCard({
    required this.record,
    required this.vehicle,
    required this.onEdit,
    required this.onDelete,
  });
  final MaintenanceRecord record;
  final Vehicle vehicle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) {
    final status = _status(record, vehicle);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _statusColor(status).withValues(alpha: .12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.build_rounded, color: _statusColor(status)),
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
                          record.service,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        _money(record.totalCost),
                        style: const TextStyle(
                          color: AppColors.blue,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${record.category} • ${_date(record.date)} • ${record.mileage} km',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  if (record.workshop != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        record.workshop!,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  if (record.nextDate != null ||
                      record.nextMileage != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _nextLabel(record, status),
                        style: TextStyle(
                          color: _statusColor(status),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
}

class _Header extends StatelessWidget {
  const _Header({required this.vehicle});
  final Vehicle vehicle;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [AppColors.navy, AppColors.blue]),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        Icon(vehicleTypeIcon(vehicle), color: AppColors.gold, size: 32),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            vehicle.nickname,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

class _NoVehicle extends StatelessWidget {
  const _NoVehicle();
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(30),
      child: Text(
        'Cadastre e selecione um veículo para acessar as manutenções.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.muted, fontSize: 16),
      ),
    ),
  );
}

enum _MaintenanceStatus { ok, upcoming, overdue }

_MaintenanceStatus _status(MaintenanceRecord record, Vehicle vehicle) {
  final overdueDate =
      record.nextDate != null && record.nextDate!.isBefore(DateTime.now());
  final overdueKm =
      record.nextMileage != null && vehicle.mileage >= record.nextMileage!;
  if (overdueDate || overdueKm) return _MaintenanceStatus.overdue;
  final upcomingDate =
      record.nextDate != null &&
      record.nextDate!.difference(DateTime.now()).inDays <= 30;
  final upcomingKm =
      record.nextMileage != null &&
      record.nextMileage! - vehicle.mileage <= 1000;
  if (upcomingDate || upcomingKm) return _MaintenanceStatus.upcoming;
  return _MaintenanceStatus.ok;
}

Color _statusColor(_MaintenanceStatus status) => switch (status) {
  _MaintenanceStatus.ok => Colors.green,
  _MaintenanceStatus.upcoming => Colors.orange,
  _MaintenanceStatus.overdue => Colors.redAccent,
};

String _nextLabel(MaintenanceRecord record, _MaintenanceStatus status) {
  final prefix = status == _MaintenanceStatus.overdue
      ? 'Vencida'
      : status == _MaintenanceStatus.upcoming
      ? 'Próxima'
      : 'Prevista';
  final values = [
    if (record.nextDate != null) _date(record.nextDate!),
    if (record.nextMileage != null) '${record.nextMileage} km',
  ];
  return '$prefix: ${values.join(' • ')}';
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
String _money(double value) =>
    'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
