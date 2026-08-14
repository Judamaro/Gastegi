import 'package:flutter/material.dart';
import 'package:gastegi/app/router/app_screen.dart';
import 'package:gastegi/app/state/app_state.dart';
import 'package:gastegi/app/theme/app_colors.dart';
import 'package:gastegi/app/theme/app_icons.dart';
import 'package:gastegi/app/theme/entity_visuals.dart';
import 'package:gastegi/core/widgets/app_chip.dart';
import 'package:gastegi/core/widgets/app_icon_button.dart';
import 'package:gastegi/core/widgets/app_input.dart';
import 'package:gastegi/core/widgets/field_label.dart';
import 'package:gastegi/core/widgets/primary_button.dart';
import 'package:gastegi/core/widgets/secondary_button.dart';
import 'package:gastegi/features/expenses/presentation/widgets/amount_keypad.dart';

/// Nuevo gasto: monto con teclado propio, categoría, cuenta y descripción.
class AddExpensePage extends StatelessWidget {
  const AddExpensePage({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final hasAmount = state.addAmountValue > 0;

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
                        onTap: () => state.goTo(Screen.home),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Text(
                      state.addAmount.isEmpty ? '0' : state.addAmount,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.88,
                        height: 1,
                        color: hasAmount
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
                          for (final c in state.categories)
                            AppChip(
                              label: c.name,
                              icon: c.icon,
                              color: c.color,
                              active: state.addCat == c.name,
                              onTap: () => state.pickAddCat(c.name),
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
                      if (state.accounts.isEmpty)
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
                              onTap: () => state.goTo(Screen.accounts),
                            ),
                          ],
                        )
                      else
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final a in state.accounts)
                              AppChip(
                                label: a.name,
                                active: state.addAccountId == a.id,
                                onTap: () => state.pickAddAcct(a.id),
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
                            active: state.addDateIsToday,
                            onTap: state.setAddDateToday,
                          ),
                          AppChip(
                            label: 'Ayer',
                            active: state.addDateIsYesterday,
                            onTap: state.setAddDateYesterday,
                          ),
                          AppChip(
                            label: state.addDateLabel,
                            active: !state.addDateIsPreset,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: state.addDate,
                                firstDate: DateTime(2020),
                                // No tiene sentido registrar gastos futuros.
                                lastDate: state.today,
                              );
                              if (picked != null) state.setAddDate(picked);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  AppInput(
                    hint: 'Descripción (opcional)',
                    onChanged: state.setAddDesc,
                  ),
                  const Spacer(),
                  AmountKeypad(onKey: state.keypadTap),
                  PrimaryButton(
                    label: 'Guardar gasto',
                    disabled: state.saveDisabled,
                    onTap: state.saveExpense,
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
