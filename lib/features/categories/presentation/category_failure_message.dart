import 'package:gastegi/features/categories/domain/failures.dart';
import 'package:gastegi/l10n/generated/app_localizations.dart';

/// Texto de un fallo al guardar una categoría.
///
/// El `switch` es exhaustivo por ser [CategoryFailure] `sealed`: al añadir un
/// fallo nuevo, el compilador señala aquí.
String categoryFailureMessage(AppLocalizations l10n, CategoryFailure failure) =>
    switch (failure) {
      EmptyCategoryName() => l10n.categoryFormEmptyName,
      DuplicateCategoryName() => l10n.categoryFormDuplicateName,
    };
