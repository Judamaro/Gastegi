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

  static bool _isDigit(String ch) {
    final code = ch.codeUnitAt(0);
    return code >= 0x30 && code <= 0x39;
  }
}
