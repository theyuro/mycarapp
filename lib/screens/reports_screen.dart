import 'package:flutter/material.dart';

import '../models/establishment.dart';
import '../models/fueling_record.dart';
import '../models/maintenance_record.dart';
import '../models/vehicle.dart';
import '../models/vehicle_expense.dart';
import '../services/establishment_storage_service.dart';
import '../services/expense_storage_service.dart';
import '../services/fueling_storage_service.dart';
import '../services/maintenance_storage_service.dart';
import '../services/vehicle_storage_service.dart';
import '../services/access_service.dart';
import '../theme/app_colors.dart';
import 'lifetime_purchase_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final vehicleStorage = VehicleStorageService();
  final fuelingStorage = FuelingStorageService();
  final maintenanceStorage = MaintenanceStorageService();
  final establishmentStorage = EstablishmentStorageService();
  final expenseStorage = ExpenseStorageService();
  Vehicle? vehicle;
  List<_ConsumptionResult> results = const [];
  List<FuelingRecord> fuelings = const [];
  List<MaintenanceRecord> maintenances = const [];
  List<VehicleExpense> expenses = const [];
  List<Establishment> establishments = const [];
  int confirmedFillUps = 0;
  bool loading = true;
  _ReportPeriod fuelPeriod = _ReportPeriod.oneMonth;
  _ReportPeriod maintenancePeriod = _ReportPeriod.oneMonth;
  _StationPeriod stationPeriod = _StationPeriod.all;
  _StationPeriod workshopPeriod = _StationPeriod.all;
  _StationPeriod overallPeriod = _StationPeriod.sixMonths;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final active = await vehicleStorage.loadActiveVehicle();
      final records = await fuelingStorage.loadFuelings();
      final maintenanceRecords = await maintenanceStorage.loadMaintenances();
      final establishmentRecords = await establishmentStorage
          .loadEstablishments();
      final expenseRecords = await expenseStorage.loadExpenses();
      final selected = active == null
          ? <FuelingRecord>[]
          : records.where((item) => item.vehicleId == active.id).toList();
      final selectedExpenses = active == null
          ? <VehicleExpense>[]
          : expenseRecords
                .where((item) => item.vehicleId == active.id && item.active)
                .toList();
      // Carregado antes do cálculo de consumo: `_stationAttribution`
      // consulta `establishments` para resolver o nome do posto.
      establishments = establishmentRecords;
      final confirmed = selected.where(_isStrictFull).length;
      final calculated = _calculate(selected);
      final selectedMaintenances = active == null
          ? <MaintenanceRecord>[]
          : maintenanceRecords
                .where(
                  (item) => item.vehicleId == active.id && item.isCompleted,
                )
                .toList();
      if (!mounted) return;
      setState(() {
        vehicle = active;
        confirmedFillUps = confirmed;
        results = calculated.reversed.toList();
        fuelings = selected;
        maintenances = selectedMaintenances;
        expenses = selectedExpenses;
        establishments = establishmentRecords;
        loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  List<_ConsumptionResult> _calculate(List<FuelingRecord> source) {
    final records = [...source]..sort((a, b) => a.date.compareTo(b.date));
    final calculated = <_ConsumptionResult>[];
    FuelingRecord? start;
    double intervalLiters = 0;
    final intervalRecords = <FuelingRecord>[];
    double? previousConsumption;

    for (final record in records) {
      if (start != null) {
        intervalLiters += record.liters;
        intervalRecords.add(record);
      }
      if (!_isStrictFull(record)) continue;
      if (start != null &&
          record.mileage! > start.mileage! &&
          intervalLiters > 0) {
        final distance = record.mileage! - start.mileage!;
        final consumption = distance / intervalLiters;
        final attribution = _stationAttribution(intervalRecords);
        calculated.add(
          _ConsumptionResult(
            start: start,
            end: record,
            distance: distance,
            litersUsed: intervalLiters,
            consumption: consumption,
            difference: previousConsumption == null
                ? null
                : consumption - previousConsumption,
            stationKey: attribution?.key,
            stationName: attribution?.name,
            fuelType: attribution?.fuelType,
            establishmentId: attribution?.establishmentId,
          ),
        );
        previousConsumption = consumption;
      }
      start = record;
      intervalLiters = 0;
      intervalRecords.clear();
    }
    return calculated;
  }

  _StationAttribution? _stationAttribution(List<FuelingRecord> interval) {
    if (interval.isEmpty) return null;

    final fuels = interval
        .map((record) => record.fuelType?.trim())
        .whereType<String>()
        .where((fuel) => fuel.isNotEmpty)
        .toList();
    if (fuels.length != interval.length) return null;
    final fuelKeys = fuels.map((fuel) => fuel.toLowerCase()).toSet();
    if (fuelKeys.length != 1) return null;

    // Prioriza o estabelecimento estruturado (Fase 1): mais confiável que
    // comparar texto livre, já que o mesmo posto pode ter sido digitado de
    // formas diferentes antes da migração.
    final establishmentIds = interval
        .map((record) => record.establishmentId)
        .toSet();
    if (establishmentIds.length == 1 && establishmentIds.first != null) {
      final id = establishmentIds.first!;
      final name =
          _establishmentById(id)?.name ??
          _displayStation(interval.first.station?.trim() ?? '');
      return _StationAttribution(
        key: 'est:$id',
        name: name,
        fuelType: fuels.first,
        establishmentId: id,
      );
    }

    final stations = interval
        .map((record) => record.station?.trim())
        .whereType<String>()
        .where((station) => station.isNotEmpty)
        .toList();
    if (stations.length != interval.length) return null;
    final stationKeys = stations.map(_normalizeStation).toSet();
    if (stationKeys.length != 1 || stationKeys.first.isEmpty) return null;
    return _StationAttribution(
      key: stationKeys.first,
      name: _displayStation(stations.first),
      fuelType: fuels.first,
    );
  }

  Establishment? _establishmentById(String id) {
    for (final item in establishments) {
      if (item.id == id) return item;
    }
    return null;
  }

  bool _isStrictFull(FuelingRecord record) =>
      record.fullTank &&
      record.gaugeMarkedFull &&
      record.mileage != null &&
      record.tankCapacityLiters != null &&
      record.tankCapacityLiters! > 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: AppColors.navy,
      foregroundColor: Colors.white,
      title: const Text('Relatórios'),
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              children: [
                _ExpandableReportCard(
                  icon: Icons.local_gas_station_outlined,
                  title: 'Gastos com combustível',
                  subtitle: 'Total gasto e preço médio por litro',
                  initiallyExpanded: true,
                  child: _FuelExpenseReport(
                    records: fuelings,
                    period: fuelPeriod,
                    onPeriodChanged: (value) => _selectPremiumPeriod(
                      value,
                      (selected) => setState(() => fuelPeriod = selected),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _ExpandableReportCard(
                  icon: Icons.build_circle_outlined,
                  title: 'Gastos com manutenções',
                  subtitle: 'Somente manutenções realizadas',
                  child: _MaintenanceExpenseReport(
                    records: maintenances,
                    period: maintenancePeriod,
                    onPeriodChanged: (value) => _selectPremiumPeriod(
                      value,
                      (selected) =>
                          setState(() => maintenancePeriod = selected),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (AccessService.instance.subscriptionActive) ...[
                  _ConsumptionReport(
                    vehicle: vehicle,
                    results: results,
                    confirmedFillUps: confirmedFillUps,
                  ),
                  const SizedBox(height: 16),
                  _CostPerKmCard(
                    fuelings: fuelings,
                    maintenances: maintenances,
                    expenses: expenses,
                    period: overallPeriod,
                    onPeriodChanged: (value) =>
                        setState(() => overallPeriod = value),
                  ),
                  const SizedBox(height: 16),
                ],
                _StationReportCard(
                  key: ValueKey('station-report-${vehicle?.id}'),
                  results: results,
                  fuelings: fuelings,
                  establishments: establishments,
                  period: stationPeriod,
                  onPeriodChanged: (value) =>
                      setState(() => stationPeriod = value),
                  isPremium: AccessService.instance.subscriptionActive,
                  onUpgrade: _openPremium,
                ),
                if (AccessService.instance.subscriptionActive) ...[
                  const SizedBox(height: 16),
                  _WorkshopReportCard(
                    maintenances: maintenances,
                    fuelings: fuelings,
                    establishments: establishments,
                    period: workshopPeriod,
                    onPeriodChanged: (value) =>
                        setState(() => workshopPeriod = value),
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  _PremiumReportsCard(onTap: _openPremium),
                ],
              ],
            ),
          ),
  );

  Future<void> _selectPremiumPeriod(
    _ReportPeriod value,
    ValueChanged<_ReportPeriod> select,
  ) async {
    if (value == _ReportPeriod.oneMonth ||
        AccessService.instance.subscriptionActive) {
      select(value);
      return;
    }
    await _openPremium();
  }

  Future<void> _openPremium() => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(builder: (_) => const SubscriptionScreen()),
  );
}

class _PremiumReportsCard extends StatelessWidget {
  const _PremiumReportsCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [AppColors.navy, AppColors.blue]),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        const Icon(
          Icons.workspace_premium_rounded,
          color: AppColors.gold,
          size: 38,
        ),
        const SizedBox(height: 10),
        const Text(
          'Mais relatórios com o Premium',
          style: TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Compare períodos maiores, acompanhe a evolução do consumo do veículo e veja o ranking completo entre todos os seus postos.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, height: 1.35),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: AppColors.navy,
          ),
          child: const Text('CONHECER O PREMIUM'),
        ),
      ],
    ),
  );
}

