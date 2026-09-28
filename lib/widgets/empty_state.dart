import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Estado vacío genérico: listo para backend (sin datos mock).
/// Se muestra cuando aún no hay registros del usuario.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool dark;
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = dark ? Colors.white : AppColors.textDark;
    final subColor = dark ? Colors.white70 : AppColors.textMedium;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dark ? Colors.white24 : AppColors.divider, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dark ? Colors.white.withValues(alpha: 0.10) : AppColors.primary.withValues(alpha: 0.07),
            ),
            child: Icon(icon, size: 32, color: dark ? Colors.white70 : AppColors.primary),
          ),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: titleColor)),
          const SizedBox(height: 4),
          Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: subColor)),
          if (actionLabel != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: onAction, icon: const Icon(Icons.add_rounded, size: 18), label: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

/// Placeholder de gráfico vacío (mantiene layout del mockup sin datos falsos).
class EmptyChartBox extends StatelessWidget {
  final bool dark;
  final double height;
  const EmptyChartBox({super.key, this.dark = false, this.height = 170});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: dark ? Colors.white.withValues(alpha: 0.05) : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dark ? Colors.white24 : AppColors.divider),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_outlined, color: dark ? Colors.white38 : AppColors.textMedium, size: 32),
            const SizedBox(height: 6),
            Text('Sin datos aún', style: TextStyle(fontSize: 12, color: dark ? Colors.white60 : AppColors.textMedium)),
            Text('Aparecerán aquí al registrar consumo', style: TextStyle(fontSize: 11, color: dark ? Colors.white38 : AppColors.textMedium)),
          ],
        ),
      ),
    );
  }
}
