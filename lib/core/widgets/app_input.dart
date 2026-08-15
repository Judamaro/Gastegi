import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gastegi/app/theme/app_colors.dart';
import 'package:gastegi/app/theme/app_spacing.dart';

/// Campo de texto estilo .input del diseño.
class AppInput extends StatelessWidget {
  const AppInput({
    super.key,
    required this.hint,
    required this.onChanged,
    this.keyboardType,
    this.initialValue,
    this.inputFormatters,
    this.prefixText,
    this.suffixText,
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  /// Adorno fijo a los lados del texto, para lo que no se edita: el símbolo de
  /// la moneda, que cae a un lado o a otro según el idioma.
  final String? prefixText;
  final String? suffixText;

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
      inputFormatters: inputFormatters,
      cursorColor: AppColors.accent,
      style: const TextStyle(fontSize: 14, color: AppColors.text),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: AppColors.neutral600),
        prefixText: prefixText,
        suffixText: suffixText,
        prefixStyle: const TextStyle(fontSize: 14, color: AppColors.text),
        suffixStyle: const TextStyle(fontSize: 14, color: AppColors.text),
        isDense: true,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
      ),
    );
  }
}