enum _ReportPeriod {
  oneMonth('1 mês', 1),
  threeMonths('3 meses', 3),
  sixMonths('6 meses', 6),
  oneYear('1 ano', 12),
  all('Total', null);

  const _ReportPeriod(this.label, this.months);
  final String label;
  final int? months;
}

/// Opções de período do relatório "Por posto" (Seção 1.2 do guia): apenas
/// 3/6/12 meses e "tudo" — sem a opção de 1 mês, que raramente reúne
/// abastecimentos suficientes para comparar postos.
enum _StationPeriod {
  threeMonths('3 meses', 3),
  sixMonths('6 meses', 6),
  oneYear('12 meses', 12),
  all('Tudo', null);

  const _StationPeriod(this.label, this.months);
  final String label;
  final int? months;

  DateTime? startDate() {
    final value = months;
    if (value == null) return null;
    final now = DateTime.now();
    return DateTime(now.year, now.month - value + 1);
  }
}

class _ExpandableReportCard extends StatefulWidget {
  const _ExpandableReportCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.initiallyExpanded = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final bool initiallyExpanded;

  @override
  State<_ExpandableReportCard> createState() => _ExpandableReportCardState();
}

class _ExpandableReportCardState extends State<_ExpandableReportCard> {
  late bool expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.gold.withValues(alpha: .5)),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        InkWell(
          onTap: () => setState(() => expanded = !expanded),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppColors.blue.withValues(alpha: .09),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(widget.icon, color: AppColors.blue),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        widget.subtitle,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: expanded ? .5 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: widget.child,
          crossFadeState: expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
          sizeCurve: Curves.easeOut,
        ),
      ],
    ),
  );
}

class _FuelExpenseReport extends StatelessWidget {
  const _FuelExpenseReport({
    required this.records,
    required this.period,
    required this.onPeriodChanged,
  });

