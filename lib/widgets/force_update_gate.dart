import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../services/update_service.dart';
import '../theme/app_colors.dart';
import 'app_logo.dart';

/// Cobre o app inteiro com o pedido de atualização quando a versão instalada
/// está abaixo do mínimo definido no servidor.
class ForceUpdateGate extends StatelessWidget {
  const ForceUpdateGate({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: UpdateService.instance,
    builder: (context, _) => UpdateService.instance.updateRequired
        ? const _ForceUpdateScreen()
        : child,
  );
}

class _ForceUpdateScreen extends StatelessWidget {
  const _ForceUpdateScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.navy,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const Spacer(),
            const AppLogo(size: 96),
            const SizedBox(height: 28),
            Text(
              tr.forceUpdateTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              tr.forceUpdateText,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, height: 1.4),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                onPressed: UpdateService.instance.updateNow,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.navy,
                ),
                icon: const Icon(Icons.system_update_rounded),
                label: Text(tr.forceUpdateButton),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    ),
  );
}
