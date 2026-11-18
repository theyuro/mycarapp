import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../l10n/l10n.dart';

/// Dados já calculados do relatório em PDF. Os números saem dos mesmos
/// cálculos da tela de relatórios (reports_screen.dart monta este objeto),
/// para o PDF não duplicar a lógica nem divergir do que o usuário vê.
class PdfReportData {
  const PdfReportData({
    required this.vehicleName,
    required this.vehicleDetails,
    required this.periodLabel,
    required this.averageConsumption,
    required this.confirmedFillUps,
    required this.fuelTotal,
    required this.fuelLiters,
    required this.maintenanceTotal,
    required this.months,
    required this.costPerKm,
    required this.distance,
    required this.expenseTotal,
    required this.annualProjection,
    required this.stations,
    required this.stationsPeriodLabel,
    required this.onlyBestStation,
    required this.maintenances,
  });

  final String vehicleName;

  /// Marca, modelo, ano, combustível etc., já formatados (linhas curtas).
  final List<String> vehicleDetails;
  final String periodLabel;

  /// km/L médio do período; `null` sem medições.
  final double? averageConsumption;
  final int confirmedFillUps;
  final double fuelTotal;
  final double fuelLiters;
  final double maintenanceTotal;

  /// Gastos por mês, do mais recente ao mais antigo.
  final List<PdfMonthRow> months;

  /// `null` quando ainda não há duas quilometragens no período.
  final double? costPerKm;
  final int? distance;
  final double expenseTotal;
  final double annualProjection;

  /// Postos já ordenados por custo por km. Vazia = a seção fica de fora
  /// (no gratuito, quando o melhor posto não está liberado na sessão).
  final List<PdfStationRow> stations;
  final String stationsPeriodLabel;

  /// Gratuito: só o melhor posto (sem ranking).
  final bool onlyBestStation;
  final List<PdfMaintenanceRow> maintenances;
}

class PdfMonthRow {
  const PdfMonthRow({
    required this.label,
    required this.fuel,
    required this.maintenance,
  });
  final String label;
  final double fuel;
  final double maintenance;
  double get total => fuel + maintenance;
}

class PdfStationRow {
  const PdfStationRow({
    required this.name,
    required this.fuelType,
    required this.consumption,
    required this.costPerKm,
    required this.fillUps,
    this.preliminary = false,
    this.consumptionAlert = false,
  });
  final String name;
  final String fuelType;
  final double consumption;
  final double costPerKm;
  final int fillUps;

  /// Menos de 3 medições com tanque cheio no posto (selo "Preliminar").
  final bool preliminary;

  /// Consumo muito diferente da média geral do veículo.
  final bool consumptionAlert;
}

class PdfMaintenanceRow {
  const PdfMaintenanceRow({
    required this.date,
    required this.category,
    required this.workshop,
    required this.cost,
  });
  final DateTime date;
  final String category;
  final String workshop;
  final double cost;
}

/// Gera o relatório do veículo em PDF (pacote pdf) num arquivo temporário,
/// pronto para compartilhar com share_plus, como a exportação CSV.
class PdfReportService {
  static const _navy = PdfColor.fromInt(0xFF071B33); // AppColors.navy
  static const _muted = PdfColor.fromInt(0xFF6B7889); // AppColors.muted
  static const _line = PdfColor.fromInt(0xFFE1E7EE);

  // Fontes Noto Sans dos assets, lidas uma vez e reaproveitadas nos próximos
  // PDFs. Substituem a Helvetica padrão (só Latin-1) e a antiga troca de
  // caracteres fora do Latin-1.
  static pw.ThemeData? _theme;

  static Future<pw.ThemeData> _loadTheme() async => _theme ??=
      pw.ThemeData.withFont(
        base: pw.Font.ttf(
          await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
        ),
        bold: pw.Font.ttf(
          await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'),
        ),
      );

