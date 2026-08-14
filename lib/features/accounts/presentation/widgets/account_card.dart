import 'package:flutter/material.dart';
import 'package:gastegi/app/state/app_state.dart';
import 'package:gastegi/app/theme/app_colors.dart';
import 'package:gastegi/app/theme/app_elevation.dart';
import 'package:gastegi/app/theme/app_icons.dart';
import 'package:gastegi/app/theme/app_spacing.dart';
import 'package:gastegi/app/theme/entity_visuals.dart';
import 'package:gastegi/core/widgets/app_icon_button.dart';
import 'package:gastegi/features/accounts/domain/entities/account.dart';

class AccountCard extends StatelessWidget {
  const AccountCard({super.key, required this.state, required this.account});

  final AppState state;
  final Account account;

  @override
  Widget build(BuildContext context) {
    final negative = account.balance < 0;
    return InkWell(
      onTap: () => state.openAccountForm(account),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space3),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppElevation.smBorder),
        ),
        child: Row(
          spacing: 12,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.neutral900,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                account.icon,
                size: 19,
                color: negative ? AppColors.neutral500 : AppColors.accent300,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(account.name, style: const TextStyle(fontSize: 14)),
                  if (account.kind.isNotEmpty)
                    Text(
                      account.kind,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.neutral600,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              '${negative ? '−' : ''}${state.fmt(account.balance.abs())}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: negative ? AppColors.neutral500 : AppColors.text,
              ),
            ),
            AppIconButton(
              icon: AppIcons.x,
              onTap: () => state.askDeleteAccount(account.id),
            ),
          ],
        ),
      ),
    );
  }
}
