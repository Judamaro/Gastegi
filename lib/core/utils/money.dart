import 'package:gastegi/app/config/app_config.dart';
import 'package:gastegi/core/utils/formatters.dart';
import 'package:gastegi/l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';

/// Importes escritos para el usuario.
///
/// Siempre en la moneda de [AppConfig.currencyCode], con el patrón del idioma
/// activo: `1.234,56 €` en español y `€1,234.56` en inglés. Separado de
/// `formatters.dart`, que son las reglas sin idioma, igual que
/// `date_labels.dart` lo está de `date_utils.dart`.
///
/// La frontera con el estado: un notifier guarda texto **canónico**
/// (`[-]?dígitos[.dígitos]`, sin miles ni símbolo) y es la página la que lo
/// traduce con [typed] o [typedNumber], y de vuelta con [canonical].
class MoneyLabels {
  const MoneyLabels(this._l10n);

  final AppLocalizations _l10n;

  /// Construir un `NumberFormat` reparsea el patrón del idioma, y la pantalla
  /// de inicio formatea una docena de importes por frame. Con dos idiomas este
  /// mapa nunca pasa de dos entradas.
  static final Map<String, _MoneyFormats> _cache = {};

  _MoneyFormats get _f => _cache.putIfAbsent(
    _l10n.localeName,
    () => _MoneyFormats(_l10n.localeName),
  );

  /// `1.234,56 €`. Siempre con los dos decimales.
  String format(double n) => _f.currency.format(n);

  /// Igual, con el menos tipográfico delante del todo si el importe es
  /// negativo: `−1.234,56 €` en español y `−€1,234.56` en inglés.
  ///
  /// Delante del todo y no delante de la cifra porque así vale para los dos
  /// idiomas sin saber de qué lado cae el símbolo.
  String formatSigned(double n) =>
      n < 0 ? '$minusSign${format(-n)}' : format(n);

  /// Separador decimal del idioma, para la tecla del teclado propio.
  String get decimalSeparator => _f.currency.symbols.DECIMAL_SEP;

  /// Separador de miles del idioma: lo pone la app, no el usuario, y por eso
  /// el formateador de entrada lo trata aparte al recolocar el cursor.
  String get groupSeparator => _f.currency.symbols.GROUP_SEP;

  /// Lo que va antes y después de la cifra: en español `''` y `' €'`, en
  /// inglés `'€'` y `''`. Sirve para decorar un campo de texto sin meter el
  /// símbolo dentro de lo editable.
  String get symbolPrefix => _f.prefix;
  String get symbolSuffix => _f.suffix;

  /// Lo tecleado hasta ahora, con símbolo y con el cero de partida.
  ///
  /// Para el visor del nuevo gasto, donde un importe vacío se enseña como cero.
  String typed(String canonical) {
    final negative = canonical.startsWith('-');
    final body = negative ? canonical.substring(1) : canonical;
    return '${negative ? minusSign : ''}'
        '$symbolPrefix${_grouped(body)}$symbolSuffix';
  }

  /// Lo tecleado hasta ahora, sin símbolo y sin cero de relleno.
  ///
  /// Para el contenido de un campo de texto: si estuviera vacío y devolviera
  /// `0`, el hint no llegaría a verse nunca.
  String typedNumber(String canonical) {
    if (canonical.isEmpty) return '';
    final negative = canonical.startsWith('-');
    final body = negative ? canonical.substring(1) : canonical;
    // Solo el signo, todavía sin cifras: se deja tal cual para no plantar un
    // cero que el usuario no ha escrito.
    if (body.isEmpty) return minusSign;
    return '${negative ? minusSign : ''}${_grouped(body)}';
  }

  /// Texto del idioma → canónico, aplicando los topes de dígitos.
  ///
  /// Solo el **primer** separador decimal cuenta; los de miles, el símbolo y
  /// cualquier otra cosa se descartan. El signo únicamente si abre el texto.
  String canonical(String text, {bool allowNegative = false}) {
    final integer = StringBuffer();
    final fraction = StringBuffer();
    var negative = false;
    var afterPoint = false;

    for (var i = 0; i < text.length; i++) {
      final ch = text[i];
      if (ch == decimalSeparator) {
        afterPoint = true;
      } else if (_isDigit(ch)) {
        if (afterPoint) {
          if (fraction.length < maxFractionDigits) fraction.write(ch);
        } else if (integer.length < maxIntegerDigits) {
          integer.write(ch);
        }
      } else if (allowNegative &&
          !afterPoint &&
          integer.isEmpty &&
          (ch == '-' || ch == minusSign)) {
        negative = true;
      }
    }

    if (integer.isEmpty && !afterPoint) return negative ? '-' : '';
    return '${negative ? '-' : ''}$integer'
        '${afterPoint ? '$canonicalDecimalPoint$fraction' : ''}';
  }

  /// La cifra sin signo: la parte entera agrupada y la decimal copiada tal
  /// cual.
  ///
  /// No formatea el `double` parseado a propósito: eso destruiría los estados
  /// intermedios del tecleo —`12.` se vería `12`, y `12.50` se vería `12,5`—.
  String _grouped(String body) {
    final at = body.indexOf(canonicalDecimalPoint);
    final integer = at < 0 ? body : body.substring(0, at);
    final grouped = _f.grouping.format(int.tryParse(integer) ?? 0);
    return at < 0
        ? grouped
        : '$grouped$decimalSeparator${body.substring(at + 1)}';
  }

  static bool _isDigit(String ch) {
    final code = ch.codeUnitAt(0);
    return code >= 0x30 && code <= 0x39;
  }
}

/// Los tres formatos que hacen falta por idioma, calculados una sola vez.
class _MoneyFormats {
  _MoneyFormats(String locale)
    : currency = NumberFormat.simpleCurrency(
        locale: locale,
        name: AppConfig.currencyCode,
        decimalDigits: maxFractionDigits,
      ),
      grouping = NumberFormat.decimalPattern(locale) {
    // El símbolo y su sitio salen de partir un cero formateado por donde está
    // la cifra: detrás y con espacio duro en español, delante y pegado en
    // inglés. Deducirlo evita escribir el símbolo —o el espacio duro— a mano.
    final zero = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: maxFractionDigits,
    ).format(0);
    final formatted = currency.format(0);
    final at = formatted.indexOf(zero);
    prefix = formatted.substring(0, at);
    suffix = formatted.substring(at + zero.length);
  }

  final NumberFormat currency;
  final NumberFormat grouping;
  late final String prefix;
  late final String suffix;
}
