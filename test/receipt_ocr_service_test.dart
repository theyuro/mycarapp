import 'package:flutter_test/flutter_test.dart';
import 'package:my_car_app/services/receipt_ocr_service.dart';

void main() {
  test('extrai os principais dados de uma nota de abastecimento', () {
    const receipt = '''
POSTO AVENIDA LTDA
CNPJ 12.345.678/0001-90
GASOLINA COMUM
QTD: 32,450 L
VL UNIT 5,899
VALOR TOTAL R\$ 191,42
13/08/2026 09:15
''';

    final result = ReceiptOcrService().parse(receipt);

    expect(result.station, 'AVENIDA LTDA');
    expect(result.fuelType, 'Gasolina');
    expect(result.liters, 32.45);
    expect(result.totalPrice, 191.42);
    expect(result.date, DateTime(2026, 8, 13));
  });

  test('não confunde preço unitário com o total', () {
    const receipt = '''
ETANOL
LITROS 20,000
PRECO UNIT 3,999
TOTAL: 79,98
''';

    final result = ReceiptOcrService().parse(receipt);

    expect(result.liters, 20);
    expect(result.totalPrice, 79.98);
    expect(result.fuelType, 'Etanol');
  });
}
