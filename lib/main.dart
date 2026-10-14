import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'l10n/l10n.dart';
import 'screens/presentation_screen.dart';
import 'services/access_service.dart';
import 'services/ads_config.dart';
import 'services/ads_service.dart';
import 'services/auto_backup_service.dart';
import 'services/firebase_bootstrap.dart';
import 'services/update_service.dart';
import 'theme/app_colors.dart';
import 'widgets/force_update_gate.dart';
import 'widgets/premium_after_ad_sheet.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.initialize();
  await initializeDateFormatting();
  await AccessService.instance.initialize();
  AutoBackupService.instance.start();
  unawaited(UpdateService.instance.start());
  AdsService.instance.onInterstitialDismissed = () {
    final context = _navigatorKey.currentContext;
    if (context != null) unawaited(showPremiumAfterAdSheet(context));
  };
  // Limites dos anúncios vindos do Remote Config: busca em segundo plano e,
  // até responder (ou se falhar), valem os padrões locais.
  AdsConfig.instance.initialize();
  unawaited(AdsService.instance.initialize());
  runApp(const MyCarApp());
}

class MyCarApp extends StatelessWidget {
  const MyCarApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'MyCarApp',
    navigatorKey: _navigatorKey,
    supportedLocales: supportedAppLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    localeResolutionCallback: (device, _) {
      final locale = resolveAppLocale(device);
      updateAppLocale(locale);
      return locale;
    },
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.blue,
        primary: AppColors.blue,
        secondary: AppColors.gold,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
        ),
      ),
    ),
    builder: (context, child) =>
        ForceUpdateGate(child: child ?? const SizedBox.shrink()),
    home: const PresentationScreen(),
  );
}
