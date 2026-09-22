import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';

/// URL institucional da Giles Desenvolvimento de Softwares.
///
/// Deve apontar para uma página **sem** oferta/checkout de assinatura: a
/// política de pagamentos do Google Play proíbe que o app Android leve o
/// usuário para uma cobrança fora da loja. Se a home do site tiver botão de
/// assinatura, troque esta constante por uma página institucional dedicada
/// antes do lançamento (pendência registrada na trilha de implementação,
/// seção "Perguntas em aberto").
const institutionalSiteUrl = 'https://gilessoftwares.com.br';

/// Rodapé "Desenvolvido por Giles Desenvolvimento de Softwares", com o
/// domínio tocável abrindo o navegador externo do sistema (nunca WebView).
/// Reutilizado na tela de login e em Ajustes (Seção 2 do guia de
/// planejamento da próxima atualização).
class InstitutionalFooter extends StatelessWidget {
  const InstitutionalFooter({super.key, this.dark = true});

  /// true = texto claro, para uso sobre fundo escuro (login).
  /// false = texto escuro, para uso sobre fundo claro (Ajustes).
  final bool dark;

  Future<void> _open() async {
    unawaited(
      FirebaseAnalytics.instance.logEvent(name: 'institutional_site_tap'),
    );
    final uri = Uri.parse(institutionalSiteUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = dark ? Colors.white54 : AppColors.muted;
    final linkColor = dark ? AppColors.goldLight : AppColors.blue;
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _open,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text.rich(
              TextSpan(
                style: TextStyle(color: baseColor, fontSize: 11),
                children: [
                  const TextSpan(
                    text:
                        'Desenvolvido por Giles Desenvolvimento de Softwares\n',
                  ),
                  TextSpan(
                    text: 'gilessoftwares.com.br',
                    style: TextStyle(
                      color: linkColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
