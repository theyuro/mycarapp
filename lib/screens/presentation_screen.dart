import 'dart:async';
import 'package:flutter/material.dart';
import '../services/authentication_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_logo.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import '../l10n/l10n.dart';

class PresentationScreen extends StatefulWidget {
  const PresentationScreen({super.key});
  @override
  State<PresentationScreen> createState() => _PresentationScreenState();
}

class _PresentationScreenState extends State<PresentationScreen> {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 3), _openLogin);
  }

  // O app exige conta: quem já entrou vai direto para a Home; os demais
  // passam obrigatoriamente pelo login.
  bool _opening = false;

  Future<void> _openLogin() async {
    if (!mounted || _opening) return;
    _opening = true;
    _timer?.cancel();
    final signedIn = AuthenticationService.instance.currentUser != null;
    final Widget next = signedIn ? const HomeScreen() : const LoginScreen();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, _) =>
            FadeTransition(opacity: animation, child: next),
        transitionDuration: const Duration(milliseconds: 650),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.navy,
    body: InkWell(
      onTap: _openLogin,
      child: SizedBox.expand(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const Spacer(flex: 3),
                const AppLogo(size: 138),
                const SizedBox(height: 22),
                const Text(
                  'MyCarApp',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tr.appTagline,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.goldLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 20),
                Container(width: 48, height: 3, color: AppColors.gold),
                const Spacer(flex: 4),
                Text(
                  tr.presentationSlogan,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
                const SizedBox(height: 18),
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
