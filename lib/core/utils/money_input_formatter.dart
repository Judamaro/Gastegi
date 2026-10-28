import 'package:flutter/services.dart';
import 'package:gastegi/core/utils/money.dart';

/// Reescribe lo tecleado como importe del idioma activo, mientras se escribe.
///
/// Trabaja sobre la cifra sin símbolo: el símbolo va como decoración del campo
/// y no como texto editable, para que no sea un carácter que el usuario pueda
/// seleccionar y borrar.
class MoneyInputFormatter extends TextInputFormatter {
  const MoneyInputFormatter(this._money, {this.allowNegative = false});

  final MoneyLabels _money;

  /// Los saldos de una tarjeta de crédito son negativos; un gasto, nunca.
  final bool allowNegative;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;
    var cursor = newValue.selection.end;
    if (cursor < 0 || cursor > text.length) cursor = text.length;

    // Un punto recién tecleado en un idioma que separa decimales con coma es un
    // decimal, no un separador de miles.
    //
    // Los teclados numéricos del móvil ofrecen el punto sea cual sea el idioma,
    // y en español el punto es el separador de miles: sin esto, `12.5` se
    // descartaría a `125` y se guardaría un importe cien veces mayor **sin que
    // nada avise**. El separador de miles no hay que teclearlo nunca —lo pone
    // este formateador desde la primera cifra—, así que un punto que escribe el
    // usuario solo puede querer decir «decimal».
    //
    // Solo el carácter recién insertado: los separadores de miles que ya trae
    // el texto los ha puesto la app en la pasada anterior, y traducirlos
    // convertiría `1.234` en un importe con tres decimales.
    if (_money.decimalSeparator != _typedDecimalPoint &&
        text.length == oldValue.text.length + 1 &&
        cursor > 0 &&
        text[cursor - 1] == _typedDecimalPoint) {
      text = text.replaceRange(cursor - 1, cursor, _money.decimalSeparator);
    }

    // Borrar un separador de miles no cambia ningún dígito: se repondría
    // intacto y la tecla de borrado parecería muerta. Cuando pasa, se borra el
    // dígito de su izquierda, que es lo que el usuario quería.
    if (text.length < oldValue.text.length &&
        _digitsOf(text) == _digitsOf(oldValue.text)) {
      final at = _lastDigitBefore(text, cursor);
      if (at >= 0) {
        text = text.replaceRange(at, at + 1, '');
        cursor = at;
      }
    }

    final formatted = _money.typedNumber(
      _money.canonical(text, allowNegative: allowNegative),
    );

    // El cursor se recoloca contando lo que escribió el usuario, no
    // caracteres: al teclear, los separadores de miles se desplazan, y una
    // posición absoluta dejaría el cursor detrás del punto equivocado.
    final typed = _typedCount(text.substring(0, cursor));
    var offset = 0;
    var seen = 0;
    while (offset < formatted.length && seen < typed) {
      if (formatted[offset] != _money.groupSeparator) seen++;
      offset++;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: offset),
    );
  }

  /// Lo que pone el usuario. El separador de miles lo pone la app, así que no
  /// cuenta para colocar el cursor.
  int _typedCount(String text) =>
      text.split(_money.groupSeparator).join().length;

  String _digitsOf(String text) => text.split('').where(_isDigit).join();

  int _lastDigitBefore(String text, int cursor) {
    for (var i = cursor - 1; i >= 0; i--) {
      if (_isDigit(text[i])) return i;
    }
    return -1;
  }

  /// El punto que ofrece el teclado numérico del sistema, que no siempre
  /// coincide con el separador decimal del idioma.
  static const String _typedDecimalPoint = '.';

  static bool _isDigit(String ch) {
    final code = ch.codeUnitAt(0);
    return code >= 0x30 && code <= 0x39;
  }
}
