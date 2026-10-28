import 'package:flutter/widgets.dart';
import 'package:gastegi/core/utils/date_labels.dart';
import 'package:gastegi/core/utils/money.dart';
import 'package:gastegi/l10n/generated/app_localizations.dart';

/// Atajos para no repetir `AppLocalizations.of(context)` en cada `build`.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  DateLabels get dates => DateLabels(l10n);

  MoneyLabels get money => MoneyLabels(l10n);
}
