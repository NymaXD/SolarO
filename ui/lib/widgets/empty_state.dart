import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/lang.dart';

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
    final dd = dark || context.isDark;
    final titleColor = dd ? Colors.white : AppColors.textDark;
    final subColor = dd ? Colors.white70 : AppColors.textMedium;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.06)
            : (context.isDark ? AppColors.surfaceDark2 : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dd ? (dark ? Colors.white24 : AppColors.borderDark) : AppColors.divider, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dd ? Colors.white.withValues(alpha: 0.10) : AppColors.primary.withValues(alpha: 0.07),
            ),
            child: Icon(icon, size: 32, color: dd ? AppColors.primaryBright : AppColors.primary),
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
        color: dark
            ? Colors.white.withValues(alpha: 0.05)
            : (context.isDark ? AppColors.surfaceDark2 : AppColors.background),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dark ? Colors.white24 : (context.isDark ? AppColors.borderDark : AppColors.divider)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_outlined, color: (dark || context.isDark) ? Colors.white38 : AppColors.textMedium, size: 32),
            const SizedBox(height: 6),
            Text(tr('chart_empty'), style: TextStyle(fontSize: 12, color: (dark || context.isDark) ? Colors.white60 : AppColors.textMedium)),
            Text(tr('chart_empty_sub'), style: TextStyle(fontSize: 11, color: (dark || context.isDark) ? Colors.white38 : AppColors.textMedium)),
          ],
        ),
      ),
    );
  }
}
