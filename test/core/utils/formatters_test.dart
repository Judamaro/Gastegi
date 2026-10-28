import 'package:flutter_test/flutter_test.dart';
import 'package:gastegi/core/utils/formatters.dart';

void main() {
  test('percentOf se defiende de la app recién instalada', () {
    // Sin la guarda, 0/0 da NaN y `NaN.round()` lanza `UnsupportedError`.
    expect(percentOf(0, 0), 0);
    expect(percentOf(50, 200), 25);
  });

  test('canonicalAmount prellena con los dos decimales de siempre', () {
    expect(canonicalAmount(100.5), '100.50');
    expect(canonicalAmount(-1234.5), '-1234.50');
    expect(canonicalAmount(0), '0.00');
  });

  test('parseAmount lee el campo a medio escribir', () {
    // `12.` es el estado real del campo justo después de pulsar la coma, y de
    // este valor depende si el botón de guardar está activo.
    expect(parseAmount('12.'), 12);
    expect(parseAmount('1234.56'), 1234.56);
    expect(parseAmount('-100.50'), -100.5);
    expect(parseAmount(''), 0);
    expect(parseAmount('-'), 0);
  });
}
