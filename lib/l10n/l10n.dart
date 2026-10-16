import 'dart:ui';

import 'package:intl/intl.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

/// Idiomas do app: português do Brasil (padrão) e inglês. Qualquer idioma
/// que não seja português usa o inglês.
const supportedAppLocales = [Locale('pt'), Locale('en')];

Locale resolveAppLocale(Locale? device) =>
    device?.languageCode == 'pt' ? const Locale('pt') : const Locale('en');

AppLocalizations _current = lookupAppLocalizations(
  resolveAppLocale(PlatformDispatcher.instance.locale),
);

/// Textos traduzidos do app. Funciona também fora de widgets (serviços,
/// notificações), por isso é global; o MaterialApp atualiza quando o idioma
/// do aparelho muda.
AppLocalizations get tr => _current;

void updateAppLocale(Locale locale) =>
    _current = lookupAppLocalizations(resolveAppLocale(locale));

/// Localidade completa do aparelho (ex.: pt_BR, en_US), usada para
/// formatar números, moeda e datas como o usuário está acostumado.
String get _formatLocale {
  final device = PlatformDispatcher.instance.locale;
  if (device.languageCode == 'pt') return 'pt_BR';
  final tag = device.countryCode == null ? 'en' : 'en_${device.countryCode}';
  return NumberFormat.localeExists(tag) ? tag : 'en';
}

/// Valor em dinheiro: "R$ 1.234,56" no Brasil, "$1,234.56" nos EUA.
String formatMoney(double value) =>
    NumberFormat.simpleCurrency(locale: _formatLocale).format(value);

/// Número com casas decimais fixas: "12,35" ou "12.35".
String formatDecimal(double value, [int digits = 2]) =>
    NumberFormat.decimalPatternDigits(
      locale: _formatLocale,
      decimalDigits: digits,
    ).format(value);

/// Número inteiro com separador de milhar: "12.345" ou "12,345".
String formatInteger(num value) =>
    NumberFormat.decimalPattern(_formatLocale).format(value.round());

/// Data curta: "31/12/2026" ou "12/31/2026".
String formatDate(DateTime value) =>
    DateFormat.yMd(_formatLocale).format(value);

/// Dia e mês: "31/12" ou "12/31".
String formatDayMonth(DateTime value) =>
    DateFormat.Md(_formatLocale).format(value);

/// Hora: "14:05" ou "2:05 PM".
String formatTime(DateTime value) => DateFormat.jm(_formatLocale).format(value);

/// Mês e ano por extenso: "dezembro de 2026" ou "December 2026".
String formatMonthYear(DateTime value) =>
    DateFormat.yMMMM(_formatLocale).format(value);

/// Mês abreviado: "dez." ou "Dec".
String formatShortMonth(DateTime value) =>
    DateFormat.MMM(_formatLocale).format(value);

/// Símbolo da moeda local, para prefixo de campos de valor: "R$" ou "$".
String get currencySymbol =>
    NumberFormat.simpleCurrency(locale: _formatLocale).currencySymbol;

/// Número para preencher um campo de edição (sem separador de milhar):
/// "12,50" em português, "12.50" em inglês. Os campos aceitam vírgula ou
/// ponto na leitura.
String formatInput(double value, [int digits = 2]) {
  final text = value.toStringAsFixed(digits);
  return tr.localeName == 'pt' ? text.replaceAll('.', ',') : text;
}
