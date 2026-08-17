import 'package:flutter_test/flutter_test.dart';
import 'package:gastegi/app/theme/app_typography.dart';

void main() {
  group('la cifra que se teclea no se recorta', () {
    // Inter pide 1.205 em de caja de línea —ascendente más descendente—, medido
    // sobre la tipografía real. `hero` aprieta la caja a 1 em: un `Text` pinta
    // el glifo aunque sobresalga, pero un `EditableText` recorta a la suya, y
    // la cifra de «Nuevo gasto» salía sin la parte de arriba.
    //
    // Esto no se puede comprobar pintando: los tests corren sin descargar
    // tipografías y la de repuesto mide 1 em justo, así que ahí no recorta
    // nada. Lo que se fija aquí es el número.
    const interLineHeight = 1.205;

    test('el visor deja sitio a la caja de línea de la tipografía', () {
      expect(
        AppTextStyles.heroInputHeight,
        greaterThanOrEqualTo(interLineHeight),
      );
      expect(AppTextStyles.heroInput(44).height, AppTextStyles.heroInputHeight);
    });

    test('la cifra que solo se lee sigue apretada', () {
      // `hero` no se toca: sus cifras son `Text`, no recortan, y aflojarles la
      // caja separaría el total de Inicio y el patrimonio de Cuentas de lo que
      // llevan al lado.
      expect(AppTextStyles.hero(44).height, 1);
    });

    test('las dos comparten cuerpo e interletrado', () {
      // El símbolo de moneda va en un `Text` al lado del campo: si las métricas
      // se separaran, la cifra y el símbolo dejarían de cuadrar en el `Row`.
      final hero = AppTextStyles.hero(44);
      final input = AppTextStyles.heroInput(44);
      expect(input.fontSize, hero.fontSize);
      expect(input.letterSpacing, hero.letterSpacing);
      expect(input.fontWeight, hero.fontWeight);
    });
  });
}