  Future<File> build(PdfReportData data) async {
    final document = pw.Document(title: tr.pdfTitle, creator: 'MyCarApp');
    final theme = await _loadTheme();
    document.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              tr.pdfFooter(formatDate(DateTime.now())),
              style: const pw.TextStyle(color: _muted, fontSize: 8),
            ),
            pw.Text(
              '${context.pageNumber}/${context.pagesCount}',
              style: const pw.TextStyle(color: _muted, fontSize: 8),
            ),
          ],
        ),
        build: (context) => [
          ..._header(data),
          ..._consumption(data),
          ..._spending(data),
          ..._costPerKm(data),
          ..._stations(data),
          ..._maintenances(data),
        ],
      ),
    );
    final bytes = await document.save();
    final temporary = await getTemporaryDirectory();
    final safeName = data.vehicleName
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
        .toLowerCase();
    final file = File(
      '${temporary.path}${Platform.pathSeparator}mycarapp_relatorio_$safeName.pdf',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  List<pw.Widget> _header(PdfReportData data) => [
    pw.Text(
      tr.pdfTitle,
      style: pw.TextStyle(
        color: _navy,
        fontSize: 20,
        fontWeight: pw.FontWeight.bold,
      ),
    ),
    pw.SizedBox(height: 4),
    pw.Text(
      tr.pdfPeriod(data.periodLabel),
      style: const pw.TextStyle(color: _muted, fontSize: 10),
    ),
    _section(tr.pdfVehicleSection),
    pw.Text(
      data.vehicleName,
      style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
    ),
    for (final line in data.vehicleDetails)
      pw.Text(line, style: const pw.TextStyle(fontSize: 10)),
  ];

  List<pw.Widget> _consumption(PdfReportData data) => [
    _section(tr.reportConsumptionTitle),
    _keyValue(
      tr.reportOverallAverage,
      data.averageConsumption == null
          ? '--'
          : '${formatDecimal(data.averageConsumption!)} km/L',
    ),
    _keyValue(tr.reportConfirmedTanks, '${data.confirmedFillUps}'),
  ];

  List<pw.Widget> _spending(PdfReportData data) => [
    _section(tr.pdfSpendingSection),
    _keyValue(tr.reportFuelTitle, formatMoney(data.fuelTotal)),
    _keyValue(tr.pdfLiters, '${formatDecimal(data.fuelLiters)} L'),
    _keyValue(tr.reportMaintTitle, formatMoney(data.maintenanceTotal)),
    _keyValue(
      tr.pdfTotalAll,
      formatMoney(data.fuelTotal + data.maintenanceTotal),
      bold: true,
    ),
    if (data.months.isNotEmpty) ...[
      pw.SizedBox(height: 8),
      _table(
        [tr.pdfMonthCol, tr.reportFuelTitle, tr.reportMaintTitle, tr.total],
        [
          for (final month in data.months)
            [
              month.label,
              formatMoney(month.fuel),
              formatMoney(month.maintenance),
              formatMoney(month.total),
            ],
        ],
      ),
    ],
  ];

  List<pw.Widget> _costPerKm(PdfReportData data) => [
    _section(tr.reportTotalCostPerKm),
    if (data.distance == null)
      pw.Text(
        tr.reportCostNeedTwo,
        style: const pw.TextStyle(color: _muted, fontSize: 10),
      )
    else ...[
      _keyValue(
        tr.sortCostPerKm,
        data.costPerKm == null ? '--' : '${formatMoney(data.costPerKm!)}/km',
      ),
      _keyValue(tr.pdfDistance, '${formatInteger(data.distance!)} km'),
      _keyValue(tr.pdfExpenses, formatMoney(data.expenseTotal)),
      _keyValue(tr.reportAnnualProjection, formatMoney(data.annualProjection)),
    ],
  ];

  List<pw.Widget> _stations(PdfReportData data) {
    // Gratuito sem o melhor posto liberado na sessão: seção fora do PDF.
    if (data.stations.isEmpty) return const [];
    return [
      _section(data.onlyBestStation ? tr.pdfBestStation : tr.reportByStation),
      pw.Text(
        tr.pdfPeriod(data.stationsPeriodLabel),
        style: const pw.TextStyle(color: _muted, fontSize: 9),
      ),
      pw.SizedBox(height: 6),
      _table(
        [
          tr.pdfStationCol,
          tr.pdfFuelCol,
          'km/L',
          tr.sortCostPerKm,
          tr.pdfFillUpsCol,
        ],
        [
          for (final station in data.stations)
            [
              // Selo "Preliminar" e marca do alerta junto ao nome do posto.
              [
                station.name,
                if (station.preliminary) '(${tr.stationPreliminaryBadge})',
                if (station.consumptionAlert) '(!)',
              ].join(' '),
              station.fuelType,
              formatDecimal(station.consumption),
              station.costPerKm <= 0 ? '--' : formatMoney(station.costPerKm),
              '${station.fillUps}',
            ],
        ],
      ),
      // Explicação do selo e do alerta, só quando algum posto os tiver.
      if (data.stations.any((station) => station.preliminary))
        _note(tr.stationPreliminaryNote),
      if (data.stations.any((station) => station.consumptionAlert))
        _note('(!) ${tr.stationConsumptionAlert}'),
    ];
  }

  pw.Widget _note(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 5),
    child: pw.Text(
      text,
      style: const pw.TextStyle(color: _muted, fontSize: 8.5),
    ),
  );

  List<pw.Widget> _maintenances(PdfReportData data) => [
    _section(tr.pdfMaintenanceList),
    if (data.maintenances.isEmpty)
      pw.Text(
        tr.reportNoMaint,
        style: const pw.TextStyle(color: _muted, fontSize: 10),
      )
    else
      _table(
        [tr.pdfDateCol, tr.pdfServiceCol, tr.pdfWorkshopCol, tr.pdfCostCol],
        [
          for (final item in data.maintenances)
            [
              formatDate(item.date),
              item.category,
              item.workshop,
              formatMoney(item.cost),
            ],
        ],
      ),
  ];

  pw.Widget _section(String title) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 18, bottom: 6),
    child: pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.only(bottom: 3),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _line)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          color: _navy,
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    ),
  );

  pw.Widget _keyValue(String label, String value, {bool bold = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
        child: pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(
                label,
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ],
        ),
      );

  pw.Widget _table(List<String> headers, List<List<String>> rows) =>
      pw.TableHelper.fromTextArray(
        headers: headers,
        data: [
          ...rows,
        ],
        headerStyle: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
        ),
        headerDecoration: const pw.BoxDecoration(color: _navy),
        cellStyle: const pw.TextStyle(fontSize: 9),
        cellAlignment: pw.Alignment.centerLeft,
        border: const pw.TableBorder(
          horizontalInside: pw.BorderSide(color: _line, width: .5),
        ),
      );
}
