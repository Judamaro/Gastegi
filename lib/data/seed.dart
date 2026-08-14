import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

/// Siembra de la primera ejecución: solo las categorías.
///
/// Sin cuentas y sin gastos — el dinero lo pone el usuario. Los colores,
/// iconos y presupuestos son los del diseño original.
const List<(String name, int color, String iconKey, double budget)>
    initialCategories = [
  ('Comida', 0xFFB5ABFC, 'forkKnife', 500),
  ('Transporte', 0xFF9690C9, 'bus', 180),
  ('Hogar', 0xFFD2CEFD, 'houseLine', 400),
  ('Ocio', 0xFF796CBF, 'popcorn', 200),
  ('Salud', 0xFFB2B6CA, 'heartbeat', 120),
  ('Compras', 0xFF75798C, 'shoppingBag', 240),
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
