import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';

import '../models/fueling_record.dart';
import '../models/maintenance_record.dart';
import '../models/vehicle.dart';
import '../models/vehicle_expense.dart';
import '../services/access_service.dart';
import '../services/ads_config.dart';
import '../services/ads_service.dart';
import '../services/auto_backup_service.dart';
import '../services/expense_storage_service.dart';
import '../services/fueling_storage_service.dart';
import '../services/maintenance_storage_service.dart';
import '../services/notification_service.dart';
import '../services/premium_upsell_service.dart';
import '../services/vehicle_storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/free_user_banner_ad.dart';
import '../widgets/premium_upsell_banner.dart';
import '../widgets/recommendation_banner.dart';
import '../widgets/rewarded_ad_free.dart';
import '../widgets/vehicle_type_icon.dart';
import 'account_screen.dart';
import 'data_transfer_screen.dart';
import 'documents_screen.dart';
import 'establishments_screen.dart';
import 'expenses_screen.dart';
import 'fueling_form_screen.dart';
import 'fueling_history_screen.dart';
import 'lifetime_purchase_screen.dart';
import 'maintenance_form_screen.dart';
import 'maintenance_screen.dart';
import 'notifications_screen.dart';
import 'reports_screen.dart';
import 'support_screen.dart';
import 'vehicles_screen.dart';
import '../l10n/l10n.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const monthPageOrigin = 1200;
  final vehicleStorage = VehicleStorageService();
  Vehicle? activeVehicle;
  int unreadNotifications = 0;
  final notificationService = NotificationService();
  final maintenanceStorage = MaintenanceStorageService();
  final fuelingStorage = FuelingStorageService();
  final expenseStorage = ExpenseStorageService();
  final monthController = PageController(initialPage: monthPageOrigin);
  List<FuelingRecord> fuelings = const [];
  List<MaintenanceRecord> maintenances = const [];
  List<VehicleExpense> expenses = const [];

  /// A oferta de restaurar aparece no máximo uma vez por abertura do app.
  static bool _restoreOffered = false;

  @override
  void initState() {
    super.initState();
    loadActiveVehicle().then((_) => _offerCloudRestore());
  }

  /// Celular novo (sem veículos) e dados na nuvem: oferece restaurar.
  Future<void> _offerCloudRestore() async {
    if (_restoreOffered || activeVehicle != null) return;
    _restoreOffered = true;
    final backup = AutoBackupService.instance;
    final count = await backup.cloudItemCount();
    if (count == 0 || !mounted) return;
    final restore = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.cloud_download_outlined),
        title: Text(tr.homeCloudFoundTitle),
        content: Text(tr.homeCloudFoundText(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr.notNowUpper),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr.restore),
          ),
        ],
      ),
    );
    if (restore != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(tr.homeRestoring),
        behavior: SnackBarBehavior.floating,
      ),
    );
    try {
      final restored = await backup.restore();
      messenger.showSnackBar(
        SnackBar(
          content: Text(tr.backupRestoredCount(restored)),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await loadActiveVehicle();
    } on Object {
      messenger.showSnackBar(
        SnackBar(
          content: Text(tr.homeRestoreLater),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> loadActiveVehicle() async {
    try {
      final vehicle = await vehicleStorage.loadActiveVehicle();
      if (mounted) setState(() => activeVehicle = vehicle);
      await refreshDashboardData(vehicle);
      await refreshNotifications(vehicle);
    } catch (_) {
      if (mounted) setState(() => activeVehicle = null);
    }
  }

  Future<void> refreshDashboardData(Vehicle? active) async {
    final allFuelings = await fuelingStorage.loadFuelings();
    final allMaintenances = await maintenanceStorage.loadMaintenances();
    final allExpenses = await expenseStorage.loadExpenses();
    if (!mounted) return;
    setState(() {
      fuelings = active == null
          ? const []
          : allFuelings.where((item) => item.vehicleId == active.id).toList();
      maintenances = active == null
          ? const []
          : allMaintenances
                .where((item) => item.vehicleId == active.id)
                .toList();
      expenses = active == null
          ? const []
          : allExpenses.where((item) => item.vehicleId == active.id).toList();
    });
  }

  Future<void> refreshNotifications(Vehicle? active) async {
    await notificationService.requestPermission();
    await notificationService.addUnique(
      key: 'update-2026-08-documents-maintenance',
      title: tr.newsDocsTitle,
      message: tr.newsDocsText,
      showSystemNotification: false,
    );
    await notificationService.addUnique(
      key: 'update-2026-10-v1-3-4',
      title: tr.news134Title,
      message: tr.news134Text,
      showSystemNotification: false,
    );
    await notificationService.addUnique(
      key: 'update-2026-10-v1-3-3',
      title: tr.news133Title,
      message: tr.news133Text,
      showSystemNotification: false,
    );
    if (active != null) {
      final records = await maintenanceStorage.loadMaintenances();
      final now = DateTime.now();
      for (final record in records.where(
        (item) => item.vehicleId == active.id,
      )) {
        final targetDate = record.isCompleted ? record.nextDate : record.date;
        final targetMileage = record.isCompleted
            ? record.nextMileage
            : (record.mileage > 0 ? record.mileage : null);
        final closeByDate =
            targetDate != null && targetDate.difference(now).inDays <= 30;
        final closeByMileage =
            targetMileage != null && targetMileage - active.mileage <= 1000;
        if (!closeByDate && !closeByMileage) continue;
        final details = [
          if (targetDate != null) _homeDate(targetDate),
          if (targetMileage != null) '$targetMileage km',
        ].join(' • ');
        await notificationService.addUnique(
          key: 'maintenance-${record.id}-$details',
          title: closeByDate && targetDate.isBefore(now)
              ? tr.maintOverdueTitle
              : tr.maintNext,
          message: '${record.service} • $details',
          category: 'maintenance',
        );
      }

      final fuelings =
          (await fuelingStorage.loadFuelings())
              .where((item) => item.vehicleId == active.id)
              .toList()
            ..sort((a, b) => a.date.compareTo(b.date));
      final full = fuelings
          .where(
            (item) =>
                item.fullTank &&
                item.gaugeMarkedFull &&
                item.mileage != null &&
                item.tankCapacityLiters != null,
          )
          .toList();
      if (full.length >= 2) {
        final first = full.first;
        final last = full.last;
        final litersBetween = fuelings
            .where(
              (item) =>
                  item.date.isAfter(first.date) &&
                  !item.date.isAfter(last.date),
            )
            .fold<double>(0, (sum, item) => sum + item.liters);
        final distance = last.mileage! - first.mileage!;
        final average = litersBetween > 0 ? distance / litersBetween : 0.0;
        final capacity = last.tankCapacityLiters!;
        final traveled = active.mileage - last.mileage!;
        final remaining = capacity - (average > 0 ? traveled / average : 0);
        if (average > 0 && traveled >= 0 && remaining <= capacity * .2) {
          await notificationService.addUnique(
            key: 'fuel-low-${last.id}',
            title: tr.fuelLowTitle,
            message: tr.fuelLowText(active.nickname),
            category: 'fuelLow',
          );
        }
      }
    }
    final notifications = await notificationService.loadNotifications();
    if (mounted) {
      setState(() {
        unreadNotifications = notifications.where((item) => !item.read).length;
      });
    }
  }

  Future<void> openNotifications() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
    );
    final notifications = await notificationService.loadNotifications();
    if (mounted) {
      setState(
        () => unreadNotifications = notifications
            .where((item) => !item.read)
            .length,
      );
    }
  }

  Future<void> openVehicles() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const VehiclesScreen()),
    );
    if (!mounted) return;
    await loadActiveVehicle();
  }

  Future<void> openFuelingHistory() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const FuelingHistoryScreen()),
    );
  }

  Future<void> openMaintenances() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const MaintenanceScreen()),
    );
  }

  Future<void> openDocuments() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const DocumentsScreen()),
    );
  }

  Future<void> openReports() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const ReportsScreen()),
    );
  }

  Future<void> openEstablishments() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const EstablishmentsScreen()),
    );
  }

  Future<void> openExpenses({VehicleExpenseCategory? category}) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ExpensesScreen(initialCategory: category),
      ),
    );
    if (mounted) await refreshDashboardData(activeVehicle);
  }

  Future<void> openFuelingForm() async {
    final vehicle = activeVehicle;
    if (vehicle == null) {
      _message(tr.homeNeedVehicle);
      return;
    }
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => FuelingFormScreen(vehicle: vehicle),
      ),
    );
    if (changed == true && mounted) await loadActiveVehicle();
  }

  Future<void> openMaintenanceForm() async {
    final vehicle = activeVehicle;
    if (vehicle == null) {
      _message(tr.homeNeedVehicle);
      return;
    }
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => MaintenanceFormScreen(vehicle: vehicle),
      ),
    );
    if (changed == true && mounted) await loadActiveVehicle();
  }

  Future<void> showNewEntryDialog() async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => _NewEntrySheet(
        onFueling: () {
          Navigator.pop(sheetContext);
          openFuelingForm();
        },
        onMaintenance: () {
          Navigator.pop(sheetContext);
          openMaintenanceForm();
        },
        onInsurance: () {
          Navigator.pop(sheetContext);
          openExpenses(category: VehicleExpenseCategory.insurance);
        },
        onInstallment: () {
          Navigator.pop(sheetContext);
          openExpenses(category: VehicleExpenseCategory.financing);
        },
        onOther: () {
          Navigator.pop(sheetContext);
          openExpenses(category: VehicleExpenseCategory.other);
        },
      ),
    );
  }

  Future<void> showMoreMenu() async {
    // Adianta o carregamento do vídeo premiado, para ele estar pronto se o
    // usuário escolher "ficar sem anúncios em tela cheia".
    // No teto do período sem anúncios outro vídeo não somaria tempo.
    final adFreeActive = AdsService.instance.adFreeActive;
    final adFreeAtLimit = AdsService.instance.adFreeAtLimit;
    if (rewardedOfferAvailable && !adFreeAtLimit) {
      AdsService.instance.loadRewarded();
    }
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
        children: [
          ListTile(
            title: Text(
              tr.moreOptions,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          // Vídeo premiado: horas sem anúncios em tela cheia. Com o período
          // ativo, mostra o tempo restante e permite somar outro vídeo; só
          // fica desabilitado quando o período já está no teto.
          if (rewardedOfferAvailable)
            _MoreMenuTile(
              icon: Icons.ondemand_video_rounded,
              title: adFreeActive
                  ? tr.adFreeMenuActive(adFreeRemainingHours())
                  : tr.adFreeMenuTitle(AdsConfig.instance.rewardedAdFreeHours),
              subtitle: !adFreeActive
                  ? tr.adFreeMenuSubtitle
                  : adFreeAtLimit
                  ? tr.adFreeMenuActiveSubtitle
                  : tr.adFreeMenuAddMore(
                      AdsConfig.instance.rewardedAdFreeHours,
                    ),
              onTap: adFreeAtLimit
                  ? null
                  : () {
                      Navigator.pop(sheetContext);
                      watchRewardedForAdFree(context);
                    },
            ),
          _MoreMenuTile(
            icon: Icons.support_agent_rounded,
            title: tr.supportTitle,
            onTap: () => _closeAndOpen(
              sheetContext,
              () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(builder: (_) => const SupportScreen()),
              ),
            ),
          ),
          _MoreMenuTile(
            icon: Icons.garage_rounded,
            title: tr.vehiclesTitle,
            onTap: () => _closeAndOpen(sheetContext, openVehicles),
          ),
          _MoreMenuTile(
            icon: Icons.account_balance_wallet_outlined,
            title: tr.expensesTitle,
            onTap: () => _closeAndOpen(sheetContext, () => openExpenses()),
          ),
          _MoreMenuTile(
            icon: Icons.bar_chart_rounded,
            title: tr.reportsTitle,
            onTap: () => _closeAndOpen(sheetContext, openReports),
          ),
          _MoreMenuTile(
            icon: Icons.place_outlined,
            title: tr.placesTitle,
            onTap: () => _closeAndOpen(sheetContext, openEstablishments),
          ),
          _MoreMenuTile(
            icon: Icons.description_outlined,
            title: tr.docsTitle,
            onTap: () => _closeAndOpen(sheetContext, openDocuments),
          ),
          _MoreMenuTile(
            icon: Icons.import_export_rounded,
            title: tr.exportTitle,
            onTap: () => _closeAndOpen(sheetContext, openDataTransfer),
          ),
          _MoreMenuTile(
            icon: Icons.star_outline_rounded,
            title: tr.rateApp,
            onTap: () {
              Navigator.pop(sheetContext);
              rateApp();
            },
          ),
          if (AdsService.instance.privacyOptionsRequired)
            _MoreMenuTile(
              icon: Icons.privacy_tip_outlined,
              title: tr.adsPrivacy,
              onTap: () {
                Navigator.pop(sheetContext);
                AdsService.instance.showPrivacyOptions().then((error) {
                  if (error != null && mounted) _message(error);
                });
              },
            ),
        ],
      ),
    );
  }

  void _closeAndOpen(BuildContext sheetContext, Future<void> Function() open) {
    Navigator.pop(sheetContext);
    open();
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
  );

  @override
  void dispose() {
    monthController.dispose();
    super.dispose();
  }

  Future<void> openDataTransfer() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const DataTransferScreen()),
    );
    if (mounted) await loadActiveVehicle();
  }

  Future<void> rateApp() async {
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.requestReview();
      } else {
        await review.openStoreListing();
      }
    } on Object {
      // API da loja indisponível: não bloquear o usuário por isso.
    }
  }

  Future<void> openSubscription() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const SubscriptionScreen()),
    );
  }

  Future<void> openAccount() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const AccountScreen()),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: AppColors.navy,
      foregroundColor: Colors.white,
      title: const Text(
        'MyCarApp',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      actions: [
        if (!AccessService.freeModeEnabled)
          IconButton(
            tooltip: 'MyCarApp Premium',
            onPressed: openSubscription,
            icon: const Icon(Icons.workspace_premium_outlined),
          ),
        IconButton(
          tooltip: tr.accountTitle,
          onPressed: openAccount,
          icon: const Icon(Icons.account_circle_outlined),
        ),
        IconButton(
          tooltip: tr.notifTitle,
          onPressed: openNotifications,
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_none_rounded),
              if (unreadNotifications > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        _BrandHero(vehicle: activeVehicle, onVehicleTap: openVehicles),
        const SizedBox(height: 18),
        _DashboardStats(
          fuelings: fuelings,
          maintenances: maintenances,
          expenses: expenses,
          vehicle: activeVehicle,
          onViewByStation: openReports,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 285,
          child: PageView.builder(
            controller: monthController,
            itemBuilder: (_, index) => _MonthlyCostCard(
              month: DateTime(
                DateTime.now().year,
                DateTime.now().month + index - monthPageOrigin,
              ),
              fuelings: fuelings,
              maintenances: maintenances,
              expenses: expenses,
              onPrevious: () => monthController.previousPage(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOut,
              ),
              onNext: () => monthController.nextPage(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOut,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const RecommendationBanner(),
        const PremiumUpsellBanner(placement: UpsellPlacement.home),
      ],
    ),
    bottomNavigationBar: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const FreeUserBannerAd(placement: BannerPlacement.home),
        _HomeBottomBar(
          onHome: () {},
          onFuelings: openFuelingHistory,
          onNewEntry: showNewEntryDialog,
          onMaintenance: openMaintenances,
          onMore: showMoreMenu,
        ),
      ],
    ),
  );
}

String _homeDate(DateTime value) => formatDate(value);

class _BrandHero extends StatelessWidget {
  const _BrandHero({required this.vehicle, required this.onVehicleTap});
  final Vehicle? vehicle;
  final VoidCallback onVehicleTap;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF06182E), AppColors.navy, AppColors.blue],
      ),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: AppColors.navy.withValues(alpha: .2),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: Stack(
      children: [
        Positioned(
          right: -55,
          top: -70,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: .04),
            ),
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onVehicleTap,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  _ActiveVehicleImage(vehicle: vehicle),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr.activeVehicle,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          vehicle?.nickname ?? tr.selectVehicle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (vehicle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${vehicle!.brand} ${vehicle!.model} • ${vehicle!.mileage} km',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.swap_horiz_rounded, color: Colors.white70),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _ActiveVehicleImage extends StatelessWidget {
  const _ActiveVehicleImage({required this.vehicle});

  final Vehicle? vehicle;

  @override
  Widget build(BuildContext context) {
    final decodedSize = (54 * MediaQuery.devicePixelRatioOf(context)).ceil();
    final photo = vehicle == null || vehicle!.photos.isEmpty
        ? null
        : vehicle!.photos.first;
    final fallback = ColoredBox(
      color: AppColors.gold.withValues(alpha: .17),
      child: Icon(
        vehicle == null ? Icons.garage_outlined : vehicleTypeIcon(vehicle!),
        color: AppColors.goldLight,
        size: 29,
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 54,
        height: 54,
        child: photo == null
            ? fallback
            : Image.file(
                File(photo.path),
                fit: BoxFit.cover,
                cacheWidth: decodedSize,
                cacheHeight: decodedSize,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
  }
}

class _DashboardStats extends StatelessWidget {
  const _DashboardStats({
    required this.fuelings,
    required this.maintenances,
    required this.expenses,
    required this.vehicle,
    required this.onViewByStation,
  });

  final List<FuelingRecord> fuelings;
  final List<MaintenanceRecord> maintenances;
  final List<VehicleExpense> expenses;
  final Vehicle? vehicle;
  final VoidCallback onViewByStation;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final month = DateTime(now.year, now.month);
    final monthlyFuelings = fuelings.where(
      (item) => _sameMonth(item.date, month),
    );
    final fuelTotal = monthlyFuelings.fold<double>(
      0,
      (sum, item) => sum + item.totalPrice,
    );
    final liters = monthlyFuelings.fold<double>(
      0,
      (sum, item) => sum + item.liters,
    );
    final maintenanceTotal = maintenances
        .where((item) => item.isCompleted && _sameMonth(item.date, month))
        .fold<double>(0, (sum, item) => sum + item.totalCost);
    final expenseTotal = expenses
        .where((item) => item.occursIn(month))
        .fold<double>(0, (sum, item) => sum + item.amount);
    final consumption = _lastConsumption(fuelings);
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.7,
      children: [
        _DashboardMetric(
          icon: Icons.account_balance_wallet_outlined,
          label: tr.homeSpentMonth,
          value: _dashboardMoney(fuelTotal + maintenanceTotal + expenseTotal),
        ),
        _DashboardMetric(
          icon: Icons.speed_rounded,
          label: tr.homeLastConsumption,
          value: consumption == null
              ? '-- km/L'
              : '${_dashboardDecimal(consumption)} km/L',
        ),
        _DashboardMetric(
          icon: Icons.local_gas_station_outlined,
          label: tr.homeAveragePriceStations,
          value: liters == 0
              ? '-- /L'
              : '${_dashboardMoney(fuelTotal / liters)}/L',
          onTap: onViewByStation,
        ),
        _DashboardMetric(
          icon: Icons.build_circle_outlined,
          label: tr.maintNext,
          value: _nextMaintenance(maintenances, vehicle),
        ),
      ],
    );
  }
}

class _DashboardMetric extends StatelessWidget {
  const _DashboardMetric({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(17),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0xFFE1E7EE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.blue, size: 22),
            const SizedBox(height: 6),
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
    ),
  );
}

class _MonthlyCostCard extends StatelessWidget {
  const _MonthlyCostCard({
    required this.month,
    required this.fuelings,
    required this.maintenances,
    required this.expenses,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final List<FuelingRecord> fuelings;
  final List<MaintenanceRecord> maintenances;
  final List<VehicleExpense> expenses;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final fuel = fuelings
        .where((item) => _sameMonth(item.date, month))
        .fold<double>(0, (sum, item) => sum + item.totalPrice);
    final maintenance = maintenances
        .where((item) => item.isCompleted && _sameMonth(item.date, month))
        .fold<double>(0, (sum, item) => sum + item.totalCost);
    final inMonth = expenses.where((item) => item.occursIn(month));
    final insurance = inMonth
        .where(
          (item) =>
              item.category == VehicleExpenseCategory.insurance ||
              item.category == VehicleExpenseCategory.cooperative,
        )
        .fold<double>(0, (sum, item) => sum + item.amount);
    final installments = inMonth
        .where(
          (item) =>
              item.category == VehicleExpenseCategory.financing ||
              item.category == VehicleExpenseCategory.consortium,
        )
        .fold<double>(0, (sum, item) => sum + item.amount);
    final other = inMonth
        .where((item) => item.category == VehicleExpenseCategory.other)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final total = fuel + maintenance + insurance + installments + other;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFE1E7EE)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: tr.previousMonth,
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _dashboardMonth(month),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      tr.homeMonthSpending,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: tr.nextMonth,
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const Divider(height: 10),
          _MonthlyCostRow(
            label: tr.homeMonthTotal,
            value: total,
            emphasized: true,
          ),
          _MonthlyCostRow(label: tr.fuel, value: fuel),
          _MonthlyCostRow(label: tr.maintenance, value: maintenance),
          _MonthlyCostRow(label: tr.homeInsurance, value: insurance),
          _MonthlyCostRow(label: tr.homeFinancing, value: installments),
          if (other > 0)
            _MonthlyCostRow(label: tr.homeOtherExpenses, value: other),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.swipe_rounded, size: 15, color: AppColors.muted),
              const SizedBox(width: 5),
              Text(
                tr.homeSwipeMonths,
                style: const TextStyle(color: AppColors.muted, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthlyCostRow extends StatelessWidget {
  const _MonthlyCostRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });
  final String label;
  final double value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: emphasized ? AppColors.text : AppColors.muted,
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          _dashboardMoney(value),
          style: TextStyle(
            color: emphasized ? AppColors.blue : AppColors.text,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _NewEntrySheet extends StatelessWidget {
  const _NewEntrySheet({
    required this.onFueling,
    required this.onMaintenance,
    required this.onInsurance,
    required this.onInstallment,
    required this.onOther,
  });
  final VoidCallback onFueling;
  final VoidCallback onMaintenance;
  final VoidCallback onInsurance;
  final VoidCallback onInstallment;
  final VoidCallback onOther;

  @override
  Widget build(BuildContext context) => ListView(
    shrinkWrap: true,
    padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
    children: [
      Text(
        tr.homeNewEntry,
        style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
      ),
      Text(tr.homeWhatToRecord, style: const TextStyle(color: AppColors.muted)),
      const SizedBox(height: 14),
      _SheetSection(tr.homeVehicleUse),
      _NewEntryTile(
        icon: Icons.local_gas_station_outlined,
        title: tr.ocrFueling,
        subtitle: tr.homeFuelingHint,
        onTap: onFueling,
      ),
      _NewEntryTile(
        icon: Icons.build_circle_outlined,
        title: tr.maintenance,
        subtitle: tr.homeMaintHint,
        onTap: onMaintenance,
      ),
      _SheetSection(tr.homeVehicleExpenses),
      _NewEntryTile(
        icon: Icons.shield_outlined,
        title: tr.homeInsuranceEntry,
        subtitle: tr.homeInsuranceHint,
        onTap: onInsurance,
      ),
      _NewEntryTile(
        icon: Icons.account_balance_outlined,
        title: tr.homeFinancingEntry,
        subtitle: tr.homeFinancingHint,
        onTap: onInstallment,
      ),
      _NewEntryTile(
        icon: Icons.receipt_long_outlined,
        title: tr.expenseOther,
        subtitle: tr.homeOtherHint,
        onTap: onOther,
      ),
    ],
  );
}

class _SheetSection extends StatelessWidget {
  const _SheetSection(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 10, 4, 3),
    child: Text(
      text,
      style: const TextStyle(
        color: AppColors.muted,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: .7,
      ),
    ),
  );
}

class _NewEntryTile extends StatelessWidget {
  const _NewEntryTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    leading: Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.blue.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: AppColors.blue),
    ),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
    subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );
}

