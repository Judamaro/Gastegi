import 'package:flutter_test/flutter_test.dart';
import 'package:gastegi/app/theme/app_colors.dart';
import 'package:gastegi/core/storage/seed.dart';

/// La paleta de categorías es un catálogo de valores sueltos: nada de lo que
/// hay aquí falla al compilar si se rompe, y el síntoma —un formulario que abre
/// sin ninguna muestra marcada— es de los que se ven tarde.
void main() {
  final palette = AppColors.categoryPalette.map((c) => c.toARGB32()).toList();

  test('la paleta son 31 colores distintos', () {
    expect(palette, hasLength(31));
    // Un repetido marcaría dos muestras a la vez: `_ColorOption` decide cuál
    // está activa comparando ARGB, no posiciones.
    expect(palette.toSet(), hasLength(palette.length));
  });

  test('el color de partida de una categoría nueva está en la paleta', () {
    expect(palette, contains(AppColors.defaultCategoryColorValue));
  });

  test('los colores de la siembra están en la paleta', () {
    // Si no, editar una categoría recién sembrada abriría el selector sin nada
    // elegido, y el primer toque cambiaría el color sin que se pidiera.
    for (final (name, color, _, _) in initialCategories) {
      expect(palette, contains(color), reason: name);
    }
  });

  test('las seis de la siembra no repiten color', () {
    final colors = initialCategories.map((c) => c.$2).toSet();
    expect(colors, hasLength(initialCategories.length));
  });
}
