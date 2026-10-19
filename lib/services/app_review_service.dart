import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:path_provider/path_provider.dart';

import 'ads_service.dart';

/// Avaliação do app na Play.
///
/// - Botões "Avaliar" (menu Mais, banner de recomendação, anúncio próprio):
///   abrem direto a página do app na Play com [openStoreListing]. A janela
///   de avaliação dentro do app tem cota e a Play pode não mostrá-la sem
///   avisar, então ela não serve para um botão (orientação da Google).
/// - Janela dentro do app: pedida uma única vez, automaticamente, depois do
///   2º registro novo (veículo, abastecimento ou manutenção), via
///   [registerEvent]. Se houver intersticial na tela, fica para o próximo
///   registro. Se a Play decidir não mostrar, nada acontece.
class AppReviewService {
  AppReviewService._();
  static final AppReviewService instance = AppReviewService._();

  /// Registros novos necessários para pedir a avaliação.
  static const eventsBeforeRequest = 2;

  /// Espera antes de pedir, para o formulário fechar e a tela anterior
  /// aparecer primeiro.
  static const _requestDelay = Duration(milliseconds: 1500);

  int _events = 0;
  bool _requested = false;
  Future<void>? _loaded;

  /// Abre a página do app na Play. Para os botões "Avaliar".
  Future<void> openStoreListing() async {
    try {
      await InAppReview.instance.openStoreListing();
    } on Object {
      // Loja indisponível: não bloquear o usuário por isso.
    }
  }

  /// Conta um registro novo (veículo, abastecimento ou manutenção) e, no
  /// [eventsBeforeRequest]º, pede a janela de avaliação da Play.
  void registerEvent() => unawaited(_registerEvent());

  Future<void> _registerEvent() async {
    try {
      await (_loaded ??= _loadState());
      if (_requested) return;
      _events++;
      await _saveState();
      if (_events < eventsBeforeRequest) return;
      await Future<void>.delayed(_requestDelay);
      // Intersticial na tela ou app fora do primeiro plano: não abre por
      // cima de nada e tenta de novo no próximo registro.
      if (AdsService.instance.fullScreenShowing ||
          WidgetsBinding.instance.lifecycleState !=
              AppLifecycleState.resumed) {
        return;
      }
      _requested = true;
      await _saveState();
      final review = InAppReview.instance;
      if (await review.isAvailable()) await review.requestReview();
    } on Object catch (error) {
      debugPrint('Avaliação: pedido automático falhou ($error).');
    }
  }

  Future<File> _stateFile() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${documents.path}${Platform.pathSeparator}MyCarApp',
    );
    if (!await directory.exists()) await directory.create(recursive: true);
    return File('${directory.path}${Platform.pathSeparator}app_review.json');
  }

  Future<void> _loadState() async {
    try {
      final file = await _stateFile();
      if (!await file.exists()) return;
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      _events = (json['events'] as num?)?.toInt() ?? 0;
      _requested = json['requested'] as bool? ?? false;
    } on Object {
      debugPrint('Estado da avaliação corrompido; reiniciando.');
    }
  }

  Future<void> _saveState() async {
    final file = await _stateFile();
    await file.writeAsString(
      jsonEncode({'events': _events, 'requested': _requested}),
      flush: true,
    );
  }
}
