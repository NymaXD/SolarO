import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Skeletons sin dependencias (pulsing). Usar mientras carga backend:
/// `isLoading ? Skeleton... : ContenidoReal`
class SkeletonBox extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;
  final bool dark;
  const SkeletonBox({super.key, this.width, required this.height, this.radius = 10, this.dark = false});

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
  late final Animation<double> _a = Tween(begin: 0.35, end: 0.7).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: FadeTransition(
        opacity: _a,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.dark ? Colors.white24 : const Color(0xFFE2E8F5),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      ),
    );
  }
}

/// Skeleton del gráfico de consumo (7 barras).
class ChartSkeleton extends StatelessWidget {
  final bool dark;
  final double height;
  const ChartSkeleton({super.key, this.dark = false, this.height = 180});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final h in [0.7, 0.5, 0.6, 0.8, 0.95, 0.75, 0.65])
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SkeletonBox(height: 10, width: 32, radius: 4, dark: dark),
                    const SizedBox(height: 4),
                    SkeletonBox(height: (height - 60) * h, radius: 6, dark: dark),
                    const SizedBox(height: 6),
                    SkeletonBox(height: 10, width: 28, radius: 4, dark: dark),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Skeleton de lista de electrodomésticos (filas verticales, igual al
/// `_AppliancesSummary` cargado: leading + título + subtítulo + kWh).
class AppliancesSkeleton extends StatelessWidget {
  final bool dark;
  const AppliancesSkeleton({super.key, this.dark = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < 4; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i < 3 ? 10 : 0),
            child: Row(
              children: [
                SkeletonBox(height: 36, width: 36, radius: 18, dark: dark),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(height: 12, width: 130, radius: 4, dark: dark),
                      const SizedBox(height: 5),
                      SkeletonBox(height: 10, width: 90, radius: 4, dark: dark),
                    ],
                  ),
                ),
                SkeletonBox(height: 12, width: 52, radius: 4, dark: dark),
              ],
            ),
          ),
      ],
    );
  }
}

/// Skeleton de cards Aprende.
class LearnListSkeleton extends StatelessWidget {
  final bool dark;
  const LearnListSkeleton({super.key, this.dark = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < 4; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: dark
                    ? Colors.white.withValues(alpha: 0.06)
                    : (context.isDark ? AppColors.surfaceDark : Colors.white),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: dark
                        ? Colors.white24
                        : (context.isDark ? AppColors.borderDark : AppColors.divider)),
              ),
              child: const Row(
                children: [
                  SkeletonBox(height: 52, width: 52, radius: 26),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(height: 12, radius: 4),
                        SizedBox(height: 6),
                        SkeletonBox(height: 10, radius: 4),
                      ],
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
