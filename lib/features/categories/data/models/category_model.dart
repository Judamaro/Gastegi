import 'package:gastegi/features/categories/domain/entities/category.dart';

/// [Category] con el mapeo desde una fila de la tabla `categories`.
class CategoryModel extends Category {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.colorValue,
    required super.iconKey,
    required super.budget,
  });

  factory CategoryModel.fromRow(Map<String, Object?> r) => CategoryModel(
    id: r['id'] as String,
    name: r['name'] as String,
    colorValue: r['color'] as int,
    iconKey: r['icon_key'] as String,
    budget: (r['budget'] as num).toDouble(),
  );
}
