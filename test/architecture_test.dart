import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Las dos reglas que sostienen esta arquitectura, comprobadas por el propio
/// proyecto.
///
/// Un lint no puede expresarlas y una convención escrita en el README se
/// erosiona sola. Esto son treinta líneas que fallan el día que alguien las
/// rompe, con el archivo y la línea concretos.
void main() {
  final libDir = Directory('lib');

  List<File> dartFilesIn(String path) {
    final dir = Directory(path);
    if (!dir.existsSync()) return const [];
    return dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();
  }

  List<String> featureNames() => Directory('lib/features')
      .listSync()
      .whereType<Directory>()
      .map((d) => d.uri.pathSegments[d.uri.pathSegments.length - 2])
      .toList();

  test('lib/ existe y el test corre desde la raíz del proyecto', () {
    expect(
      libDir.existsSync(),
      isTrue,
      reason: 'Ejecuta `flutter test` desde la raíz del proyecto.',
    );
    expect(featureNames(), isNotEmpty);
  });

  test('el dominio no depende de Flutter', () {
    final offenders = <String>[];
    for (final feature in featureNames()) {
      for (final file in dartFilesIn('lib/features/$feature/domain')) {
        final line = file.readAsLinesSync().indexWhere(
          (l) => l.contains("import 'package:flutter"),
        );
        if (line >= 0) offenders.add('${file.path}:${line + 1}');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'domain/ debe poder compilarse y probarse sin Flutter. Si necesitas '
          'un Color o un IconData, guarda el dato en crudo en la entidad y '
          'tradúcelo en app/theme/entity_visuals.dart.',
    );
  });

  test('ninguna feature entra en el data/ ni el presentation/ de otra', () {
    final features = featureNames();
    final offenders = <String>[];

    for (final feature in features) {
      final forbidden = [
        for (final other in features)
          if (other != feature) ...[
            'package:gastegi/features/$other/data/',
            'package:gastegi/features/$other/presentation/',
          ],
      ];

      for (final file in dartFilesIn('lib/features/$feature')) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          for (final bad in forbidden) {
            if (lines[i].startsWith('import ') && lines[i].contains(bad)) {
              offenders.add('${file.path}:${i + 1} -> $bad');
            }
          }
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Una feature solo puede importar el domain/ de otra —entidades y '
          'contratos de repositorio—, nunca sus detalles.',
    );
  });

  test('core/ no depende de ninguna feature', () {
    final offenders = <String>[];
    for (final file in dartFilesIn('lib/core')) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].startsWith('import ') &&
            lines[i].contains('package:gastegi/features/')) {
          offenders.add('${file.path}:${i + 1}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'core/ es código compartido: si algo de ahí necesita una feature '
          'concreta, es que pertenece a esa feature.',
    );
  });
}
