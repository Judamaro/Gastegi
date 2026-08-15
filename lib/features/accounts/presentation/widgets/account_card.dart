import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:gastegi/app/theme/app_colors.dart';
import 'package:gastegi/app/theme/app_elevation.dart';
import 'package:gastegi/app/theme/app_icons.dart';
import 'package:gastegi/app/theme/app_spacing.dart';
import 'package:gastegi/app/theme/app_typography.dart';
import 'package:gastegi/app/theme/entity_visuals.dart';
import 'package:gastegi/core/utils/l10n_context.dart';
import 'package:gastegi/core/widgets/app_icon_button.dart';
import 'package:gastegi/features/accounts/domain/entities/account.dart';
import 'package:gastegi/features/accounts/presentation/providers/account_form_notifier.dart';

/// Fila de una cuenta: icono, nombre, tipo y saldo.
class AccountCard extends ConsumerWidget {
  const AccountCard({super.key, required this.account});

  final Account account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.read(accountFormProvider.notifier);
    final negative = account.balance < 0;
    return InkWell(
      onTap: () => form.open(account),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: AppSpacing.card,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppElevation.smBorder),
        ),
        child: Row(
          spacing: 12.r,
          children: [
            Container(
              width: 38.r,
              height: 38.r,
              decoration: BoxDecoration(
                color: AppColors.neutral900,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                account.icon,
                size: 19.r,
                color: negative ? AppColors.neutral500 : AppColors.accent300,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: AppFontSize.body),
                  ),
                  if (account.kind.isNotEmpty)
                    Text(
                      account.kind,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppFontSize.caption,
                        color: AppColors.neutral600,
                      ),
                    ),
                ],
              ),
            ),
            // Pegado a la derecha y encogible: el saldo más largo con
            // moneda y decimales no cabe junto al nombre de la cuenta.
            Expanded(
              flex: 2,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  context.money.formatSigned(account.balance),
                  style: TextStyle(
                    fontSize: AppFontSize.subtitle,
                    fontWeight: FontWeight.w500,
                    color: negative ? AppColors.neutral500 : AppColors.text,
                  ),
                ),
              ),
            ),
            AppIconButton(
              icon: AppIcons.x,
              onTap: () => form.askDelete(account.id),
            ),
          ],
        ),
      ),
    );
  }
}
