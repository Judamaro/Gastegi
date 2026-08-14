import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gastegi/app/router/app_screen.dart';
import 'package:gastegi/app/router/nav_notifier.dart';
import 'package:gastegi/app/state/app_data_notifier.dart';
import 'package:gastegi/app/theme/app_colors.dart';
import 'package:gastegi/app/theme/app_icons.dart';
import 'package:gastegi/app/theme/entity_visuals.dart';
import 'package:gastegi/core/utils/date_utils.dart';
import 'package:gastegi/core/widgets/app_chip.dart';
import 'package:gastegi/core/widgets/app_icon_button.dart';
import 'package:gastegi/core/widgets/app_input.dart';
import 'package:gastegi/core/widgets/field_label.dart';
import 'package:gastegi/core/widgets/primary_button.dart';
import 'package:gastegi/core/widgets/secondary_button.dart';
import 'package:gastegi/features/expenses/presentation/providers/add_expense_notifier.dart';
import 'package:gastegi/features/expenses/presentation/widgets/amount_keypad.dart';

/// Nuevo gasto: monto con teclado propio, categoría, cuenta y descripción.
class AddExpensePage extends ConsumerWidget {
  const AddExpensePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appDataProvider);
    final state = ref.watch(addExpenseProvider);
    final form = ref.read(addExpenseProvider.notifier);
    final nav = ref.read(navProvider.notifier);

    final today = data.today;
    final isToday = sameDay(state.date, today);
    final isYesterday = sameDay(state.date, daysBefore(today, 1));
    final isPreset = isToday || isYesterday;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Nuevo gasto',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      AppIconButton(
                        icon: AppIcons.x,
                        onTap: () => nav.goTo(Screen.home),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Text(
                      state.amount.isEmpty ? '0' : state.amount,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.88,
                        height: 1,
                        color: state.amountValue > 0
                            ? AppColors.text
                            : AppColors.neutral700,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 5,
                    children: [
                      const FieldLabel('Categoría'),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
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
                    spacing: 5,
                    children: [
                      const FieldLabel('Cuenta'),
                      // Sin cuentas no se puede guardar nada: explicarlo y dar
                      // la salida, en vez de dejar un hueco vacío y un botón
                      // deshabilitado sin motivo aparente.
                      if (data.accounts.isEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 8,
                          children: [
                            const Text(
                              'Necesitas una cuenta para registrar el gasto.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.neutral500,
                              ),
                            ),
                            SecondaryButton(
                              label: 'Crear cuenta',
                              onTap: () => nav.goTo(Screen.accounts),
                            ),
                          ],
                        )
                      else
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
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
                    spacing: 5,
                    children: [
                      const FieldLabel('Fecha'),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          AppChip(
                            label: 'Hoy',
                            active: isToday,
                            onTap: () => form.setDate(today),
                          ),
                          AppChip(
                            label: 'Ayer',
                            active: isYesterday,
                            onTap: () => form.setDate(daysBefore(today, 1)),
                          ),
                          AppChip(
                            label: isPreset
                                ? 'Otra fecha…'
                                : dayLabelShort(state.date, today),
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
                    hint: 'Descripción (opcional)',
                    onChanged: form.setDescription,
                  ),
                  const Spacer(),
                  AmountKeypad(onKey: form.keypadTap),
                  PrimaryButton(
                    label: 'Guardar gasto',
                    disabled: state.saveDisabled,
                    onTap: () async {
                      if (await form.save()) nav.goTo(Screen.history);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
