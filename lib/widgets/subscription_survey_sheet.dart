import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../l10n/l10n.dart';
import '../screens/exit_offer_screen.dart';
import '../services/access_service.dart';
import '../services/analytics_service.dart';
import '../theme/app_colors.dart';

/// Intervalo mínimo entre dois questionários de saída da assinatura.
const _surveyInterval = Duration(days: 7);

/// Abre o questionário de saída da SubscriptionScreen, se o usuário não for
/// Premium e o último questionário tiver sido há 7 dias ou mais (data
/// guardada localmente). Quando a resposta é "Muito caro" e o servidor
/// concede a oferta de saída, abre a [ExitOfferScreen] em seguida.
///
/// Recebe o [NavigatorState] (e não o contexto da tela de assinatura), porque
/// é chamado enquanto essa tela está saindo.
Future<void> maybeShowSubscriptionSurvey(NavigatorState navigator) async {
  if (AccessService.instance.subscriptionActive) return;
  if (!await _SurveyState.due()) return;
  // Espera a animação de saída da tela de assinatura terminar.
  await Future<void>.delayed(const Duration(milliseconds: 350));
  if (!navigator.mounted || AccessService.instance.subscriptionActive) return;
  await _SurveyState.markShown();
  if (!navigator.mounted) return;
  final expiresAt = await showModalBottomSheet<DateTime>(
    context: navigator.context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (_) => const SubscriptionSurveySheet(),
  );
  if (expiresAt == null || !navigator.mounted) return;
  await navigator.push<void>(
    MaterialPageRoute<void>(
      builder: (_) => ExitOfferScreen(expiresAt: expiresAt),
      settings: const RouteSettings(name: 'exit_offer'),
    ),
  );
}

/// Motivos do questionário; [id] é o valor fixo enviado ao Analytics.
enum _SurveyReason {
  tooExpensive('too_expensive'),
  stillExploring('still_exploring'),
  dontNeed('dont_need'),
  preferOneTime('prefer_one_time'),
  other('other');

  const _SurveyReason(this.id);
  final String id;

  String get label => switch (this) {
    tooExpensive => tr.surveyTooExpensive,
    stillExploring => tr.surveyStillExploring,
    dontNeed => tr.surveyDontNeed,
    preferOneTime => tr.surveyPreferOneTime,
    other => tr.surveyOther,
  };

  String get hint => switch (this) {
    tooExpensive => tr.surveyTooExpensiveHint,
    stillExploring => tr.surveyStillExploringHint,
    dontNeed => tr.surveyDontNeedHint,
    preferOneTime => tr.surveyPreferOneTimeHint,
    other => tr.surveyOtherHint,
  };
}

/// Folha inferior "Antes de você ir…": 5 motivos de escolha única, sem
/// campo de texto (nenhum texto do usuário é enviado). Fecha com o fim da
/// janela da oferta de saída quando ela foi concedida; nos demais casos,
/// mostra o agradecimento e fecha sem resultado.
class SubscriptionSurveySheet extends StatefulWidget {
  const SubscriptionSurveySheet({super.key});

  @override
  State<SubscriptionSurveySheet> createState() =>
      _SubscriptionSurveySheetState();
}

class _SubscriptionSurveySheetState extends State<SubscriptionSurveySheet> {
  _SurveyReason? selected;
  bool sending = false;
  bool answered = false;
  bool thanks = false;

  @override
  void dispose() {
    // Fechou arrastando ou com o voltar, sem responder nem tocar em "Pular".
    if (!answered) AnalyticsService.event('survey_skip');
    super.dispose();
  }

  void _skip() {
    answered = true;
    AnalyticsService.event('survey_skip');
    Navigator.of(context).pop();
  }

  Future<void> _send() async {
    final reason = selected;
    if (reason == null || sending) return;
    answered = true;
    AnalyticsService.event('survey_answer', {'reason': reason.id});
    if (reason == _SurveyReason.tooExpensive) {
      setState(() => sending = true);
      final access = AccessService.instance;
      final expiresAt = await access.claimExitOffer();
      if (expiresAt != null) {
        await access.refreshSubscriptionOffers();
        // Só abre a oferta se a Play devolveu a opção e a janela ainda vale.
        if (mounted &&
            access.exitOfferOption != null &&
            expiresAt.isAfter(DateTime.now())) {
          Navigator.of(context).pop(expiresAt);
          return;
        }
      }
      if (!mounted) return;
    }
    setState(() {
      sending = false;
      thanks = true;
    });
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: thanks ? _thanks() : _questions(),
    ),
  );

  Widget _thanks() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.favorite_rounded, color: AppColors.gold, size: 40),
      const SizedBox(height: 14),
      Text(
        tr.surveyThanks,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.text,
          fontSize: 15,
          height: 1.4,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.navy,
            foregroundColor: Colors.white,
          ),
          child: Text(tr.premiumBackToApp),
        ),
      ),
    ],
  );

  Widget _questions() => SingleChildScrollView(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tr.surveyTitle,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          tr.surveyText,
          style: const TextStyle(color: AppColors.muted, height: 1.4),
        ),
        const SizedBox(height: 16),
        for (final reason in _SurveyReason.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ReasonTile(
              reason: reason,
              selected: selected == reason,
              onTap: sending ? null : () => setState(() => selected = reason),
            ),
          ),
        const SizedBox(height: 8),
        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: selected == null || sending ? null : _send,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.navy,
            ),
            child: sending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    selected == null ? tr.surveyChooseOption : tr.surveySend,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
          ),
        ),
        TextButton(
          onPressed: sending ? null : _skip,
          child: Text(
            tr.surveySkip,
            style: const TextStyle(color: AppColors.muted),
          ),
        ),
      ],
    ),
  );
}

class _ReasonTile extends StatelessWidget {
  const _ReasonTile({
    required this.reason,
    required this.selected,
    required this.onTap,
  });
  final _SurveyReason reason;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: selected ? AppColors.blue.withValues(alpha: .06) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? AppColors.blue : const Color(0xFFE1E7EE),
          width: selected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            selected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_unchecked_rounded,
            color: selected ? AppColors.blue : AppColors.muted,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reason.label,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  reason.hint,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// Data do último questionário exibido, guardada localmente no mesmo padrão
/// de arquivo JSON dos demais estados do app.
abstract final class _SurveyState {
  static Future<File> _file() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${documents.path}${Platform.pathSeparator}MyCarApp',
    );
    if (!await directory.exists()) await directory.create(recursive: true);
    return File(
      '${directory.path}${Platform.pathSeparator}subscription_survey.json',
    );
  }

  static Future<bool> due() async {
    try {
      final file = await _file();
      if (!await file.exists()) return true;
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final last = DateTime.tryParse(json['lastShownAt'] as String? ?? '');
      return last == null || DateTime.now().difference(last) >= _surveyInterval;
    } on Object catch (error) {
      debugPrint('Estado do questionário corrompido; reiniciando: $error');
      return true;
    }
  }

  static Future<void> markShown() async {
    try {
      final file = await _file();
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsString(
        jsonEncode({'lastShownAt': DateTime.now().toIso8601String()}),
        flush: true,
      );
      await temporary.rename(file.path);
    } on Object catch (error) {
      debugPrint('Não foi possível salvar o estado do questionário: $error');
    }
  }
}
