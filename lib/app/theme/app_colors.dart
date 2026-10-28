import 'package:flutter/widgets.dart';

/// Paleta del sistema de diseño Nocturne (tema oscuro), portada de styles.css.
abstract final class AppColors {
  static const Color bg = Color(0xFF161826);
  static const Color surface = Color(0xFF232532);
  static const Color text = Color(0xFFE9E9ED);
  static const Color accent = Color(0xFF9184D9);
  static const Color divider = Color(0x29E9E9ED); // text al 16 %

  static const Color neutral100 = Color(0xFFF3F5FE);
  static const Color neutral200 = Color(0xFFE4E7F5);
  static const Color neutral300 = Color(0xFFCFD3E5);
  static const Color neutral400 = Color(0xFFB2B6CA);
  static const Color neutral500 = Color(0xFF9397AB);
  static const Color neutral600 = Color(0xFF75798C);
  static const Color neutral700 = Color(0xFF595D6C);
  static const Color neutral800 = Color(0xFF3F424D);
  static const Color neutral900 = Color(0xFF292B31);

  static const Color accent100 = Color(0xFFF5F4FF);
  static const Color accent200 = Color(0xFFE7E5FE);
  static const Color accent300 = Color(0xFFD2CEFD);
  static const Color accent400 = Color(0xFFB5ABFC);
  static const Color accent500 = Color(0xFF968AE0);
  static const Color accent600 = Color(0xFF796CBF);
  static const Color accent700 = Color(0xFF5D5294);
  static const Color accent800 = Color(0xFF423A6A);
  static const Color accent900 = Color(0xFF2B2741);

  /// Colores elegibles al crear o editar una categoría.
  ///
  /// Una rueda de tono de treinta pasos más el blanco. No sale de la escala
  /// `accent`/`neutral`: aquélla son tokens del sistema de diseño y cambia con
  /// él, mientras que esto es un catálogo de elección del usuario, y el color
  /// que elija queda guardado en su base de datos.
  ///
  /// La luminosidad va alta a propósito. Estos colores se pintan sobre `bg` y
  /// `surface`, que son oscuros, y en porciones de dona de pocos píxeles: un
  /// tono apagado ahí no se distingue del de al lado.
  static const List<Color> categoryPalette = [
    Color(0xFFCD3D3E),
    Color(0xFFCB593F),
    Color(0xFFCD763D),
    Color(0xFFCF933D),
    Color(0xFFCFB23E),
    Color(0xFFD1D040),
    Color(0xFFB4D13E),
    Color(0xFF96D13E),
    Color(0xFF7BD140),
    Color(0xFF5DD240),
    Color(0xFF3FD53F),
    Color(0xFF3FD55C),
    Color(0xFF41D67D),
    Color(0xFF40D799),
    Color(0xFF41D6B9),
    Color(0xFF42D8D8),
    Color(0xFF41BBD8),
    Color(0xFF419DDA),
    Color(0xFF407EDC),
    Color(0xFF4360DD),
    Color(0xFF4241DE),
    Color(0xFF6142DE),
    Color(0xFF8242E0),
    Color(0xFFA142DF),
    Color(0xFFC142E0),
    Color(0xFFE242E4),
    Color(0xFFE242C2),
    Color(0xFFE343A5),
    Color(0xFFE34383),
    Color(0xFFE54465),
    Color(0xFFFFFFFF),
  ];

  /// Color de partida de una categoría nueva.
  ///
  /// Un valor de [categoryPalette] y no uno cualquiera: el selector marca la
  /// muestra comparando ARGB, así que un color de fuera abriría el formulario
  /// sin nada elegido. Lo vigila `test/app/theme/category_palette_test.dart`.
  static const int defaultCategoryColorValue = 0xFFCD3D3E;
}
