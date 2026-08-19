import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:gastegi/app/theme/app_colors.dart';
import 'package:gastegi/app/theme/app_icons.dart';
import 'package:gastegi/app/theme/app_spacing.dart';
import 'package:gastegi/app/theme/app_typography.dart';
import 'package:gastegi/core/utils/l10n_context.dart';
import 'package:gastegi/core/widgets/app_card.dart';
import 'package:gastegi/core/widgets/app_chip.dart';
import 'package:gastegi/core/widgets/app_input.dart';
import 'package:gastegi/core/widgets/field_label.dart';
import 'package:gastegi/core/widgets/kicker.dart';
import 'package:gastegi/core/widgets/money_input.dart';
import 'package:gastegi/core/widgets/primary_button.dart';
import 'package:gastegi/core/widgets/secondary_button.dart';
import 'package:gastegi/features/categories/presentation/category_failure_message.dart';
import 'package:gastegi/features/categories/presentation/providers/category_form_notifier.dart';
import 'package:gastegi/l10n/generated/app_localizations.dart';

/// Alta y edición de una categoría con su presupuesto, en línea bajo su tarjeta.
class CategoryForm extends ConsumerStatefulWidget {
  const CategoryForm({super.key, this.attached = false});

  /// Va cosido bajo la tarjeta de la categoría que edita, dentro del recuadro
  /// que comparte con ella. Entonces no pone el suyo: serían dos cajas, una
  /// dentro de otra.
  final bool attached;

  @override
  ConsumerState<CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends ConsumerState<CategoryForm> {
  @override
  void initState() {
    super.initState();
    // El formulario nace bajo la tarjeta que se ha tocado, y esa tarjeta puede
    // estar al pie de la ventana: mide 430 dp de alto, así que abrirlo desde la
    // mitad de abajo lo dejaría fuera de pantalla y parecería que el toque no
    // ha hecho nada. Quien llama le pone una `key` por categoría, de modo que
    // saltar de una a otra crea un estado nuevo y esto vuelve a correr.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Después del frame: durante el `build` todavía no hay geometría que
      // consultar.
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoryFormProvider);
    final form = ref.read(categoryFormProvider.notifier);
    final l10n = context.l10n;
    // La key ata los campos al registro editado: sin ella, `TextFormField`
    // conservaría el texto de la categoría anterior al cambiar de una a otra.
    final formKey = state.editingId ?? 'new';

    final fields = <Widget>[
      Kicker(
        state.isEditing
            ? l10n.categoryFormEditTitle
            : l10n.categoryFormNewTitle,
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 5.r,
        children: [
          FieldLabel(l10n.categoryFormName),
          AppInput(
            key: ValueKey('cat-name-$formKey'),
            hint: l10n.categoryFormNameHint,
            initialValue: state.name,
            onChanged: form.setName,
          ),
        ],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 5.r,
        children: [
          FieldLabel(l10n.categoryFormIcon),
          Wrap(
            spacing: 6.r,
            runSpacing: 6,
            children: [
              for (final key in AppIcons.categoryIconKeys)
                AppChip(
                  label: _iconLabel(l10n, key),
                  icon: AppIcons.resolve(key),
                  active: state.iconKey == key,
                  onTap: () => form.pickIcon(key),
                ),
            ],
          ),
        ],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 5.r,
        children: [
          FieldLabel(l10n.categoryFormColor),
          Wrap(
            spacing: 10.r,
            runSpacing: 10,
            children: [
              for (final color in AppColors.categoryPalette)
                _ColorOption(
                  color: color,
                  // El ARGB y no el `Color`: es lo que guarda la entidad, y
                  // comparar objetos de color aquí sería comparar de más.
                  active: state.colorValue == color.toARGB32(),
                  onTap: () => form.pickColor(color.toARGB32()),
                ),
            ],
          ),
        ],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 5.r,
        children: [
          FieldLabel(l10n.categoryFormBudget),
          // Sin `allowNegative`: el esquema tiene un CHECK (budget >= 0), y
          // un presupuesto en negativo no significa nada.
          MoneyInput(
            key: ValueKey('cat-budget-$formKey'),
            hint: l10n.accountFormAmountHint,
            initialValue: state.budget,
            onChanged: form.setBudget,
          ),
        ],
      ),
      if (state.failure != null)
        Text(
          categoryFailureMessage(l10n, state.failure!),
          style: TextStyle(
            fontSize: AppFontSize.label,
            color: AppColors.accent,
          ),
        ),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        spacing: 8.r,
        children: [
          SecondaryButton(label: l10n.commonCancel, onTap: form.close),
          // Ancho mínimo y no fijo: el botón conserva su presencia y crece
          // con la etiqueta cuando el tamaño de letra del sistema la alarga.
          ConstrainedBox(
            constraints: BoxConstraints(minWidth: 110.r),
            child: PrimaryButton(label: l10n.commonSave, onTap: form.submit),
          ),
        ],
      ),
    ];

    if (!widget.attached) {
      return AppCard(gap: 12, elevated: true, children: fields);
    }
    return Padding(
      padding: AppSpacing.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12.r,
        children: fields,
      ),
    );
  }
}

/// Muestra de color elegible.
///
/// No reutiliza `ColorDot`: aquí el punto tiene que ser un objetivo táctil y
/// enseñar cuál está elegido, y engordar `ColorDot` con eso lo complicaría en
/// las cinco pantallas donde solo hace de viñeta.
class _ColorOption extends StatelessWidget {
  const _ColorOption({
    required this.color,
    required this.active,
    required this.onTap,
  });

  final Color color;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 34.r,
        height: 34.r,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          // El anillo va por fuera del círculo, con un hueco de por medio: un
          // borde del mismo color se perdería sobre el propio relleno.
          border: Border.all(
            color: active ? AppColors.text : Colors.transparent,
            width: 2.r,
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
        ),
      ),
    );
  }
}

/// Nombre visible de un icono de categoría.
String _iconLabel(AppLocalizations l10n, String key) => switch (key) {
  'forkKnife' => l10n.categoryIconFood,
  'bus' => l10n.categoryIconTransport,
  'houseLine' => l10n.categoryIconHome,
  'popcorn' => l10n.categoryIconLeisure,
  'heartbeat' => l10n.categoryIconHealth,
  'shoppingBag' => l10n.categoryIconShopping,
  // Una clave desconocida puede llegar de un dispositivo con la app más nueva
  // cuando exista sincronización; mejor mostrarla que romper la pantalla.
  _ => key,
};
