import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Input con estados visuales claros: focus amarillo, error rojo + icono, show/hide password.
class SolarTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefix;
  final bool obscure;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool dark; // true = sobre fondo azul (texto blanco)

  const SolarTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefix,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.dark = false,
  });

  @override
  State<SolarTextField> createState() => _SolarTextFieldState();
}

class _SolarTextFieldState extends State<SolarTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: widget.dark ? Colors.white : AppColors.textDark,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(widget.prefix, size: 16, color: widget.dark ? AppColors.accent : AppColors.primary),
            const SizedBox(width: 6),
            Text(widget.label, style: labelStyle),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          obscureText: _hidden,
          keyboardType: widget.keyboardType,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: widget.validator,
          onChanged: widget.onChanged,
          style: TextStyle(color: widget.dark ? Colors.white : AppColors.textDark, fontSize: 14),
          decoration: InputDecoration(
            hintText: widget.hint,
            filled: true,
            fillColor: widget.dark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
            hintStyle: TextStyle(color: widget.dark ? Colors.white54 : const Color(0xFF93A0C4), fontSize: 13.5),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: widget.dark ? Colors.white30 : AppColors.divider),
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
            errorStyle: TextStyle(color: widget.dark ? const Color(0xFFFF9AA0) : AppColors.error, fontSize: 12),
            prefixIcon: Icon(widget.prefix, size: 20, color: widget.dark ? Colors.white70 : null),
            suffixIcon: widget.obscure
                ? IconButton(
                    tooltip: _hidden ? 'Mostrar' : 'Ocultar',
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

/// Validadores compartidos (solo frontend).
class SolarValidators {
  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Ingresa tu correo';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
    if (!ok) return 'Correo no válido (ej: usuario@correo.com)';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
    if (v.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  /// Política del backend (POST /auth/register): 8+, mayúscula, minúscula y número.
  static String? registerPassword(String? v) {
    if (v == null || v.isEmpty) return 'Crea una contraseña';
    if (v.length < 8) return 'Mínimo 8 caracteres';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Incluye una mayúscula';
    if (!RegExp(r'[a-z]').hasMatch(v)) return 'Incluye una minúscula';
    if (!RegExp(r'[0-9]').hasMatch(v)) return 'Incluye un número';
    return null;
  }

  static String? personName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Ingresa tu nombre';
    if (v.trim().length < 3) return 'Mínimo 3 caracteres';
    if (v.trim().isNotEmpty && double.tryParse(v.trim()) != null) return 'Nombre inválido';
    return null;
  }

  static String? required(String? v, [String msg = 'Campo requerido']) {
    if (v == null || v.trim().isEmpty) return msg;
    return null;
  }

  static String? kwh(String? v) {
    if (v == null || v.trim().isEmpty) return 'Ingresa el consumo';
    final n = double.tryParse(v.replaceAll(',', '.'));
    if (n == null) return 'Solo números (ej: 15)';
    if (n <= 0) return 'Debe ser mayor a 0';
    if (n > 2000) return 'Valor muy alto, verifícalo';
    return null;
  }
}
