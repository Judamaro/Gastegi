import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

/// Siembra de la primera ejecución: solo las categorías.
///
/// Sin cuentas y sin gastos — el dinero lo pone el usuario. Los iconos y los
/// presupuestos son los del diseño original.
///
/// Los colores están tomados de `AppColors.categoryPalette` cada cinco pasos:
/// seis tonos repartidos por la rueda, lo más separados que caben. Así la dona
/// de Inicio se lee de un vistazo en una app recién instalada, que es la única
/// a la que llega esta lista. Los ARGB van en crudo porque `core/` no depende
/// de `app/`; que sigan siendo de la paleta lo vigila
/// `test/app/theme/category_palette_test.dart`.
const List<(String name, int color, String iconKey, double budget)>
initialCategories = [
  ('Comida', 0xFFCD3D3E, 'forkKnife', 500),
  ('Transporte', 0xFFD1D040, 'bus', 180),
  ('Hogar', 0xFF3FD53F, 'houseLine', 400),
  ('Ocio', 0xFF42D8D8, 'popcorn', 200),
  ('Salud', 0xFF4241DE, 'heartbeat', 120),
  ('Compras', 0xFFE242E4, 'shoppingBag', 240),
];

const Uuid uuid = Uuid();

/// Se llama una única vez, desde `onCreate`.
Future<void> seedNewDatabase(Database db) async {
  final now = DateTime.now().millisecondsSinceEpoch;
  final batch = db.batch();

  for (var i = 0; i < initialCategories.length; i++) {
    final (name, color, iconKey, budget) = initialCategories[i];
    batch.insert('categories', {
      'id': uuid.v4(),
      'name': name,
      'color': color,
      'icon_key': iconKey,
      'budget': budget,
      'sort_order': i,
      'created_at': now,
      'updated_at': now,
    });
  }

  // Identidad estable del dispositivo, útil para atribuir cambios cuando
  // exista sincronización. TODO(nube): al fusionar dos dispositivos por
  // primera vez habrá que deduplicar estas categorías por nombre.
  batch.insert('sync_state', {'key': 'device_id', 'value': uuid.v4()});

  await batch.commit(noResult: true);
}
