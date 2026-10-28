import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastegi/core/utils/date_labels.dart';
import 'package:gastegi/l10n/generated/app_localizations.dart';

import '../../helpers/test_db.dart';

void main() {
  setUpAll(initTestLocale);

  late DateLabels es;

  setUp(
    () async => es = DateLabels(
      await AppLocalizations.delegate.load(const Locale('es')),
    ),
  );

  test('dayLabel distingue hoy, ayer y el resto', () {
    final today = DateTime(2026, 8, 12);
    expect(es.dayLabel(today, today), 'Hoy');
    expect(es.dayLabel(DateTime(2026, 8, 11), today), 'Ayer');
    expect(es.dayLabel(DateTime(2026, 8, 3), today), '3 de agosto');
    expect(es.dayLabelShort(DateTime(2026, 8, 3), today), '3 ago');
  });

  test('las abreviaturas de mes son de tres letras, sin punto', () {
    // El CLDR español devuelve 'ago.' y 'sept.'; por eso están escritas a mano
    // en el catálogo, y este test es lo que impide que alguien las sustituya
    // por DateFormat('MMM') sin darse cuenta.
    for (var m = 1; m <= 12; m++) {
      final abbr = es.monthAbbr(DateTime(2026, m));
      expect(abbr, hasLength(3));
      expect(abbr, isNot(contains('.')));
    }
  });

  test('monthTitle y monthName van capitalizados', () {
    expect(es.monthTitle(DateTime(2026, 8)), 'Agosto 2026');
    expect(es.monthName(DateTime(2026)), 'Enero');
  });

  test('el inglés usa su propio orden de día y mes', () async {
    final en = DateLabels(
      await AppLocalizations.delegate.load(const Locale('en')),
    );
    final today = DateTime(2026, 8, 12);
    expect(en.dayLabel(today, today), 'Today');
    expect(en.dayLabel(DateTime(2026, 8, 3), today), 'august 3');
  });
}
