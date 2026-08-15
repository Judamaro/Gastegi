import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:gastegi/app/router/route_names.dart';
import 'package:gastegi/app/state/app_data_notifier.dart';
import 'package:gastegi/app/theme/app_colors.dart';
import 'package:gastegi/app/theme/app_icons.dart';
import 'package:gastegi/app/theme/app_typography.dart';
import 'package:gastegi/app/theme/entity_visuals.dart';
import 'package:gastegi/core/utils/date_utils.dart';
import 'package:gastegi/core/utils/l10n_context.dart';
import 'package:gastegi/core/utils/screen.dart';
import 'package:gastegi/core/widgets/app_chip.dart';
import 'package:gastegi/core/widgets/app_icon_button.dart';
import 'package:gastegi/core/widgets/app_input.dart';
import 'package:gastegi/core/widgets/field_label.dart';
import 'package:gastegi/core/widgets/primary_button.dart';
import 'package:gastegi/core/widgets/secondary_button.dart';
import 'package:gastegi/features/expenses/presentation/providers/add_expense_notifier.dart';
import 'package:gastegi/features/expenses/presentation/widgets/amount_keypad.dart';
import 'package:go_router/go_router.dart';

/// Nuevo gasto: monto con teclado propio, categoría, cuenta y descripción.
class AddExpensePage extends ConsumerWidget {
  const AddExpensePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    watchScreen(context);
    final data = ref.watch(appDataProvider);
    final state = ref.watch(addExpenseProvider);
    final form = ref.read(addExpenseProvider.notifier);
    final l10n = context.l10n;

    final today = data.today;
    final isToday = sameDay(state.date, today);
    final isYesterday = sameDay(state.date, daysBefore(today, 1));
    final isPreset = isToday || isYesterday;

    // Scaffold propio: esta pantalla es una ruta de nivel superior, fuera del
    // shell de pestañas, así que nadie más se lo pone.
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.r, 12.r, 20.r, 16.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 12.r,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.addExpenseTitle,
                              style: TextStyle(
                                fontSize: AppFontSize.title,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          AppIconButton(
                            icon: AppIcons.x,
                            // Volver a donde se estaba, en vez de aterrizar
                            // siempre en Inicio: para eso está el router.
                            onTap: () => context.canPop()
                                ? context.pop()
                                : context.go(RouteNames.home),
                          ),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 8.r, bottom: 4.r),
                        // El máximo tecleable con moneda y decimales roza el
                        // ancho de la pantalla: se encoge en vez de desbordar.
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            context.money.typed(state.amount),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.hero(
                              AppFontSize.displayXl,
                              color: state.amountValue > 0
                                  ? AppColors.text
                                  : AppColors.neutral700,
                            ),
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 5.r,
                        children: [
                          FieldLabel(l10n.addExpenseCategory),
                          Wrap(
                            spacing: 6.r,
                            runSpacing: 6.r,
                            children: [
                              for (final c in data.categories)
                                AppChip(
                                  label: c.name,
                                  icon: c.icon,
                                  color: c.color,
                                  active: state.categoryName == c.name,
                                  onTap: () => form.pickCategory(c.name),
                                ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 5.r,
                        children: [
                          FieldLabel(l10n.addExpenseAccount),
                          // Sin cuentas no se puede guardar nada: explicarlo y dar
                          // la salida, en vez de dejar un hueco vacío y un botón
                          // deshabilitado sin motivo aparente.
                          if (data.accounts.isEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 8.r,
                              children: [
                                Text(
                                  l10n.addExpenseNeedsAccount,
                                  style: TextStyle(
                                    fontSize: AppFontSize.label,
                                    color: AppColors.neutral500,
                                  ),
                                ),
                                SecondaryButton(
                                  label: l10n.accountsCreate,
                                  onTap: () => context.go(RouteNames.accounts),
                                ),
                              ],
                            )
                          else
                            Wrap(
                              spacing: 6.r,
                              runSpacing: 6.r,
                              children: [
                                for (final a in data.accounts)
                                  AppChip(
                                    label: a.name,
                                    active: state.accountId == a.id,
                                    onTap: () => form.pickAccount(a.id),
                                  ),
                              ],
                            ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 5.r,
                        children: [
                          FieldLabel(l10n.addExpenseDate),
                          Wrap(
                            spacing: 6.r,
                            runSpacing: 6.r,
                            children: [
                              AppChip(
                                label: l10n.commonToday,
                                active: isToday,
                                onTap: () => form.setDate(today),
                              ),
                              AppChip(
                                label: l10n.commonYesterday,
                                active: isYesterday,
                                onTap: () => form.setDate(daysBefore(today, 1)),
                              ),
                              AppChip(
                                label: isPreset
                                    ? l10n.addExpenseOtherDate
                                    : context.dates.dayLabelShort(
                                        state.date,
                                        today,
                                      ),
                                active: !isPreset,
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: state.date,
                                    firstDate: DateTime(2020),
                                    // No tiene sentido registrar gastos futuros.
                                    lastDate: today,
                                  );
                                  if (picked != null) form.setDate(picked);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      AppInput(
                        hint: l10n.addExpenseDescriptionHint,
                        onChanged: form.setDescription,
                      ),
                      const Spacer(),
                      AmountKeypad(onKey: form.keypadTap),
                      PrimaryButton(
                        label: l10n.addExpenseSave,
                        disabled: state.saveDisabled,
                        onTap: () async {
                          if (!await form.save()) return;
                          if (context.mounted) context.go(RouteNames.history);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
