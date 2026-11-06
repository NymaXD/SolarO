import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// CTA amarillo principal con estados loading/disabled + hover nativo de Material 3.
class SolarPrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  const SolarPrimaryButton({super.key, required this.label, this.icon, this.onPressed, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.onAccent))
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
                  Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
                ],
              ),
      ),
    );
  }
}

/// Botón social simulado (OAuth mock: delay + callback).
class SolarSocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onPressed;
  final bool dark;
  const SolarSocialButton({super.key, required this.label, required this.icon, required this.iconColor, this.onPressed, this.dark = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: dark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
          side: BorderSide(color: dark ? Colors.white30 : const Color(0xFFE2E8F5)),
          foregroundColor: dark ? Colors.white : AppColors.textDark,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        icon: Icon(icon, color: iconColor, size: 20),
        label: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

/// Link de acción secundaria (ej: recuperar contraseña).
class SolarLinkButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  const SolarLinkButton({super.key, required this.label, this.onPressed, this.color});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
      child: Text(label, style: TextStyle(color: color ?? AppColors.accent, fontWeight: FontWeight.w700, fontSize: 13)),
    );
  }
}
