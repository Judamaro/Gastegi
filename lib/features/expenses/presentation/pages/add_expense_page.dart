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
import 'package:gastegi/core/widgets/content_width.dart';
import 'package:gastegi/core/widgets/field_label.dart';
import 'package:gastegi/core/widgets/primary_button.dart';
import 'package:gastegi/core/widgets/secondary_button.dart';
import 'package:gastegi/features/expenses/presentation/providers/add_expense_notifier.dart';
import 'package:gastegi/features/expenses/presentation/widgets/amount_field.dart';
import 'package:go_router/go_router.dart';

/// Nuevo gasto: el importe se teclea con el teclado del sistema sobre la cifra
/// grande, y debajo van categoría, cuenta, fecha y descripción.
///
/// Una sola columna en las dos orientaciones: con el teclado del sistema puesto,
/// en apaisado desaparece media pantalla, y una segunda columna quedaría detrás
/// de él.
class AddExpensePage extends ConsumerWidget {
  const AddExpensePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    watchScreen(context);

    // Scaffold propio: esta pantalla es una ruta de nivel superior, fuera del
    // shell de pestañas, así que nadie más se lo pone.
    //
    // `resizeToAvoidBottomInset` se queda en su valor por defecto: el `Scaffold`
    // encoge el cuerpo hasta el borde del teclado, el `LayoutBuilder` de abajo
    // ve el alto reducido, el `Spacer` colapsa y el desplazamiento alcanza el
    // botón. Apagándolo, el teclado taparía Guardar sin salida posible.
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ContentWidth(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.r, 12.r, 20.r, 16.r),
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                // `IntrinsicHeight` + `Spacer` sobre la altura mínima de la
                // ventana: así Guardar se pega abajo cuando sobra sitio, y la
                // pantalla se desplaza cuando no lo hay.
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 12.r,
                      children: [
                        const _Header(),
                        Padding(
                          padding: EdgeInsets.only(top: 8.r, bottom: 4.r),
                          // El ancho se mide aquí y baja como parámetro: el
                          // campo no puede montar su propio `LayoutBuilder`
                          // colgando de un `IntrinsicHeight`.
                          child: AmountField(maxWidth: constraints.maxWidth),
                        ),
                        const _Fields(),
                        const Spacer(),
                        const _SaveButton(),
                      ],
                    ),
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

/// Título y botón de cerrar.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    watchScreen(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            context.l10n.addExpenseTitle,
            style: TextStyle(
              fontSize: AppFontSize.title,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        AppIconButton(
          icon: AppIcons.x,
          // Volver a donde se estaba, en vez de aterrizar siempre en Inicio:
          // para eso está el router.
          onTap: () =>
              context.canPop() ? context.pop() : context.go(RouteNames.home),
        ),
      ],
    );
  }
}

/// Categoría, cuenta, fecha y descripción.
class _Fields extends ConsumerWidget {
  const _Fields();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    watchScreen(context);
    final data = ref.watch(appDataProvider);
    // La descripción no se pinta aquí, pero `setDescription` emite estado nuevo
    // en cada pulsación: sin el `select`, los trece chips se reconstruían por
    // tecla tecleada.
    final (categoryName, accountId, date) = ref.watch(
      addExpenseProvider.select((s) => (s.categoryName, s.accountId, s.date)),
    );
    final form = ref.read(addExpenseProvider.notifier);
    final l10n = context.l10n;

    final today = data.today;
    final isToday = sameDay(date, today);
    final isYesterday = sameDay(date, daysBefore(today, 1));
    final isPreset = isToday || isYesterday;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12.r,
      children: [
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
                    active: categoryName == c.name,
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
            // Sin cuentas no se puede guardar nada: explicarlo y dar la
            // salida, en vez de dejar un hueco vacío y un botón deshabilitado
            // sin motivo aparente.
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
                      active: accountId == a.id,
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
                      : context.dates.dayLabelShort(date, today),
                  active: !isPreset,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: date,
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
      ],
    );
  }
}

/// Guardar el gasto.
class _SaveButton extends ConsumerWidget {
  const _SaveButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    watchScreen(context);
    final saveDisabled = ref.watch(
      addExpenseProvider.select((s) => s.saveDisabled),
    );
    final form = ref.read(addExpenseProvider.notifier);
    return PrimaryButton(
      label: context.l10n.addExpenseSave,
      disabled: saveDisabled,
      onTap: () async {
        if (!await form.save()) return;
        if (context.mounted) context.go(RouteNames.history);
      },
    );
  }
}
