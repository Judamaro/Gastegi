import 'package:flutter/material.dart';

import '../theme/nocturne.dart';

/// Tarjeta Nocturne: superficie + borde fino (elev-sm) o borde y sombra (elev-md).
class NCard extends StatelessWidget {
  const NCard({super.key, required this.children, this.gap = Nocturne.space2, this.elevated = false});

  final List<Widget> children;
  final double gap;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Nocturne.space3),
      decoration: BoxDecoration(
        color: Nocturne.surface,
        borderRadius: BorderRadius.circular(Nocturne.radiusMd),
        border: Border.all(color: elevated ? Nocturne.elevMdBorder : Nocturne.elevSmBorder),
        boxShadow: elevated ? const [Nocturne.elevMdShadow] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: gap,
        children: children,
      ),
    );
  }
}

/// Etiqueta kicker de tarjeta: mayúsculas pequeñas en acento.
class Kicker extends StatelessWidget {
  const Kicker(this.text, {super.key, this.color = Nocturne.accent, this.size = 10});

  final String text;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(fontSize: size, letterSpacing: size * 0.1, color: color),
    );
  }
}

/// Chip-botón en forma de píldora, réplica de chipSt() del diseño:
/// activo = tinte del color al 18 % + borde y texto en el color; inactivo =
/// borde divisor y texto neutral-400.
class NChip extends StatelessWidget {
  const NChip({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
    this.color,
    this.icon,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  /// Color propio (categorías); si es nulo se usa el acento.
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final accentText = color ?? Nocturne.accent300;
    final borderColor = color ?? Nocturne.accent;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active ? borderColor.withValues(alpha: 0.18) : Colors.transparent,
          border: Border.all(color: active ? borderColor : Nocturne.divider),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: active ? accentText : Nocturne.neutral400),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: active ? accentText : Nocturne.neutral400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón .btn-primary del diseño: texto y borde en acento, fondo transparente.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.disabled = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(Nocturne.radiusMd),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Nocturne.accent),
            borderRadius: BorderRadius.circular(Nocturne.radiusMd),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 6,
            children: [
              if (icon != null) Icon(icon, size: 16, color: Nocturne.accent),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Nocturne.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón .btn-secondary: borde divisor, texto normal.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Nocturne.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Nocturne.divider),
          borderRadius: BorderRadius.circular(Nocturne.radiusMd),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

/// Botón de icono 36×36 estilo .btn-icon.btn-secondary.
class NIconButton extends StatelessWidget {
  const NIconButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Nocturne.radiusMd),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          border: Border.all(color: Nocturne.divider),
          borderRadius: BorderRadius.circular(Nocturne.radiusMd),
        ),
        child: Icon(icon, size: 16, color: Nocturne.text),
      ),
    );
  }
}

/// Campo de texto estilo .input del diseño.
class NInput extends StatelessWidget {
  const NInput({
    super.key,
    required this.hint,
    required this.onChanged,
    this.keyboardType,
    this.initialValue,
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;

  /// Valor de partida al editar. Usa `TextFormField`, que gestiona su propio
  /// controlador; para que se repueble al cambiar de registro, el llamante debe
  /// pasar una `key` que dependa del registro editado.
  final String? initialValue;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      keyboardType: keyboardType,
      cursorColor: Nocturne.accent,
      style: const TextStyle(fontSize: 14, color: Nocturne.text),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: Nocturne.neutral600),
        isDense: true,
        filled: true,
        fillColor: Nocturne.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Nocturne.radiusMd),
          borderSide: const BorderSide(color: Nocturne.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Nocturne.radiusMd),
          borderSide: const BorderSide(color: Nocturne.accent),
        ),
      ),
    );
  }
}

/// Etiqueta de campo de formulario (.field > label).
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontSize: 12, color: Nocturne.text.withValues(alpha: 0.7)),
    );
  }
}

/// Barra de progreso fina (6 px): pista neutral-900 + relleno coloreado.
class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key, required this.fraction, required this.color, this.height = 6});

  final double fraction;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Container(color: Nocturne.neutral900),
            FractionallySizedBox(
              widthFactor: fraction.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Punto de color de una categoría.
class ColorDot extends StatelessWidget {
  const ColorDot(this.color, {super.key, this.size = 8});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// Fila de gasto del historial / detalle de categoría.
class ExpenseTile extends StatelessWidget {
  const ExpenseTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    this.icon,
    this.iconColor,
  });

  final String title;
  final String subtitle;
  final String amount;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        spacing: 10,
        children: [
          if (icon != null)
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Nocturne.neutral900,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 17, color: iconColor),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13.5),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Nocturne.neutral600),
                ),
              ],
            ),
          ),
          Text(
            '−$amount',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
