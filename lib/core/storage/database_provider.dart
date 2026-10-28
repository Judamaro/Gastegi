import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

/// La base de datos abierta.
///
/// Lanza si nadie la sobrescribe: abrirla es asíncrono y se hace una sola vez
/// en el arranque, así que el `ProviderScope` la recibe ya abierta. Los tests
/// la sobrescriben con una base en memoria.
final databaseProvider = Provider<Database>(
  (ref) => throw UnimplementedError(
    'databaseProvider debe sobrescribirse en el ProviderScope raíz',
  ),
);