  final List<FuelingRecord> records;
  final _ReportPeriod period;
  final ValueChanged<_ReportPeriod> onPeriodChanged;

  List<FuelingRecord> get filtered {
    final months = period.months;
    if (months == null) return records;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - months + 1);
    return records.where((item) => !item.date.isBefore(start)).toList();
  }

  List<_MonthlyFuelExpense> monthly(List<FuelingRecord> source) {
    final grouped = <String, _MonthlyFuelExpense>{};
    for (final record in source) {
      final key = '${record.date.year}-${record.date.month}';
      final month = grouped.putIfAbsent(
        key,
        () => _MonthlyFuelExpense(record.date.year, record.date.month),
      );
      month.total += record.totalPrice;
      month.liters += record.liters;
      month.fillUps++;
    }
    return grouped.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Widget build(BuildContext context) {
    final selected = filtered;
    final total = selected.fold<double>(
      0,
      (sum, item) => sum + item.totalPrice,
    );
    final liters = selected.fold<double>(0, (sum, item) => sum + item.liters);
    final averagePrice = liters == 0 ? 0.0 : total / liters;
    final months = monthly(selected);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _ReportPeriod.values
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: ChoiceChip(
                        label: Text(item.label),
                        selected: period == item,
                        onSelected: (_) => onPeriodChanged(item),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ExpenseMetric(
                  label: 'Total gasto',
                  value: _moneyValue(total),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _ExpenseMetric(
                  label: 'Preço médio',
                  value: liters == 0 ? '--' : '${_decimal(averagePrice)}/L',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (months.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  'Nenhum abastecimento neste período.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            )
          else ...[
            const Text(
              'DETALHAMENTO POR MÊS',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: .6,
              ),
            ),
            const SizedBox(height: 9),
            ...months.map((item) => _MonthlyExpenseRow(expense: item)),
          ],
        ],
      ),
    );
  }
}

class _MaintenanceExpenseReport extends StatelessWidget {
  const _MaintenanceExpenseReport({
    required this.records,
    required this.period,
    required this.onPeriodChanged,
  });

  final List<MaintenanceRecord> records;
  final _ReportPeriod period;
  final ValueChanged<_ReportPeriod> onPeriodChanged;

  List<MaintenanceRecord> get filtered {
    final months = period.months;
    if (months == null) return records;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - months + 1);
    return records.where((item) => !item.date.isBefore(start)).toList();
  }

  List<_MonthlyMaintenanceExpense> monthly(List<MaintenanceRecord> source) {
    final grouped = <String, _MonthlyMaintenanceExpense>{};
    for (final record in source) {
      final key = '${record.date.year}-${record.date.month}';
      final month = grouped.putIfAbsent(
        key,
        () => _MonthlyMaintenanceExpense(record.date.year, record.date.month),
      );
      month.total += record.totalCost;
      month.maintenances++;
    }
    return grouped.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Widget build(BuildContext context) {
    final selected = filtered;
    final total = selected.fold<double>(0, (sum, item) => sum + item.totalCost);
    final average = selected.isEmpty ? 0.0 : total / selected.length;
    final months = monthly(selected);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _ReportPeriod.values
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: ChoiceChip(
                        label: Text(item.label),
                        selected: period == item,
                        onSelected: (_) => onPeriodChanged(item),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ExpenseMetric(
                  label: 'Total gasto',
                  value: _moneyValue(total),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _ExpenseMetric(
                  label: 'Custo médio',
                  value: selected.isEmpty ? '--' : _moneyValue(average),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (months.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  'Nenhuma manutenção realizada neste período.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            )
          else ...[
            const Text(
              'DETALHAMENTO POR MÊS',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: .6,
              ),
            ),
            const SizedBox(height: 9),
            ...months.map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            '${item.maintenances} ${item.maintenances == 1 ? 'manutenção' : 'manutenções'} realizada(s)',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _moneyValue(item.total),
                          style: const TextStyle(
                            color: AppColors.blue,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Média ${_moneyValue(item.average)}',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MonthlyMaintenanceExpense {
  _MonthlyMaintenanceExpense(this.year, this.month);
  final int year;
  final int month;
  double total = 0;
  int maintenances = 0;

  DateTime get date => DateTime(year, month);
  double get average => maintenances == 0 ? 0 : total / maintenances;
  String get label => '${_monthName(month)} $year';
}

class _ExpenseMetric extends StatelessWidget {
  const _ExpenseMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(13),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _MonthlyExpenseRow extends StatelessWidget {
  const _MonthlyExpenseRow({required this.expense});
  final _MonthlyFuelExpense expense;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(13),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                expense.label,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                '${expense.fillUps} ${expense.fillUps == 1 ? 'abastecimento' : 'abastecimentos'} • ${_decimal(expense.liters)} L',
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _moneyValue(expense.total),
              style: const TextStyle(
                color: AppColors.blue,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '${_decimal(expense.pricePerLiter)}/L',
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ],
        ),
      ],
    ),
  );
}

class _MonthlyFuelExpense {
  _MonthlyFuelExpense(this.year, this.month);
  final int year;
  final int month;
  double total = 0;
  double liters = 0;
  int fillUps = 0;

  DateTime get date => DateTime(year, month);
  double get pricePerLiter => liters == 0 ? 0 : total / liters;
  String get label => '${_monthName(month)} $year';
}

String _monthName(int month) => const [
  'Janeiro',
  'Fevereiro',
  'Março',
  'Abril',
  'Maio',
  'Junho',
  'Julho',
  'Agosto',
  'Setembro',
  'Outubro',
  'Novembro',
  'Dezembro',
][month - 1];

String _moneyValue(double value) =>
    'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

class _ConsumptionReport extends StatelessWidget {
  const _ConsumptionReport({
    required this.vehicle,
    required this.results,
    required this.confirmedFillUps,
  });
  final Vehicle? vehicle;
  final List<_ConsumptionResult> results;
  final int confirmedFillUps;

  @override
  Widget build(BuildContext context) {
    final totalDistance = results.fold<int>(
      0,
      (sum, item) => sum + item.distance,
    );
    final totalLiters = results.fold<double>(
      0,
      (sum, item) => sum + item.litersUsed,
    );
    final average = totalLiters == 0 ? null : totalDistance / totalLiters;
    final latest = results.isEmpty ? null : results.first;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: .55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.goldLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.speed_rounded, color: AppColors.navy),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Consumo estimado',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Cálculo estrito por tanque cheio',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (vehicle == null)
            const _Guidance(
              text: 'Cadastre e selecione um veículo para gerar o relatório.',
            )
          else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.navy, AppColors.blue],
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle!.nickname,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    latest == null
                        ? '-- km/L'
                        : '${_decimal(latest.consumption)} km/L',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'Último consumo calculado',
                    style: TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: 'Média geral',
                    value: average == null ? '--' : '${_decimal(average)} km/L',
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _Metric(
                    label: 'Tanques confirmados',
                    value: '$confirmedFillUps',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const _Guidance(
              text:
                  'Só calculamos entre dois abastecimentos com quilometragem, capacidade informada, tanque cheio e marcador confirmado. Abastecimentos parciais no intervalo também entram na soma de litros.',
            ),
            if (results.isEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'São necessários pelo menos dois tanques cheios confirmados para calcular o consumo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted),
              ),
            ] else ...[
              const SizedBox(height: 22),
              const Text(
                'DIFERENÇA POR ABASTECIMENTO',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .6,
                ),
              ),
              const SizedBox(height: 10),
              ...results.map((item) => _DifferenceCard(result: item)),
            ],
          ],
        ],
      ),
    );
  }
}

