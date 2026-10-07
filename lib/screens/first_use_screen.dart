import 'package:flutter/material.dart';

import '../models/vehicle.dart';
import '../services/vehicle_storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_logo.dart';
import 'fueling_form_screen.dart';
import 'home_screen.dart';
import 'vehicle_registration_screen.dart';

/// Tela inicial após o login: quem ainda não tem veículo passa pelo guia de
/// primeiro uso; os demais vão direto para a Home.
Future<Widget> startScreenAfterLogin() async {
  try {
    final vehicles = await VehicleStorageService().loadVehicles();
    if (vehicles.isNotEmpty) return const HomeScreen();
  } on Object {
    // Arquivo ilegível: a Home já trata esse caso.
    return const HomeScreen();
  }
  return const FirstUseScreen();
}

/// Guia de primeiro uso: boas-vindas, cadastro do primeiro veículo e
/// orientações para os primeiros registros.
class FirstUseScreen extends StatefulWidget {
  const FirstUseScreen({super.key});

  @override
  State<FirstUseScreen> createState() => _FirstUseScreenState();
}

class _FirstUseScreenState extends State<FirstUseScreen> {
  static const _stepCount = 3;

  final storage = VehicleStorageService();
  int step = 0;
  Vehicle? vehicle;

  Future<void> registerVehicle() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const VehicleRegistrationScreen(),
      ),
    );
    if (saved != true || !mounted) return;
    final active = await storage.loadActiveVehicle();
    if (!mounted) return;
    setState(() {
      vehicle = active;
      step = 2;
    });
  }

  void openHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  Future<void> registerFirstFueling() async {
    final active = vehicle;
    if (active == null) return openHome();
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => FuelingFormScreen(vehicle: active),
      ),
    );
    if (mounted) openHome();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.navy,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StepIndicator(current: step, count: _stepCount),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: switch (step) {
                  0 => _welcomeStep(),
                  1 => _vehicleStep(),
                  _ => _readyStep(),
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _welcomeStep() => _StepBody(
    key: const ValueKey(0),
    header: const AppLogo(size: 96),
    title: 'Bem-vindo ao MyCarApp!',
    message:
        'Em poucos passos você deixa tudo pronto para acompanhar consumo, '
        'manutenções e gastos do seu veículo.',
    items: const [
      (Icons.local_gas_station_outlined, 'Abastecimentos e consumo médio'),
      (Icons.build_circle_outlined, 'Manutenções com lembretes'),
      (Icons.receipt_long_outlined, 'Despesas e relatórios'),
    ],
    primaryLabel: 'VAMOS COMEÇAR',
    onPrimary: () => setState(() => step = 1),
  );

  Widget _vehicleStep() => _StepBody(
    key: const ValueKey(1),
    header: const _StepIcon(Icons.directions_car_filled_outlined),
    title: 'Cadastre seu veículo',
    message:
        'Informe apelido, marca, modelo, ano, combustível e a quilometragem '
        'atual. Fotos e documentos são opcionais e podem ser incluídos depois.',
    items: const [
      (Icons.speed_outlined, 'A quilometragem atual é usada no consumo médio'),
      (Icons.edit_outlined, 'Você pode editar tudo depois em Veículos'),
    ],
    primaryLabel: 'CADASTRAR MEU VEÍCULO',
    onPrimary: registerVehicle,
    secondaryLabel: 'FAZER DEPOIS',
    onSecondary: openHome,
  );

  Widget _readyStep() => _StepBody(
    key: const ValueKey(2),
    header: const _StepIcon(Icons.check_circle_outline),
    title: vehicle == null
        ? 'Tudo pronto!'
        : '${vehicle!.nickname} está pronto!',
    message: 'Veja como registrar o dia a dia do seu veículo:',
    items: const [
      (
        Icons.add_circle_outline,
        'Toque em Novo, na barra inferior, para lançar abastecimento, '
            'manutenção ou despesa',
      ),
      (
        Icons.more_horiz_rounded,
        'Em Mais ficam relatórios, documentos, despesas e ajuda',
      ),
      (
        Icons.notifications_none_outlined,
        'O sino mostra lembretes de manutenção e novidades',
      ),
    ],
    primaryLabel: 'REGISTRAR PRIMEIRO ABASTECIMENTO',
    onPrimary: registerFirstFueling,
    secondaryLabel: 'IR PARA O INÍCIO',
    onSecondary: openHome,
  );
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.count});

  final int current;
  final int count;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          for (var index = 0; index < count; index++) ...[
            if (index > 0) const SizedBox(width: 6),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 4,
                decoration: BoxDecoration(
                  color: index <= current ? AppColors.gold : Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ],
      ),
      const SizedBox(height: 8),
      Text(
        'Passo ${current + 1} de $count',
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
    ],
  );
}

class _StepIcon extends StatelessWidget {
  const _StepIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 96,
    height: 96,
    decoration: const BoxDecoration(
      color: AppColors.navyLight,
      shape: BoxShape.circle,
    ),
    child: Icon(icon, size: 52, color: AppColors.gold),
  );
}

class _StepBody extends StatelessWidget {
  const _StepBody({
    super.key,
    required this.header,
    required this.title,
    required this.message,
    required this.items,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final Widget header;
  final String title;
  final String message;
  final List<(IconData, String)> items;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 32),
          child: Column(
            children: [
              header,
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 24),
              for (final (icon, text) in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    children: [
                      Icon(icon, color: AppColors.goldLight, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 56,
        child: FilledButton(
          onPressed: onPrimary,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: AppColors.navy,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            primaryLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
      if (secondaryLabel != null) ...[
        const SizedBox(height: 8),
        TextButton(
          onPressed: onSecondary,
          style: TextButton.styleFrom(foregroundColor: Colors.white70),
          child: Text(secondaryLabel!),
        ),
      ],
    ],
  );
}
