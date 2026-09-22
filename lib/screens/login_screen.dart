import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../services/authentication_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_logo.dart';
import '../widgets/institutional_footer.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool signingIn = false;

  void _start(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _signInWithGoogle() async {
    if (signingIn) return;
    setState(() => signingIn = true);
    try {
      await AuthenticationService.instance.signInWithGoogle();
      if (mounted) _start(context);
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyError(error)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => signingIn = false);
    }
  }

  String _friendlyError(Object error) {
    if (error is GoogleSignInException) {
      return switch (error.code) {
        GoogleSignInExceptionCode.clientConfigurationError ||
        GoogleSignInExceptionCode.providerConfigurationError =>
          'Não foi possível validar o acesso com Google. Tente novamente em alguns instantes.',
        GoogleSignInExceptionCode.interrupted =>
          'A entrada com Google foi interrompida. Tente novamente.',
        GoogleSignInExceptionCode.canceled =>
          'Entrada com Google interrompida. Se você escolheu uma conta, tente novamente em instantes.',
        _ => 'Não foi possível entrar com Google. Tente novamente.',
      };
    }
    if (error is FirebaseAuthException) {
      if (error.code == 'network-request-failed') {
        return 'Verifique sua conexão e tente novamente.';
      }
      if (error.code == 'account-exists-with-different-credential') {
        return 'Esta conta já usa outra forma de entrada.';
      }
    }
    final value = error.toString().toLowerCase();
    if (value.contains('canceled') || value.contains('cancelled')) {
      return 'Entrada com Google cancelada.';
    }
    if (value.contains('network')) {
      return 'Verifique sua conexão e tente novamente.';
    }
    return 'Não foi possível entrar com Google. Tente novamente.';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.navy,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            const AppLogo(size: 112),
            const SizedBox(height: 24),
            const Text(
              'MyCarApp',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'GESTÃO VEICULAR INTELIGENTE',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.goldLight,
                fontSize: 10,
                letterSpacing: 1.35,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: signingIn ? null : _signInWithGoogle,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.navy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: signingIn
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.account_circle_outlined),
                label: Text(
                  signingIn ? 'ENTRANDO...' : 'ENTRAR COM GOOGLE',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: signingIn ? null : () => _start(context),
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
              child: const Text('CONTINUAR SEM CONTA'),
            ),
            const SizedBox(height: 4),
            const Text(
              'A conta será necessária para indicações, descontos e recursos Premium.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 8),
            const InstitutionalFooter(),
          ],
        ),
      ),
    ),
  );
}