bool _sameMonth(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;

double? _lastConsumption(List<FuelingRecord> source) {
  final records = [...source]..sort((a, b) => a.date.compareTo(b.date));
  int? previousMileage;
  double intervalLiters = 0;
  double? latest;
  for (final record in records) {
    if (previousMileage != null) intervalLiters += record.liters;
    if (!record.fullTank ||
        !record.gaugeMarkedFull ||
        record.mileage == null ||
        record.tankCapacityLiters == null) {
      continue;
    }
    if (previousMileage != null &&
        record.mileage! > previousMileage &&
        intervalLiters > 0) {
      latest = (record.mileage! - previousMileage) / intervalLiters;
    }
    previousMileage = record.mileage;
    intervalLiters = 0;
  }
  return latest;
}

String _nextMaintenance(List<MaintenanceRecord> records, Vehicle? vehicle) {
  if (vehicle == null) return '--';
  final candidates = <({int distance, String label})>[];
  final now = DateTime.now();
  for (final record in records) {
    if (record.nextMileage != null) {
      final remaining = record.nextMileage! - vehicle.mileage;
      candidates.add((
        distance: remaining,
        label: remaining <= 0 ? tr.maintOverdue : '$remaining km',
      ));
    }
    if (record.nextDate != null) {
      final remaining = record.nextDate!.difference(now).inDays;
      candidates.add((
        distance: remaining,
        label: remaining <= 0 ? tr.maintOverdue : tr.daysCount(remaining),
      ));
    }
  }
  if (candidates.isEmpty) return '--';
  candidates.sort((a, b) => a.distance.compareTo(b.distance));
  return candidates.first.label;
}

String _dashboardMoney(double value) => formatMoney(value);
String _dashboardDecimal(double value) => formatDecimal(value);
String _dashboardMonth(DateTime month) {
  final text = formatMonthYear(month);
  return text[0].toUpperCase() + text.substring(1);
}

class _HomeBottomBar extends StatelessWidget {
  const _HomeBottomBar({
    required this.onHome,
    required this.onFuelings,
    required this.onNewEntry,
    required this.onMaintenance,
    required this.onMore,
  });

  final VoidCallback onHome;
  final VoidCallback onFuelings;
  final VoidCallback onNewEntry;
  final VoidCallback onMaintenance;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    elevation: 14,
    child: SafeArea(
      top: false,
      child: SizedBox(
        height: 68,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BottomDestination(
              icon: Icons.home_rounded,
              label: tr.navHome,
              selected: true,
              onTap: onHome,
            ),
            _BottomDestination(
              icon: Icons.local_gas_station_outlined,
              label: tr.navFuelings,
              onTap: onFuelings,
            ),
            _BottomDestination(
              icon: Icons.add_rounded,
              label: tr.navNew,
              emphasized: true,
              onTap: onNewEntry,
            ),
            _BottomDestination(
              icon: Icons.build_circle_outlined,
              label: tr.maintTitle,
              onTap: onMaintenance,
            ),
            _BottomDestination(
              icon: Icons.grid_view_rounded,
              label: tr.navMore,
              onTap: onMore,
            ),
          ],
        ),
      ),
    ),
  );
}

class _BottomDestination extends StatelessWidget {
  const _BottomDestination({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.emphasized = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: emphasized ? 42 : 34,
            height: emphasized ? 36 : 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: emphasized
                  ? AppColors.gold
                  : selected
                  ? AppColors.blue.withValues(alpha: .1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              size: emphasized ? 27 : 23,
              color: emphasized
                  ? AppColors.navy
                  : selected
                  ? AppColors.blue
                  : AppColors.muted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            style: TextStyle(
              color: selected ? AppColors.blue : AppColors.muted,
              fontSize: 9,
              fontWeight: selected || emphasized
                  ? FontWeight.w800
                  : FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

class _MoreMenuTile extends StatelessWidget {
  const _MoreMenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  // Nulo deixa o item desabilitado (ex.: período sem anúncios já ativo).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    enabled: onTap != null,
    leading: Icon(
      icon,
      color: onTap == null ? AppColors.muted : AppColors.blue,
    ),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
    subtitle: subtitle == null
        ? null
        : Text(subtitle!, style: const TextStyle(fontSize: 12)),
    trailing: onTap == null ? null : const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );
}
