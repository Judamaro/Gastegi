/// Traducción de lo que guarda el dominio —un ARGB, una clave de icono— a los
/// tipos de Flutter que pintan las pantallas.
///
/// Vive en `app/theme/` y no en la presentación de `categories` porque el mapeo
/// "clave guardada → glifo y paleta" es una decisión del sistema de diseño, y
/// lo necesitan varias funcionalidades: si viviera dentro de una de ellas, las
/// demás tendrían que importar el `presentation/` de una feature ajena. `app/`
/// está por encima de `features/`, así que esta dependencia baja y no cicla:
/// las entidades no importan nada.
library;

import 'package:flutter/widgets.dart';
import 'package:gastegi/app/theme/app_icons.dart';
import 'package:gastegi/features/accounts/domain/entities/account.dart';
import 'package:gastegi/features/categories/domain/entities/category.dart';

extension CategoryVisuals on Category {
  Color get color => Color(colorValue);

  IconData get icon => AppIcons.resolve(iconKey);
}

extension AccountVisuals on Account {
  IconData get icon => AppIcons.resolve(iconKey);
}
