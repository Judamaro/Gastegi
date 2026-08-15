/// Reglas de los importes que no dependen del idioma.
///
/// Lo que sí depende —los separadores, el símbolo y su sitio— vive en
/// `money.dart`, igual que `date_labels.dart` está separado de `date_utils.dart`.
library;

/// Dígitos como máximo a cada lado del separador decimal.
///
/// Un solo tope para las tres vías de entrada: el teclado propio del gasto y
/// los campos de saldo y de transferencia. Con dos decimales, `999.999.999,99`.
///
/// Subirlo alarga la cifra más larga que la app puede llegar a pintar, que es
/// la que decide si las pantallas desbordan: al tocarlo hay que mover con él
/// los importes de los tests de desbordamiento, o dejarían de probar el peor
/// caso sin que nada avise.
const int maxIntegerDigits = 9;
const int maxFractionDigits = 2;

/// Menos tipográfico (U+2212).
///
/// El CLDR devuelve el guion ASCII, más corto y más alto que las cifras: en un
/// importe grande se lee como un tropiezo. `AppData.deltaLabel` ya usa este.
const String minusSign = '−';

/// Token de borrado del teclado propio.
///
/// Vive aquí y no en el widget porque quien lo interpreta es el estado, y así
/// el notifier no tiene que importar una pantalla para reconocer una tecla.
const String backspaceKey = '⌫';

/// Separador decimal del texto *canónico*: el que guardan los notifiers.
///
/// Es siempre el punto, pase lo que pase con el idioma. Un notifier no tiene
/// `BuildContext` y no puede saber si la coma de `12,5` es decimal o de miles;
/// la traducción a los separadores del idioma la hace la página.
const String canonicalDecimalPoint = '.';

/// Porcentaje entero de [part] sobre [whole]; 0 si [whole] no es positivo.
///
/// Sin esta guarda, una app recién instalada calcula `0 / 0` y el
/// `double.nan.round()` resultante lanza `UnsupportedError`.
int percentOf(double part, double whole) =>
    whole > 0 ? (part / whole * 100).round() : 0;

/// Importe canónico para prellenar un campo editable.
///
/// Con los dos decimales puestos, que es lo que la app enseña siempre: si se
/// prellenara `100.5`, el campo mostraría un importe que no existe en pantalla.
String canonicalAmount(double n) => n.toStringAsFixed(maxFractionDigits);

/// Lee un importe canónico.
///
/// La coma no aparece por ninguna parte a propósito: quien teclea la coma es el
/// usuario, y `MoneyLabels.canonical` la traduce antes de que el texto llegue al
/// estado. El punto colgante de `12.` —el campo a medio escribir— se recorta
/// aquí porque de este valor depende si el botón de guardar está activo.
double parseAmount(String raw) =>
    double.tryParse(
      raw.endsWith(canonicalDecimalPoint)
          ? raw.substring(0, raw.length - 1)
          : raw,
    ) ??
    0;
