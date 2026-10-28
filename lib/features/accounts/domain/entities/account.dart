/// Cuenta de dinero.
///
/// [balance] es un valor **derivado** (saldo inicial menos gastos, más y menos
/// transferencias): nadie lo muta desde Dart, lo recalcula la BD. Ver
/// `core/storage/balances.dart`.
///
/// Sin dependencias de Flutter: [iconKey] es la clave que se guarda en la BD, y
/// `app/theme/entity_visuals.dart` la traduce a `IconData`.
class Account {
  const Account({
    required this.id,
    required this.name,
    required this.kind,
    required this.iconKey,
    required this.balance,
    required this.initialBalance,
    required this.archived,
  });

  /// UUID de texto; ver la nota en [Category].
  final String id;
  final String name;
  final String kind;

  /// Clave persistible del icono; ver `AppIcons.byKey`.
  final String iconKey;

  final double balance;
  final double initialBalance;
  final bool archived;
}
