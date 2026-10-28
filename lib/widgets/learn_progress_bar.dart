import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/lang.dart';

/// Barra de progreso del módulo educativo.
///
/// Muestra el porcentaje de lecciones completadas de un nivel.
/// Está preparada para conectarse al backend: el `completed` llega del
/// estado local por ahora y después se lee de `GET /learn/progress`.
class LearnProgressBar extends StatelessWidget {
  final double progress; // 0.0 - 1.0
  final int completed;
  final int total;
  final Color color;

  const LearnProgressBar({
    super.key,
    required this.progress,
    required this.completed,
    required this.total,
    this.color = AppColors.accent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final track = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : AppColors.divider;
    final filled = color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tr('learn_progress'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textWhite : AppColors.textDark,
              ),
            ),
            Text(
              '${(progress * 100).round()}%  ($completed / $total)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: filled,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 10,
            child: Stack(
              children: [
                Container(color: track),
                FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [filled, filled.withValues(alpha: 0.7)],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
