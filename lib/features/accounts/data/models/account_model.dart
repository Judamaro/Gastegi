import 'package:gastegi/features/accounts/domain/entities/account.dart';

/// [Account] con el mapeo desde una fila de la tabla `accounts`.
class AccountModel extends Account {
  const AccountModel({
    required super.id,
    required super.name,
    required super.kind,
    required super.iconKey,
    required super.balance,
    required super.initialBalance,
    required super.archived,
  });

  factory AccountModel.fromRow(Map<String, Object?> r) => AccountModel(
    id: r['id'] as String,
    name: r['name'] as String,
    kind: r['kind'] as String,
    iconKey: r['icon_key'] as String,
    balance: (r['balance'] as num).toDouble(),
    initialBalance: (r['initial_balance'] as num).toDouble(),
    archived: (r['archived'] as int) == 1,
  );
}
