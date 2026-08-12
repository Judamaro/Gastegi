import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:gastegi/main.dart';
import 'package:gastegi/state/app_state.dart';

void main() {
  group('AppState', () {
    test('el total del mes suma los gastos de demo', () {
      final state = AppState();
      expect(state.total, 1416);
      expect(state.fmt(state.total), '1.416');
    });

    test('los totales por categoría coinciden con el diseño', () {
      final state = AppState();
      expect(state.catTotals['Comida'], 430);
      expect(state.catTotals['Transporte'], 150);
      expect(state.catTotals['Hogar'], 328);
      expect(state.catTotals['Ocio'], 182);
      expect(state.catTotals['Salud'], 108);
      expect(state.catTotals['Compras'], 218);
    });

    test('alertas de presupuesto según el umbral del 90 %', () {
      final state = AppState();
      final byName = {for (final b in state.budgetRows) b.category.name: b};
      // Ocio 182/200 = 91 % ⇒ alerta, sin exceso.
      expect(byName['Ocio']!.alert, isTrue);
      expect(byName['Ocio']!.over, isFalse);
      // Salud 108/120 = 90 % ⇒ justo en el umbral, alerta.
      expect(byName['Salud']!.alert, isTrue);
      // Comida 430/500 = 86 % ⇒ sin alerta.
      expect(byName['Comida']!.alert, isFalse);
    });

    test('el filtro de rango del historial usa los cortes del diseño', () {
      final state = AppState();
      state.filterRange = HistoryRange.last7;
      expect(state.filteredExpenses.every((e) => e.day >= 24), isTrue);
      state.filterRange = HistoryRange.last15;
      expect(state.filteredExpenses.every((e) => e.day >= 16), isTrue);
    });

    test('la transferencia mueve saldo y valida origen ≠ destino', () {
      final state = AppState();
      state.trFrom = 'Débito';
      state.trTo = 'Ahorros';
      state.trAmt = '100';
      state.doTransfer();
      expect(state.accounts.firstWhere((a) => a.name == 'Débito').balance, 2250);
      expect(state.accounts.firstWhere((a) => a.name == 'Ahorros').balance, 6200);

      state.trFrom = state.trTo = 'Efectivo';
      state.trAmt = '50';
      state.doTransfer();
      expect(state.accounts.firstWhere((a) => a.name == 'Efectivo').balance, 480);
    });

    test('el teclado limita a una coma y 7 dígitos', () {
      final state = AppState();
      state.keypadTap(',');
      expect(state.addAmount, '0,');
      state.keypadTap(',');
      expect(state.addAmount, '0,');
      state.addAmount = '';
      for (var i = 0; i < 10; i++) {
        state.keypadTap('9');
      }
      expect(state.addAmount.length, 7);
      state.keypadTap('⌫');
      expect(state.addAmount.length, 6);
    });
  });

  group('GastegiApp', () {
    // Viewport de teléfono (390×844), como el marco iOS del diseño.
    Future<void> pumpApp(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const GastegiApp());
    }

    testWidgets('Inicio muestra el total del mes', (tester) async {
      await pumpApp(tester);
      expect(find.text('1.416'), findsWidgets);
      expect(find.text('gastado este mes'), findsOneWidget);
    });

    testWidgets('la navegación por pestañas cambia de pantalla', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Historial'));
      await tester.pumpAndSettle();
      expect(find.text('Buscar gasto…'), findsOneWidget);

      await tester.tap(find.text('Presupuesto'));
      await tester.pumpAndSettle();
      expect(find.text('Presupuestos'), findsOneWidget);

      await tester.tap(find.text('Cuentas').last);
      await tester.pumpAndSettle();
      expect(find.text('Saldo total'.toUpperCase()), findsOneWidget);
    });

    testWidgets('el flujo de nuevo gasto guarda y navega al historial',
        (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Agregar'));
      await tester.pumpAndSettle();
      expect(find.text('Nuevo gasto'), findsOneWidget);

      await tester.tap(find.text('5'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Comida'));
      await tester.tap(find.text('Efectivo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar gasto'));
      await tester.pumpAndSettle();

      // Navega al historial y el gasto aparece bajo "Hoy" (los datos de demo
      // ya traen 3 gastos "Comida · Efectivo"; el nuevo es el cuarto).
      expect(find.text('Buscar gasto…'), findsOneWidget);
      expect(find.text('HOY'), findsOneWidget);
      expect(find.text('Comida · Efectivo'), findsNWidgets(4));
    });
  });
}
