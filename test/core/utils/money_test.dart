import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastegi/core/utils/formatters.dart';
import 'package:gastegi/core/utils/money.dart';
import 'package:gastegi/l10n/generated/app_localizations.dart';

import '../../helpers/test_db.dart';

void main() {
  setUpAll(initTestLocale);

  late MoneyLabels es;
  late MoneyLabels en;

  setUp(() async {
    es = MoneyLabels(await AppLocalizations.delegate.load(const Locale('es')));
    en = MoneyLabels(await AppLocalizations.delegate.load(const Locale('en')));
  });

  test('format pone la moneda con el patrón del idioma', () {
    expect(es.format(1234.56), '1.234,56 €');
    expect(en.format(1234.56), '€1,234.56');
  });

  test('los decimales están siempre, aunque el importe sea redondo', () {
    expect(es.format(1234.5), '1.234,50 €');
    expect(es.format(480), '480,00 €');
    expect(es.format(0), '0,00 €');
  });

  test('el espacio antes del símbolo es duro', () {
    // U+00A0 sale del patrón del CLDR y evita que el símbolo caiga solo a la
    // línea siguiente. Quien lo "arregle" con un espacio normal rompe esto sin
    // que se note a ojo, y las aserciones de los tests de widget dejan de
    // encontrar el importe.
    expect(es.format(1), contains(' €'));
    expect(es.format(1), isNot(contains(' €')));
  });

  test('el menos va delante del todo en los dos idiomas', () {
    expect(es.formatSigned(-12.3), '−12,30 €');
    expect(en.formatSigned(-12.3), '−€12.30');
    expect(es.formatSigned(12.3), '12,30 €');
  });

  test('los separadores y afijos salen del idioma', () {
    expect(es.decimalSeparator, ',');
    expect(es.groupSeparator, '.');
    expect(es.symbolPrefix, '');
    expect(es.symbolSuffix, ' €');
    expect(en.decimalSeparator, '.');
    expect(en.groupSeparator, ',');
    expect(en.symbolPrefix, '€');
    expect(en.symbolSuffix, '');
  });

  test('typed enseña lo tecleado sin completar decimales', () {
    // Formatear el `double` parseado destruiría estos estados intermedios:
    // `12.` se vería `12` y `12.50` se vería `12,5`.
    expect(es.typed(''), '0 €');
    expect(es.typed('12'), '12 €');
    expect(es.typed('12.'), '12, €');
    expect(es.typed('12.5'), '12,5 €');
    expect(es.typed('1234.50'), '1.234,50 €');
    expect(es.typed('-1234.50'), '−1.234,50 €');
    expect(en.typed('1234.50'), '€1,234.50');
    expect(en.typed('-1234.50'), '−€1,234.50');
  });

  test('typedNumber deja el campo vacío vacío', () {
    // Si devolviera `0`, el hint del campo no llegaría a verse nunca.
    expect(es.typedNumber(''), '');
    expect(es.typedNumber('-'), '−');
    expect(es.typedNumber('1234.5'), '1.234,5');
    expect(en.typedNumber('1234.5'), '1,234.5');
  });

  test('canonical entiende el texto del idioma', () {
    expect(es.canonical('1.234,56'), '1234.56');
    expect(en.canonical('1,234.56'), '1234.56');
    expect(es.canonical('12,'), '12.');
    expect(es.canonical(''), '');
  });

  test('canonical recorta a los topes de dígitos', () {
    expect(es.canonical('12,999'), '12.99');
    expect(es.canonical('9' * (maxIntegerDigits + 2)), '9' * maxIntegerDigits);
  });

  test('canonical solo admite el signo si se le permite y abre el texto', () {
    expect(es.canonical('−12,5', allowNegative: true), '-12.5');
    expect(es.canonical('-12,5', allowNegative: true), '-12.5');
    expect(es.canonical('-12,5'), '12.5');
    expect(es.canonical('12-5', allowNegative: true), '125');
  });
}
