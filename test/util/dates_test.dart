import 'package:flutter_test/flutter_test.dart';
import 'package:gastegi/util/dates.dart';

import '../helpers/test_db.dart';

void main() {
  setUpAll(initTestLocale);

  test('dayKey y monthKey usan el formato de la BD', () {
    expect(dayKey(DateTime(2026, 8, 12)), '2026-08-12');
    expect(monthKey(DateTime(2026, 8, 12)), '2026-08');
  });

  test('daysInMonth acierta en meses cortos y en febrero bisiesto', () {
    expect(daysInMonth(DateTime(2026, 2)), 28);
    expect(daysInMonth(DateTime(2024, 2)), 29);
    expect(daysInMonth(DateTime(2026, 4)), 30);
    expect(daysInMonth(DateTime(2026, 8)), 31);
  });

  test('addMonths cruza el fin de año en los dos sentidos', () {
    expect(addMonths(DateTime(2026), -1), DateTime(2025, 12));
    expect(addMonths(DateTime(2026, 12), 1), DateTime(2027));
    expect(addMonths(DateTime(2026, 8), -5), DateTime(2026, 3));
  });

  test('daysBefore no se desplaza al cambiar de mes', () {
    expect(daysBefore(DateTime(2026, 8, 3), 6), DateTime(2026, 7, 28));
  });

  test('dayLabel distingue hoy, ayer y el resto', () {
    final today = DateTime(2026, 8, 12);
    expect(dayLabel(today, today), 'Hoy');
    expect(dayLabel(DateTime(2026, 8, 11), today), 'Ayer');
    expect(dayLabel(DateTime(2026, 8, 3), today), '3 de agosto');
    expect(dayLabelShort(DateTime(2026, 8, 3), today), '3 ago');
  });

  test('las abreviaturas de mes son de tres letras, sin punto', () {
    for (var m = 1; m <= 12; m++) {
      final abbr = monthAbbr(DateTime(2026, m));
      expect(abbr, hasLength(3));
      expect(abbr, isNot(contains('.')));
    }
  });

  test('monthTitle y monthName van capitalizados', () {
    expect(monthTitle(DateTime(2026, 8)), 'Agosto 2026');
    expect(monthName(DateTime(2026)), 'Enero');
  });
}
