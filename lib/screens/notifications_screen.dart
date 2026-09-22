import 'package:flutter/material.dart';

import '../models/app_notification.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final service = NotificationService();
  List<AppNotification> notifications = const [];
  bool loading = true;
  NotificationPreferences preferences = const NotificationPreferences();

  @override
  void initState() {
    super.initState();
    load();
    service.requestPermission();
  }

  Future<void> load() async {
    final results = await Future.wait<Object?>([
      service.loadNotifications(),
      service.loadPreferences(),
    ]);
    final items = results[0] as List<AppNotification>;
    await service.markAllRead();
    if (!mounted) return;
    setState(() {
      notifications = items;
      preferences = results[1] as NotificationPreferences;
      loading = false;
    });
  }

  Future<void> openPreferences() async {
    var current = preferences;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          Future<void> update(NotificationPreferences value) async {
            setSheetState(() => current = value);
            setState(() => preferences = value);
            await service.savePreferences(value);
            if (value.anyEnabled) await service.requestPermission();
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Personalizar notificações',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Escolha quais alertas deseja receber neste aparelho.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 14),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Todas as notificações',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      current.allEnabled
                          ? 'Todas ativadas'
                          : current.anyEnabled
                          ? 'Algumas ativadas'
                          : 'Todas desativadas',
                    ),
                    value: current.allEnabled,
                    activeThumbColor: AppColors.blue,
                    onChanged: (value) => update(
                      NotificationPreferences(
                        updates: value,
                        maintenance: value,
                        fuelLow: value,
                        overfill: value,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => update(
                            const NotificationPreferences(
                              updates: false,
                              maintenance: false,
                              fuelLow: false,
                              overfill: false,
                            ),
                          ),
                          child: const Text('DESATIVAR TODAS'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: () =>
                              update(const NotificationPreferences()),
                          child: const Text('ATIVAR TODAS'),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  _PreferenceSwitch(
                    title: 'Novidades e atualizações',
                    icon: Icons.new_releases_outlined,
                    value: current.updates,
                    onChanged: (value) =>
                        update(current.copyWith(updates: value)),
                  ),
                  _PreferenceSwitch(
                    title: 'Próximas manutenções',
                    icon: Icons.build_circle_outlined,
                    value: current.maintenance,
                    onChanged: (value) =>
                        update(current.copyWith(maintenance: value)),
                  ),
                  _PreferenceSwitch(
                    title: 'Combustível próximo de 20%',
                    icon: Icons.local_gas_station_outlined,
                    value: current.fuelLow,
                    onChanged: (value) =>
                        update(current.copyWith(fuelLow: value)),
                  ),
                  _PreferenceSwitch(
                    title: 'Abastecimento inadequado',
                    icon: Icons.warning_amber_rounded,
                    value: current.overfill,
                    onChanged: (value) =>
                        update(current.copyWith(overfill: value)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> clear() async {
    await service.clear();
    if (mounted) setState(() => notifications = const []);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: AppColors.navy,
      foregroundColor: Colors.white,
      title: const Text('Notificações'),
      actions: [
        IconButton(
          tooltip: 'Personalizar notificações',
          onPressed: openPreferences,
          icon: const Icon(Icons.tune_rounded),
        ),
        if (notifications.isNotEmpty)
          IconButton(
            tooltip: 'Limpar notificações',
            onPressed: clear,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
      ],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : notifications.isEmpty
        ? const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  size: 66,
                  color: AppColors.muted,
                ),
                SizedBox(height: 14),
                Text(
                  'Nenhuma notificação',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, _) => const SizedBox(height: 9),
            itemBuilder: (context, index) {
              final item = notifications[index];
              return Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: item.read ? const Color(0xFFE1E7EE) : AppColors.gold,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(_icon(item.key), color: AppColors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.message,
                            style: const TextStyle(
                              color: AppColors.muted,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _date(item.createdAt),
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
  );
}

class _PreferenceSwitch extends StatelessWidget {
  const _PreferenceSwitch({
    required this.title,
    required this.icon,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    secondary: Icon(icon, color: AppColors.blue),
    title: Text(title),
    value: value,
    activeThumbColor: AppColors.blue,
    onChanged: onChanged,
  );
}

IconData _icon(String key) {
  if (key.startsWith('maintenance')) return Icons.build_circle_outlined;
  if (key.startsWith('fuel')) return Icons.local_gas_station_outlined;
  return Icons.new_releases_outlined;
}

String _date(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
