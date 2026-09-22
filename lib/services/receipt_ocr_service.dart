import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ReceiptOcrResult {
  const ReceiptOcrResult({
    this.station,
    this.liters,
    this.totalPrice,
    this.fuelType,
    this.date,
  });

  final String? station;
  final double? liters;
  final double? totalPrice;
  final String? fuelType;
  final DateTime? date;

  bool get hasAnyValue =>
      station != null ||
      liters != null ||
      totalPrice != null ||
      fuelType != null ||
      date != null;
}

class ReceiptOcrService {
  Future<ReceiptOcrResult> recognize(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final recognized = await recognizer.processImage(
        InputImage.fromFilePath(imagePath),
      );
      return parse(recognized.text);
    } finally {
      await recognizer.close();
    }
  }

  ReceiptOcrResult parse(String text) {
    final lines = text
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final normalized = text.toUpperCase();

    return ReceiptOcrResult(
      station: _station(lines),
      liters: _labeledNumber(
        lines,
        RegExp(r'\b(QTD|QTDE|QUANTIDADE|LITROS?|VOLUME)\b'),
        maximum: 500,
      ),
      totalPrice: _total(lines),
      fuelType: _fuelType(normalized),
      date: _date(text),
    );
  }

  String? _station(List<String> lines) {
    final labeled = RegExp(
      r'(?:POSTO|RAZ[AÃ]O SOCIAL|NOME FANTASIA)\s*[:\-]?\s*(.+)',
      caseSensitive: false,
    );
    for (final line in lines) {
      final match = labeled.firstMatch(line);
      final value = match?.group(1)?.trim();
      if (value != null && value.length >= 3) return value;
    }
    for (final line in lines.take(5)) {
      final upper = line.toUpperCase();
      if ((upper.contains('POSTO') || upper.contains('COMBUST')) &&
          !upper.contains('CNPJ') &&
          line.length >= 4) {
        return line;
      }
    }
    return null;
  }

  double? _labeledNumber(List<String> lines, RegExp label, {double? maximum}) {
    for (final line in lines) {
      if (!label.hasMatch(line.toUpperCase())) continue;
      final values = _numbers(line);
      for (final value in values.reversed) {
        if (value > 0 && (maximum == null || value <= maximum)) return value;
      }
    }
    return null;
  }

  double? _total(List<String> lines) {
    const labels = ['VALOR TOTAL', 'TOTAL R\$', 'TOTAL:', 'A PAGAR'];
    for (final label in labels) {
      for (final line in lines.reversed) {
        if (!line.toUpperCase().contains(label)) continue;
        final values = _numbers(line);
        if (values.isNotEmpty && values.last > 0) return values.last;
      }
    }
    return null;
  }

  List<double> _numbers(String line) => RegExp(r'\d{1,6}(?:[.,]\d{2,3})')
      .allMatches(line)
      .map((match) => double.tryParse(match.group(0)!.replaceAll(',', '.')))
      .whereType<double>()
      .toList();

  String? _fuelType(String text) {
    if (text.contains('ETANOL') || text.contains('ALCOOL')) return 'Etanol';
    if (text.contains('DIESEL')) return 'Diesel';
    if (text.contains('GNV')) return 'GNV';
    if (text.contains('GASOLINA')) return 'Gasolina';
    return null;
  }

  DateTime? _date(String text) {
    final match = RegExp(
      r'\b(\d{2})[\/-](\d{2})[\/-](\d{2,4})\b',
    ).firstMatch(text);
    if (match == null) return null;
    final day = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    var year = int.parse(match.group(3)!);
    if (year < 100) year += 2000;
    final value = DateTime(year, month, day);
    if (value.day != day ||
        value.month != month ||
        value.isAfter(DateTime.now())) {
      return null;
    }
    return value;
  }
}