class _DifferenceCard extends StatelessWidget {
  const _DifferenceCard({required this.result});
  final _ConsumptionResult result;
  @override
  Widget build(BuildContext context) {
    final difference = result.difference;
    final percentage = difference == null
        ? null
        : difference / (result.consumption - difference) * 100;
    final improved = difference != null && difference >= 0;
    final capacity = result.end.tankCapacityLiters!;
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _date(result.end.date),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${result.distance} km • ${_decimal(result.litersUsed)} L consumidos',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_decimal(result.consumption)} km/L',
                    style: const TextStyle(
                      color: AppColors.blue,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  if (difference != null)
                    Text(
                      '${improved ? '+' : ''}${_decimal(difference)} km/L • ${percentage! >= 0 ? '+' : ''}${_decimal(percentage)}%',
                      style: TextStyle(
                        color: improved ? Colors.green : Colors.redAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  else
                    const Text(
                      'Base de comparação',
                      style: TextStyle(color: AppColors.muted, fontSize: 10),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 7),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Capacidade: ${_decimal(capacity)} L • Uso equivalente: ${_decimal(result.litersUsed / capacity)} tanque(s)',
              style: const TextStyle(color: AppColors.muted, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(13),
    ),
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 10),
        ),
      ],
    ),
  );
}

class _Guidance extends StatelessWidget {
  const _Guidance({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.blue.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, color: AppColors.blue, size: 19),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );
}

enum _StationSort {
  costPerKm('Custo por km'),
  consumption('Consumo'),
  spent('Valor gasto');

  const _StationSort(this.label);
  final String label;
}

/// Relatório "Por posto" (Seção 1.2 do guia). Gratuito mostra 1 posto só
/// (Regra 2 da trilha de implementação); Premium mostra o ranking completo.
class _StationReportCard extends StatefulWidget {
  const _StationReportCard({
    super.key,
    required this.results,
    required this.fuelings,
    required this.establishments,
    required this.period,
    required this.onPeriodChanged,
    required this.isPremium,
    required this.onUpgrade,
  });

  final List<_ConsumptionResult> results;
  final List<FuelingRecord> fuelings;
  final List<Establishment> establishments;
  final _StationPeriod period;
  final ValueChanged<_StationPeriod> onPeriodChanged;
  final bool isPremium;
  final VoidCallback onUpgrade;

  @override
  State<_StationReportCard> createState() => _StationReportCardState();
}

class _StationReportCardState extends State<_StationReportCard> {
  _StationSort sort = _StationSort.costPerKm;

  String? _baseKeyFor(FuelingRecord record) {
    final establishmentId = record.establishmentId;
    if (establishmentId != null) return 'est:$establishmentId';
    final text = record.station?.trim();
    if (text == null || text.isEmpty) return null;
    final normalized = _normalizeStation(text);
    return normalized.isEmpty ? null : normalized;
  }

  List<_StationAggregate> _aggregate() {
    final start = widget.period.startDate();
    final grouped = <String, _StationAggregate>{};

    for (final result in widget.results) {
      if (start != null && result.end.date.isBefore(start)) continue;
      final stationKey = result.stationKey;
      final stationName = result.stationName;
      final fuelType = result.fuelType;
      if (stationKey == null || stationName == null || fuelType == null) {
        continue;
      }
      final key = '$stationKey|${fuelType.toLowerCase()}';
      final aggregate = grouped.putIfAbsent(
        key,
        () => _StationAggregate(
          name: stationName,
          fuelType: fuelType,
          establishmentId: result.establishmentId,
        ),
      );
      aggregate.distance += result.distance;
      aggregate.consumptionLiters += result.litersUsed;
      aggregate.measurements++;
    }

    // Enriquece com preço, litros e nº de abastecimentos a partir dos
    // lançamentos individuais — só para postos que já têm ao menos um
    // intervalo de consumo válido calculado acima.
    for (final fueling in widget.fuelings) {
      if (start != null && fueling.date.isBefore(start)) continue;
      final fuel = fueling.fuelType?.trim();
      if (fuel == null || fuel.isEmpty) continue;
      final baseKey = _baseKeyFor(fueling);
      if (baseKey == null) continue;
      final aggregate = grouped['$baseKey|${fuel.toLowerCase()}'];
      if (aggregate == null) continue;
      aggregate.totalLiters += fueling.liters;
      aggregate.totalSpent += fueling.totalPrice;
      aggregate.fillUpsCount++;
    }

    final overall = _overallConsumption(start);
    final ranking = grouped.values
        .where((item) => item.measurements > 0)
        .toList();
    for (final item in ranking) {
      item.overallConsumption = overall;
    }
    return ranking;
  }

