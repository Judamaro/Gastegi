import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastegi/core/utils/money.dart';
import 'package:gastegi/core/utils/money_input_formatter.dart';
import 'package:gastegi/l10n/generated/app_localizations.dart';

import '../../helpers/test_db.dart';

/// Lo que tendría el campo con [text] tecleado y el cursor en [cursor]
/// (al final si no se dice otra cosa).
TextEditingValue _value(String text, [int? cursor]) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: cursor ?? text.length),
);

void main() {
  setUpAll(initTestLocale);

  late MoneyInputFormatter es;
  late MoneyInputFormatter signed;

  setUp(() async {
    final money = MoneyLabels(
      await AppLocalizations.delegate.load(const Locale('es')),
    );
    es = MoneyInputFormatter(money);
    signed = MoneyInputFormatter(money, allowNegative: true);
  });

  test('agrupa los miles según se teclea, con el cursor al final', () {
    final result = es.formatEditUpdate(_value('123'), _value('1234'));
    expect(result.text, '1.234');
    expect(result.selection.baseOffset, 5);
  });

  test('al insertar en medio, el cursor se queda tras el dígito escrito', () {
    // '1.234' con el cursor tras el 2, se teclea un 9: '1.2934' → '12.934'.
    final result = es.formatEditUpdate(_value('1.234'), _value('1.2934', 4));
    expect(result.text, '12.934');
    // Tras el 9 recién escrito, que en '12.934' cae en la posición 4: el
    // separador se ha movido y una posición absoluta habría fallado.
    expect(result.selection.baseOffset, 4);
  });

  test('borrar sobre un separador de miles se lleva el dígito de al lado', () {
    // Sin esto la tecla de borrado parecería muerta: el separador se repondría
    // intacto porque ningún dígito ha cambiado.
    final result = es.formatEditUpdate(_value('1.234'), _value('1234', 1));
    expect(result.text, '234');
  });

  test('respeta el tope de dos decimales', () {
    final result = es.formatEditUpdate(_value('12,34'), _value('12,345'));
    expect(result.text, '12,34');
  });

  test('el campo vacío se queda vacío, para que se vea el hint', () {
    final result = es.formatEditUpdate(_value('1'), _value(''));
    expect(result.text, '');
  });

  test('el signo solo pasa donde se permite', () {
    expect(signed.formatEditUpdate(_value(''), _value('-12')).text, '−12');
    expect(es.formatEditUpdate(_value(''), _value('-12')).text, '12');
  });
}
