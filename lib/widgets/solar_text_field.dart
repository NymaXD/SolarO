import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/lang.dart';

/// Input con estados visuales claros: focus amarillo, error rojo + icono, show/hide password.
/// Soporta Enter para enviar (`onSubmitted` + `textInputAction`).
class SolarTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefix;
  final bool obscure;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final int maxLines;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final bool dark; // true = sobre fondo azul (texto blanco)

  const SolarTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefix,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.maxLines = 1,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.dark = false,
  });

  @override
  State<SolarTextField> createState() => _SolarTextFieldState();
}

class _SolarTextFieldState extends State<SolarTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    // En modo oscuro los campos son oscuros aunque no estén sobre fondo azul.
    final dd = widget.dark || context.isDark;
    final labelStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: dd ? Colors.white : AppColors.textDark,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(widget.prefix, size: 16, color: dd ? AppColors.accent : AppColors.primary),
            const SizedBox(width: 6),
            Text(widget.label, style: labelStyle),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          obscureText: _hidden,
          // Un campo multilínea debe usar teclado multilínea para que
          // TextInputAction.newline sea válido.
          keyboardType: widget.maxLines > 1
              ? TextInputType.multiline
              : widget.keyboardType,
          textInputAction: widget.textInputAction,
          minLines: widget.maxLines > 1 ? 3 : 1,
          maxLines: widget.maxLines,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          style: TextStyle(color: dd ? Colors.white : AppColors.textDark, fontSize: 14),
          decoration: InputDecoration(
            hintText: widget.hint,
            filled: true,
            fillColor: widget.dark
                ? Colors.white.withValues(alpha: 0.08)
                : (context.isDark ? AppColors.surfaceDark2 : Colors.white),
            hintStyle: TextStyle(color: dd ? Colors.white54 : const Color(0xFF93A0C4), fontSize: 13.5),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: dd ? (widget.dark ? Colors.white30 : AppColors.borderDark) : AppColors.divider),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide(color: AppColors.accent, width: 2),
            ),
            errorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide(color: AppColors.error, width: 1.5),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide(color: AppColors.error, width: 2),
            ),
            errorStyle: TextStyle(color: dd ? const Color(0xFFFF9AA0) : AppColors.error, fontSize: 12),
            prefixIcon: Icon(widget.prefix, size: 20, color: dd ? (widget.dark ? Colors.white70 : AppColors.mutedDark) : null),
            suffixIcon: widget.obscure
                ? IconButton(
                    tooltip: _hidden ? tr('show') : tr('hide'),
                    onPressed: () => setState(() => _hidden = !_hidden),
                    icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                  )
                : const Icon(Icons.check_circle, size: 0, color: Colors.transparent),
          ),
        ),
      ],
    );
  }
}

/// Validadores compartidos (mensajes según idioma).
class SolarValidators {
  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return tr('v_email_empty');
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
    if (!ok) return tr('v_email_bad');
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return tr('v_pass_empty');
    if (v.length < 6) return tr('v_pass_short');
    return null;
  }

  /// Política del backend (POST /auth/register): 8+, mayúscula, minúscula y número.
  static String? registerPassword(String? v) {
    if (v == null || v.isEmpty) return tr('v_pass_empty');
    if (v.length < 8) return tr('v_pass_short');
    if (!RegExp(r'[A-Z]').hasMatch(v)) return tr('v_pass_upper');
    if (!RegExp(r'[a-z]').hasMatch(v)) return tr('v_pass_lower');
    if (!RegExp(r'[0-9]').hasMatch(v)) return tr('v_pass_digit');
    return null;
  }

  static String? personName(String? v) {
    if (v == null || v.trim().isEmpty) return tr('v_name_empty');
    if (v.trim().length < 3) return tr('v_name_short');
    if (v.trim().isNotEmpty && double.tryParse(v.trim()) != null) return tr('v_name_bad');
    return null;
  }

  static String? required(String? v, [String? msg]) {
    if (v == null || v.trim().isEmpty) return msg ?? tr('v_required');
    return null;
  }

  static String? kwh(String? v) {
    if (v == null || v.trim().isEmpty) return tr('v_kwh_empty');
    final n = double.tryParse(v.replaceAll(',', '.'));
    if (n == null) return tr('e_num');
    if (n <= 0) return tr('e_positive');
    if (n > 2000) return tr('e_too_high');
    return null;
  }
}
