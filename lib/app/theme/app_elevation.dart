import 'package:flutter/widgets.dart';
import 'package:gastegi/app/theme/app_colors.dart';

/// Elevación de Nocturne. El diseño no usa sombras de Material: la elevación
/// se expresa con un contorno fino y, en el nivel medio, una sombra ambiental.
abstract final class AppElevation {
  /// shadow-sm: contorno fino de 1 px.
  static const Color smBorder = AppColors.neutral800;

  /// shadow-md: contorno más claro + sombra ambiental.
  static const Color mdBorder = AppColors.neutral700;

  static const BoxShadow mdShadow = BoxShadow(
    color: Color(0x8C000000),
    offset: Offset(0, 6),
    blurRadius: 18,
  );
}