  double _overallConsumption(DateTime? start) {
    final filtered = widget.results.where(
      (item) => start == null || !item.end.date.isBefore(start),
    );
    final totalDistance = filtered.fold<int>(0, (sum, r) => sum + r.distance);
    final totalLiters = filtered.fold<double>(
      0,
      (sum, r) => sum + r.litersUsed,
    );
    return totalLiters == 0 ? 0 : totalDistance / totalLiters;
  }

  List<_StationAggregate> _sorted(List<_StationAggregate> ranking) {
    final list = [...ranking];
    switch (sort) {
      case _StationSort.costPerKm:
        list.sort((a, b) {
          if (a.costPerKm <= 0) return 1;
          if (b.costPerKm <= 0) return -1;
          return a.costPerKm.compareTo(b.costPerKm);
        });
      case _StationSort.consumption:
        list.sort((a, b) => b.consumption.compareTo(a.consumption));
      case _StationSort.spent:
        list.sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
    }
    return list;
  }

  /// O posto exibido no plano gratuito (Regra 2): o favorito, se ele tiver
  /// alguma medição no período; senão, o mais usado.
  _StationAggregate? _freeStation(List<_StationAggregate> ranking) {
    if (ranking.isEmpty) return null;
    final favoriteIds = widget.establishments
        .where((item) => item.favorite)
        .map((item) => item.id)
        .toSet();
    final favorites =
        ranking
            .where(
              (item) =>
                  item.establishmentId != null &&
                  favoriteIds.contains(item.establishmentId),
            )
            .toList()
          ..sort((a, b) => b.fillUpsCount.compareTo(a.fillUpsCount));
    if (favorites.isNotEmpty) return favorites.first;
    final byUsage = [...ranking]
      ..sort((a, b) => b.fillUpsCount.compareTo(a.fillUpsCount));
    return byUsage.first;
  }

