import 'package:flutter/widgets.dart';

/// Iconos Phosphor usados por la app, servidos desde las fuentes en
/// assets/fonts (el paquete phosphor_flutter no compila con Flutter ≥ 3.4x
/// porque extiende IconData, ahora final). Codepoints de Phosphor 2.x.
abstract final class AppIcons {
  static const _family = 'Phosphor';
  static const _familyFill = 'PhosphorFill';

  // Categorías
  static const forkKnife = IconData(0xe262, fontFamily: _family);
  static const bus = IconData(0xe106, fontFamily: _family);
  static const houseLine = IconData(0xe2c4, fontFamily: _family);
  static const popcorn = IconData(0xeb4e, fontFamily: _family);
  static const heartbeat = IconData(0xe2ac, fontFamily: _family);
  static const shoppingBag = IconData(0xe416, fontFamily: _family);

  // Cuentas
  static const money = IconData(0xe588, fontFamily: _family);
  static const creditCard = IconData(0xe1d2, fontFamily: _family);
  static const bank = IconData(0xe0b4, fontFamily: _family);

  // Pestañas (regular + fill para la activa)
  static const house = IconData(0xe2c2, fontFamily: _family);
  static const houseFill = IconData(0xe2c2, fontFamily: _familyFill);
  static const receipt = IconData(0xe3ec, fontFamily: _family);
  static const receiptFill = IconData(0xe3ec, fontFamily: _familyFill);
  static const plusCircle = IconData(0xe3d6, fontFamily: _family);
  static const plusCircleFill = IconData(0xe3d6, fontFamily: _familyFill);
  static const wallet = IconData(0xe68a, fontFamily: _family);
  static const walletFill = IconData(0xe68a, fontFamily: _familyFill);
  static const target = IconData(0xe47c, fontFamily: _family);
  static const targetFill = IconData(0xe47c, fontFamily: _familyFill);

  // Varios
  static const caretLeft = IconData(0xe138, fontFamily: _family);
  static const x = IconData(0xe4f6, fontFamily: _family);
  static const warning = IconData(0xe4e0, fontFamily: _family);
  static const arrowsLeftRight = IconData(0xe0a0, fontFamily: _family);

  /// Iconos persistibles: en la BD se guarda la clave, no el [IconData].
  static const Map<String, IconData> byKey = {
    'forkKnife': forkKnife,
    'bus': bus,
    'houseLine': houseLine,
    'popcorn': popcorn,
    'heartbeat': heartbeat,
    'shoppingBag': shoppingBag,
    'money': money,
    'creditCard': creditCard,
    'bank': bank,
    'wallet': wallet,
  };

  /// Una clave desconocida no debe romper la app: al sincronizar, un teléfono
  /// con la app vieja recibirá claves que todavía no conoce.
  static IconData resolve(String key) => byKey[key] ?? wallet;

  /// Iconos elegibles al crear o editar una cuenta.
  static const List<String> accountIconKeys = [
    'money',
    'creditCard',
    'bank',
    'wallet',
  ];

  /// Iconos elegibles al crear o editar una categoría.
  static const List<String> categoryIconKeys = [
    'forkKnife',
    'bus',
    'houseLine',
    'popcorn',
    'heartbeat',
    'shoppingBag',
  ];
}
