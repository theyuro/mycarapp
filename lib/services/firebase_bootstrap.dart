import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class FirebaseBootstrap {
  const FirebaseBootstrap._();

  static Future<void> initialize() async {
    await Firebase.initializeApp();

    if (defaultTargetPlatform == TargetPlatform.android) {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: kDebugMode
            ? const AndroidDebugProvider()
            : const AndroidPlayIntegrityProvider(),
      );
    }

    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      !kDebugMode,
    );
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // Vincula Analytics e Crashlytics ao UID do Firebase (nunca ao e-mail),
    // para acompanhar uso e erros por usuário.
    FirebaseAuth.instance.authStateChanges().listen((user) {
      final uid = user?.uid;
      FirebaseAnalytics.instance.setUserId(id: uid).ignore();
      FirebaseCrashlytics.instance.setUserIdentifier(uid ?? '').ignore();
    });
  }
}