  @override
  Widget build(BuildContext context) {
    final ranking = _aggregate();
    final byCost = [...ranking]
      ..removeWhere((item) => item.costPerKm <= 0)
      ..sort((a, b) => a.costPerKm.compareTo(b.costPerKm));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1E7EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_events_outlined,
                  color: AppColors.blue,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Por posto',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Onde seu carro rende mais',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _StationPeriod.values
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: ChoiceChip(
                        label: Text(item.label),
                        selected: widget.period == item,
                        onSelected: (_) => widget.onPeriodChanged(item),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          const _Guidance(
            text:
                'Um resultado só é atribuído a um posto quando todos os abastecimentos daquele intervalo foram feitos no mesmo local e com o mesmo combustível.',
          ),
          if (ranking.isEmpty) ...[
            const SizedBox(height: 18),
            const Text(
              'Ainda não há intervalos completos com posto informado para formar este relatório.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
          ] else if (!widget.isPremium) ...[
            const SizedBox(height: 18),
            _FreeStationCard(station: _freeStation(ranking)!),
            const SizedBox(height: 14),
            _StationUpsell(onTap: widget.onUpgrade),
          ] else ...[
            const SizedBox(height: 18),
            if (byCost.isNotEmpty)
              _StationHighlight(
                best: byCost.first,
                second: byCost.length > 1 ? byCost[1] : null,
              ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              children: _StationSort.values
                  .map(
                    (item) => ChoiceChip(
                      label: Text(item.label),
                      selected: sort == item,
                      onSelected: (_) => setState(() => sort = item),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 14),
            ...List.generate(
              _sorted(ranking).length,
              (index) => _StationRankRow(
                position: index + 1,
                station: _sorted(ranking)[index],
                maxCostPerKm: byCost.isEmpty ? 0 : byCost.last.costPerKm,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StationUpsell extends StatelessWidget {
  const _StationUpsell({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(13),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.goldLight.withValues(alpha: .4),
        borderRadius: BorderRadius.circular(13),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.workspace_premium_outlined,
            color: AppColors.navy,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Compare todos os seus postos com o Premium.',
              style: TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.navy,
            size: 20,
          ),
        ],
      ),
    ),
  );
}

class _FreeStationCard extends StatelessWidget {
  const _FreeStationCard({required this.station});
  final _StationAggregate station;

  @override
  Widget build(BuildContext context) {
    final reliable = station.reliable;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy, AppColors.blue],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            station.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            station.fuelType,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StationMetricTile(
                  label: 'Consumo médio',
                  value: '${_decimal(station.consumption)} km/L',
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _StationMetricTile(
                  label: 'Custo por km',
                  value: station.costPerKm == 0
                      ? '--'
                      : _moneyValue(station.costPerKm),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: _StationMetricTile(
                  label: 'Preço médio/L',
                  value: station.avgPricePerLiter == 0
                      ? '--'
                      : '${_decimal(station.avgPricePerLiter)}/L',
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _StationMetricTile(
                  label: 'Litros e valor',
                  value:
                      '${_decimal(station.totalLiters)} L • ${_moneyValue(station.totalSpent)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            'Baseado em ${station.fillUpsCount} '
            '${station.fillUpsCount == 1 ? 'abastecimento' : 'abastecimentos'}'
            '${reliable ? '' : ' • amostra pequena, não é conclusivo ainda'}',
            style: TextStyle(
              color: reliable ? Colors.white70 : AppColors.goldLight,
              fontSize: 11,
              fontWeight: reliable ? FontWeight.w400 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StationMetricTile extends StatelessWidget {
  const _StationMetricTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(11),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10.5),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ],
    ),
  );
}

class _StationHighlight extends StatelessWidget {
  const _StationHighlight({required this.best, this.second});
  final _StationAggregate best;
  final _StationAggregate? second;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [AppColors.navy, AppColors.blue]),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          best.reliable
              ? 'Seu melhor custo por km: ${best.name}'
              : '${best.name} (amostra pequena)',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '${_moneyValue(best.costPerKm)}/km • ${_decimal(best.consumption)} km/L • '
          'baseado em ${best.fillUpsCount} abastecimento(s)',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        if (second != null) ...[
          const Divider(color: Colors.white24, height: 20),
          Text(
            '2º colocado: ${second!.name}',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          Text(
            '${_moneyValue(second!.costPerKm)}/km • ${_decimal(second!.consumption)} km/L',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ],
    ),
  );
}

class _StationRankRow extends StatelessWidget {
  const _StationRankRow({
    required this.position,
    required this.station,
    required this.maxCostPerKm,
  });
  final int position;
  final _StationAggregate station;
  final double maxCostPerKm;

  @override
  Widget build(BuildContext context) {
    final variation = station.variationPercent;
    final barFraction = maxCostPerKm <= 0 || station.costPerKm <= 0
        ? 0.0
        : (station.costPerKm / maxCostPerKm).clamp(0.05, 1.0);
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: position == 1 ? AppColors.goldLight : Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$positionº',
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${station.fuelType} • ${station.fillUpsCount} '
                      '${station.fillUpsCount == 1 ? 'abastecimento' : 'abastecimentos'}'
                      '${variation == null ? '' : ' • ${variation >= 0 ? '+' : ''}${_decimal(variation)}% vs. média'}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                    if (!station.reliable)
                      const Text(
                        'Amostra pequena',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_decimal(station.consumption)} km/L',
                    style: const TextStyle(
                      color: AppColors.blue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    station.costPerKm == 0
                        ? '--/km'
                        : '${_moneyValue(station.costPerKm)}/km',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (barFraction > 0) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LayoutBuilder(
                builder: (context, constraints) => Stack(
                  children: [
                    Container(height: 6, color: const Color(0xFFE5EAF0)),
                    Container(
                      height: 6,
                      width: constraints.maxWidth * barFraction,
                      color: AppColors.blue,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StationAggregate {
  _StationAggregate({
    required this.name,
    required this.fuelType,
    this.establishmentId,
  });
  final String name;
  final String fuelType;
  final String? establishmentId;
  int distance = 0;
  double consumptionLiters = 0;
  int measurements = 0;
  double totalLiters = 0;
  double totalSpent = 0;
  int fillUpsCount = 0;
  double overallConsumption = 0;

  double get consumption =>
      consumptionLiters == 0 ? 0 : distance / consumptionLiters;
  double get avgPricePerLiter =>
      totalLiters == 0 ? 0 : totalSpent / totalLiters;
  double get costPerKm => consumption == 0 ? 0 : avgPricePerLiter / consumption;

  /// Guia (Seção 1.2): só destacar como "melhor posto" com 4+ abastecimentos
  /// válidos; abaixo disso, mostrar com aviso de amostra pequena.
  bool get reliable => fillUpsCount >= 4;

  double? get variationPercent {
    if (overallConsumption <= 0 || consumption <= 0) return null;
    return (consumption - overallConsumption) / overallConsumption * 100;
  }
}

class _StationAttribution {
  const _StationAttribution({
    required this.key,
    required this.name,
    required this.fuelType,
    this.establishmentId,
  });
  final String key;
  final String name;
  final String fuelType;
  final String? establishmentId;
}

class _ConsumptionResult {
  const _ConsumptionResult({
    required this.start,
    required this.end,
    required this.distance,
    required this.litersUsed,
    required this.consumption,
    this.stationKey,
    this.stationName,
    this.fuelType,
    this.establishmentId,
    this.difference,
  });
  final FuelingRecord start;
  final FuelingRecord end;
  final int distance;
  final double litersUsed;
  final double consumption;
  final String? stationKey;
  final String? stationName;
  final String? fuelType;
  final String? establishmentId;
  final double? difference;
}

/// Distância percorrida no período, estimada pela diferença entre a menor
/// e a maior quilometragem informada nos abastecimentos — mesma lógica já
/// usada para o consumo, reaplicada aqui para custo por km e por oficina.
int? _distanceInPeriod(List<FuelingRecord> fuelings, DateTime? start) {
  final relevant =
      fuelings
          .where(
            (item) =>
                (start == null || !item.date.isBefore(start)) &&
                item.mileage != null,
          )
          .map((item) => item.mileage!)
          .toList()
        ..sort();
  if (relevant.length < 2) return null;
  final distance = relevant.last - relevant.first;
  return distance <= 0 ? null : distance;
}

double _expensesInPeriod(
  List<VehicleExpense> expenses,
  DateTime start,
  DateTime end,
) {
  var total = 0.0;
  var cursor = DateTime(start.year, start.month);
  final last = DateTime(end.year, end.month);
  while (!cursor.isAfter(last)) {
    for (final expense in expenses) {
      if (expense.occursIn(cursor)) total += expense.amount;
    }
    cursor = DateTime(cursor.year, cursor.month + 1);
  }
  return total;
}

int _monthsBetween(DateTime start, DateTime end) {
  final months = (end.year - start.year) * 12 + end.month - start.month + 1;
  return months < 1 ? 1 : months;
}

/// Relatório "Custo total por km" + projeção anual (Seção 1.4 do guia — a
/// própria seção 1.5 lista este como um dos três relatórios prioritários,
/// junto com consumo por posto e evolução do consumo). 100% Premium.
class _CostPerKmCard extends StatelessWidget {
  const _CostPerKmCard({
    required this.fuelings,
    required this.maintenances,
    required this.expenses,
    required this.period,
    required this.onPeriodChanged,
  });

  final List<FuelingRecord> fuelings;
  final List<MaintenanceRecord> maintenances;
  final List<VehicleExpense> expenses;
  final _StationPeriod period;
  final ValueChanged<_StationPeriod> onPeriodChanged;

  DateTime _earliestDate() {
    final dates = [
      ...fuelings.map((item) => item.date),
      ...maintenances.map((item) => item.date),
    ];
    if (dates.isEmpty) return DateTime.now();
    return dates.reduce((a, b) => a.isBefore(b) ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    final start = period.startDate() ?? _earliestDate();
    final end = DateTime.now();
    final distance = _distanceInPeriod(fuelings, period.startDate());
    final fuelTotal = fuelings
        .where((item) => !item.date.isBefore(start))
        .fold<double>(0, (sum, item) => sum + item.totalPrice);
    final maintenanceTotal = maintenances
        .where((item) => !item.date.isBefore(start))
        .fold<double>(0, (sum, item) => sum + item.totalCost);
    final expenseTotal = _expensesInPeriod(expenses, start, end);
    final total = fuelTotal + maintenanceTotal + expenseTotal;
    final costPerKm = distance == null ? null : total / distance;
    final months = _monthsBetween(start, end);
    final annualProjection = total / months * 12;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1E7EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.functions_rounded,
                  color: AppColors.blue,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Custo total por km',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Combustível, manutenções e despesas somados',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _StationPeriod.values
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: ChoiceChip(
                        label: Text(item.label),
                        selected: period == item,
                        onSelected: (_) => onPeriodChanged(item),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          if (distance == null)
            const Text(
              'São necessários ao menos dois abastecimentos com quilometragem no período para calcular este relatório.',
              style: TextStyle(color: AppColors.muted),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _ExpenseMetric(
                    label: 'Custo por km',
                    value: costPerKm == null
                        ? '--'
                        : '${_moneyValue(costPerKm)}/km',
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _ExpenseMetric(
                    label: 'Projeção anual',
                    value: _moneyValue(annualProjection),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${_decimal(distance.toDouble())} km rodados • '
              '${_moneyValue(total)} no total '
              '(combustível ${_moneyValue(fuelTotal)} • manutenção ${_moneyValue(maintenanceTotal)} • despesas ${_moneyValue(expenseTotal)})',
              style: const TextStyle(color: AppColors.muted, fontSize: 11.5),
            ),
            const SizedBox(height: 10),
            const _Guidance(
              text:
                  'A projeção anual estende a média mensal do período selecionado — não considera sazonalidade nem manutenções pontuais fora do padrão.',
            ),
          ],
        ],
      ),
    );
  }
}

/// Relatório "Por oficina" (Seção 1.3 do guia). 100% Premium: não faz parte
/// da exceção de nuvem-grátis da Regra 2 (essa vale só para postos).
class _WorkshopReportCard extends StatelessWidget {
  const _WorkshopReportCard({
    required this.maintenances,
    required this.fuelings,
    required this.establishments,
    required this.period,
    required this.onPeriodChanged,
  });

  final List<MaintenanceRecord> maintenances;
  final List<FuelingRecord> fuelings;
  final List<Establishment> establishments;
  final _StationPeriod period;
  final ValueChanged<_StationPeriod> onPeriodChanged;

  String? _baseKeyFor(MaintenanceRecord record) {
    final establishmentId = record.establishmentId;
    if (establishmentId != null) return 'est:$establishmentId';
    final text = record.workshop?.trim();
    if (text == null || text.isEmpty) return null;
    final normalized = _normalizeStation(text);
    return normalized.isEmpty ? null : normalized;
  }

  String _nameFor(MaintenanceRecord record) {
    final establishmentId = record.establishmentId;
    if (establishmentId != null) {
      for (final item in establishments) {
        if (item.id == establishmentId) return item.name;
      }
    }
    return _displayStation(record.workshop?.trim() ?? 'Oficina não informada');
  }

  List<MaintenanceRecord> _filtered() {
    final start = period.startDate();
    return maintenances
        .where((item) => start == null || !item.date.isBefore(start))
        .where(
          (item) =>
              item.establishmentId != null ||
              (item.workshop != null && item.workshop!.trim().isNotEmpty),
        )
        .toList();
  }

  List<_WorkshopAggregate> _ranking() {
    final grouped = <String, _WorkshopAggregate>{};
    for (final record in _filtered()) {
      final key = _baseKeyFor(record);
      if (key == null) continue;
      final aggregate = grouped.putIfAbsent(
        key,
        () => _WorkshopAggregate(
          name: _nameFor(record),
          establishmentId: record.establishmentId,
        ),
      );
      aggregate.addVisit(record);
    }
    final ranking = grouped.values.toList()
      ..sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
    return ranking;
  }

  Map<String, double> _categoryComposition() {
    final composition = <String, double>{};
    for (final record in _filtered()) {
      composition[record.category] =
          (composition[record.category] ?? 0) + record.totalCost;
    }
    return composition;
  }

  /// Compara o preço médio da mesma categoria de serviço entre oficinas
  /// diferentes — só para categorias com histórico em 2+ oficinas.
  Map<String, Map<String, double>> _categoryComparison() {
    final raw = <String, Map<String, List<double>>>{};
    for (final record in _filtered()) {
      final name = _nameFor(record);
      raw
          .putIfAbsent(record.category, () => {})
          .putIfAbsent(name, () => [])
          .add(record.totalCost);
    }
    final comparison = <String, Map<String, double>>{};
    for (final entry in raw.entries) {
      if (entry.value.length < 2) continue;
      comparison[entry.key] = {
        for (final workshop in entry.value.entries)
          workshop.key:
              workshop.value.fold<double>(0, (sum, v) => sum + v) /
              workshop.value.length,
      };
    }
    return comparison;
  }

  double? _costPer1000Km() {
    final distance = _distanceInPeriod(fuelings, period.startDate());
    if (distance == null) return null;
    final total = _filtered().fold<double>(
      0,
      (sum, item) => sum + item.totalCost,
    );
    return total / distance * 1000;
  }

  @override
  Widget build(BuildContext context) {
    final ranking = _ranking();
    final composition = _categoryComposition();
    final sortedComposition = composition.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxComposition = sortedComposition.isEmpty
        ? 0.0
        : sortedComposition.first.value;
    final comparison = _categoryComparison();
    final costPer1000 = _costPer1000Km();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1E7EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.build_circle_outlined,
                  color: AppColors.blue,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Por oficina',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Onde seu dinheiro de manutenção vai',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _StationPeriod.values
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: ChoiceChip(
                        label: Text(item.label),
                        selected: period == item,
                        onSelected: (_) => onPeriodChanged(item),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          if (costPer1000 != null) ...[
            _ExpenseMetric(
              label: 'Custo de manutenção por 1.000 km',
              value: _moneyValue(costPer1000),
            ),
            const SizedBox(height: 16),
          ],
          if (ranking.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Nenhuma manutenção com oficina informada neste período.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted),
              ),
            )
          else ...[
            const Text(
              'POR OFICINA',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: .6,
              ),
            ),
            const SizedBox(height: 9),
            ...ranking.map((item) => _WorkshopRow(workshop: item)),
          ],
          if (sortedComposition.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'COMPOSIÇÃO POR TIPO DE SERVIÇO',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: .6,
              ),
            ),
            const SizedBox(height: 9),
            for (final entry in sortedComposition.take(6))
              _CompositionRow(
                label: entry.key,
                value: entry.value,
                fraction: maxComposition == 0
                    ? 0
                    : entry.value / maxComposition,
              ),
          ],
          if (comparison.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'MESMO SERVIÇO, OFICINAS DIFERENTES',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: .6,
              ),
            ),
            const SizedBox(height: 9),
            for (final entry in comparison.entries.take(4))
              _CategoryComparisonCard(category: entry.key, prices: entry.value),
          ],
        ],
      ),
    );
  }
}

class _WorkshopRow extends StatelessWidget {
  const _WorkshopRow({required this.workshop});
  final _WorkshopAggregate workshop;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                workshop.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                '${workshop.visitCount} ${workshop.visitCount == 1 ? 'visita' : 'visitas'} • '
                'ticket médio ${_moneyValue(workshop.avgTicket)}',
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
              if (workshop.reworkAlert)
                const Text(
                  'Possível retrabalho: duas visitas do mesmo tipo em até 30 dias',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
        Text(
          _moneyValue(workshop.totalSpent),
          style: const TextStyle(
            color: AppColors.blue,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _CompositionRow extends StatelessWidget {
  const _CompositionRow({
    required this.label,
    required this.value,
    required this.fraction,
  });
  final String label;
  final double value;
  final double fraction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: const TextStyle(fontSize: 12.5)),
            ),
            Text(
              _moneyValue(value),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(
              children: [
                Container(height: 6, color: const Color(0xFFE5EAF0)),
                Container(
                  height: 6,
                  width: constraints.maxWidth * fraction.clamp(0.02, 1.0),
                  color: AppColors.gold,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _CategoryComparisonCard extends StatelessWidget {
  const _CategoryComparisonCard({required this.category, required this.prices});
  final String category;
  final Map<String, double> prices;

  @override
  Widget build(BuildContext context) {
    final entries = prices.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(category, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                  Text(
                    _moneyValue(entry.value),
                    style: const TextStyle(fontSize: 11.5),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _WorkshopAggregate {
  _WorkshopAggregate({required this.name, this.establishmentId});
  final String name;
  final String? establishmentId;
  double totalSpent = 0;
  int visitCount = 0;
  bool reworkAlert = false;
  final Map<String, List<DateTime>> _visitsByCategory = {};

  void addVisit(MaintenanceRecord record) {
    totalSpent += record.totalCost;
    visitCount++;
    final dates = _visitsByCategory.putIfAbsent(record.category, () => []);
    for (final previous in dates) {
      if (record.date.difference(previous).inDays.abs() <= 30) {
        reworkAlert = true;
      }
    }
    dates.add(record.date);
  }

  double get avgTicket => visitCount == 0 ? 0 : totalSpent / visitCount;
}

String _normalizeStation(String value) {
  var normalized = value.toLowerCase().trim();
  const replacements = {
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'é': 'e',
    'ê': 'e',
    'í': 'i',
    'ó': 'o',
    'ô': 'o',
    'õ': 'o',
    'ú': 'u',
    'ç': 'c',
  };
  replacements.forEach((from, to) {
    normalized = normalized.replaceAll(from, to);
  });
  normalized = normalized
      .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
      .replaceAll(RegExp(r'\bposto\b'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return normalized;
}

String _displayStation(String value) {
  final withoutPrefix = value.trim().replaceFirst(
    RegExp(r'^posto\s+', caseSensitive: false),
    '',
  );
  return withoutPrefix.isEmpty ? value.trim() : withoutPrefix;
}

String _decimal(double value) => value.toStringAsFixed(2).replaceAll('.', ',');
String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
