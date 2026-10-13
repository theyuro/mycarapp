import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'access_service.dart';

/// Mantém os usuários na versão mais recente.
///
/// - Ao abrir o app, se a Google Play tiver uma versão nova, abre a tela de
///   atualização da própria Play (atualização imediata).
/// - O servidor define um build mínimo (`appConfig/public.minimumBuild`,
///   devolvido por `getAppAccess`). Abaixo dele o app fica bloqueado em
///   [updateRequired] até o usuário atualizar. Para obrigar todos a
///   atualizar, basta subir esse número depois de publicar a versão.
class UpdateService extends ChangeNotifier {
  UpdateService._();
  static final UpdateService instance = UpdateService._();

  static const storeUrl =
      'https://play.google.com/store/apps/details?id=com.gilesdesenvolvimento.mycarapp';

  int? _installedBuild;
  bool _started = false;
  bool _offeredThisSession = false;

  /// Versão instalada abaixo do mínimo exigido pelo servidor.
  bool get updateRequired {
    final installed = _installedBuild;
    final minimum = AccessService.instance.minimumBuild;
    return installed != null && minimum != null && installed < minimum;
  }

  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      final info = await PackageInfo.fromPlatform();
      _installedBuild = int.tryParse(info.buildNumber);
    } on Object catch (error) {
      debugPrint('Não foi possível ler a versão instalada: $error');
    }
    AccessService.instance.addListener(notifyListeners);
    notifyListeners();
    unawaited(_offerPlayUpdate());
  }

  /// Abre a atualização imediata da Google Play, se houver versão nova.
  Future<void> _offerPlayUpdate() async {
    if (_offeredThisSession ||
        kDebugMode ||
        defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    _offeredThisSession = true;
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable &&
          info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
      }
    } on Object catch (error) {
      // Instalado fora da Play (debug, APK manual) ou Play indisponível.
      debugPrint('Atualização pela Play indisponível: $error');
    }
  }

  /// Botão "Atualizar" da tela de bloqueio: tenta o fluxo da Play e, se não
  /// der, abre a página do app na loja.
  Future<void> updateNow() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable &&
          info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
        return;
      }
    } on Object catch (error) {
      debugPrint('Atualização pela Play indisponível: $error');
    }
    await launchUrl(Uri.parse(storeUrl), mode: LaunchMode.externalApplication);
  }
}
