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
import 'package:gastegi/features/expenses/presentation/widgets/amount_keypad.dart';
import 'package:go_router/go_router.dart';

/// Nuevo gasto: monto con teclado propio, categoría, cuenta y descripción.
///
/// En apaisado se reparte en dos columnas —campos a la izquierda, teclado y
/// Guardar a la derecha—: en vertical, la pantalla entera no cabe en la altura
/// de un teléfono tumbado, y obligar a desplazarse para llegar al teclado
/// convierte en dos gestos lo que era uno.
class AddExpensePage extends ConsumerWidget {
  const AddExpensePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screen = watchScreen(context);

    // Scaffold propio: esta pantalla es una ruta de nivel superior, fuera del
    // shell de pestañas, así que nadie más se lo pone.
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        // En apaisado el contenido se reparte en dos columnas, así que puede
        // aprovechar más ancho que una pantalla de lectura en vertical.
        child: ContentWidth(
          maxWidth: screen.isLandscape ? 840 : kTabletBreakpoint,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.r, 12.r, 20.r, 16.r),
            // La decisión se toma con la pantalla y no con las restricciones
            // del `LayoutBuilder`: aquí dentro el ancho ya viene recortado por
            // `ContentWidth`, y en una tableta tumbada comparar ancho contra
            // alto daría el resultado contrario al que se ve.
            child: screen.isLandscape
                ? const _LandscapeLayout()
                : const _PortraitLayout(),
          ),
        ),
      ),
    );
  }
}

/// Una sola columna, con el teclado empujado al fondo.
class _PortraitLayout extends StatelessWidget {
  const _PortraitLayout();

  @override
  Widget build(BuildContext context) {
    watchScreen(context);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        // `IntrinsicHeight` + `Spacer` sobre la altura mínima de la ventana:
        // así el teclado se pega abajo cuando sobra sitio, y la pantalla se
        // desplaza cuando no lo hay.
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12.r,
              children: [
                const _Header(),
                const _AmountDisplay(),
                const _Fields(),
                const Spacer(),
                const _Keypad(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dos columnas: los campos a la izquierda, el teclado a la derecha.
class _LandscapeLayout extends StatelessWidget {
  const _LandscapeLayout();

  @override
  Widget build(BuildContext context) {
    watchScreen(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12.r,
      children: [
        // La cabecera cruza las dos columnas en vez de vivir dentro de la
        // izquierda: si no, el botón de cerrar cae a media pantalla, donde
        // termina esa columna, y no en la esquina donde se busca.
        const _Header(),
        Expanded(
          child: Row(
            // Las dos columnas arrancan a la misma altura, justo debajo de la
            // cabecera. Sin esto la de la derecha se estira hasta el fondo y
            // centra el teclado en su propio alto, que no coincide con nada de
            // lo que tiene al lado.
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 20.r,
            children: [
              Expanded(
                // Solo la columna de campos se desplaza: el teclado y Guardar
                // tienen que quedarse quietos, que es lo que se está tocando.
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 12.r,
                    children: [const _AmountDisplay(), const _Fields()],
                  ),
                ),
              ),
              const Expanded(child: _Keypad()),
            ],
          ),
        ),
      ],
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

/// La cifra que se está tecleando.
class _AmountDisplay extends ConsumerWidget {
  const _AmountDisplay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    watchScreen(context);
    final state = ref.watch(addExpenseProvider);
    return Padding(
      padding: EdgeInsets.only(top: 8.r, bottom: 4.r),
      // El máximo tecleable con moneda y decimales roza el ancho de la
      // pantalla: se encoge en vez de desbordar.
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
    final state = ref.watch(addExpenseProvider);
    final form = ref.read(addExpenseProvider.notifier);
    final l10n = context.l10n;

    final today = data.today;
    final isToday = sameDay(state.date, today);
    final isYesterday = sameDay(state.date, daysBefore(today, 1));
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
                      : context.dates.dayLabelShort(state.date, today),
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
      ],
    );
  }
}

/// Teclado numérico y botón de guardar.
class _Keypad extends ConsumerWidget {
  const _Keypad();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    watchScreen(context);
    final saveDisabled = ref.watch(
      addExpenseProvider.select((s) => s.saveDisabled),
    );
    final form = ref.read(addExpenseProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12.r,
      children: [
        AmountKeypad(onKey: form.keypadTap),
        PrimaryButton(
          label: context.l10n.addExpenseSave,
          disabled: saveDisabled,
          onTap: () async {
            if (!await form.save()) return;
            if (context.mounted) context.go(RouteNames.history);
          },
        ),
      ],
    );
  }
}
