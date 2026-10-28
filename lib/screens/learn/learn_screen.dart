import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/lang.dart';
import '../../theme/responsive.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/learn_progress_bar.dart';
import '../../widgets/skeletons.dart';
import '../../widgets/solar_logo.dart';
import 'learn_level.dart';
import 'learn_level_screen.dart';

/// Aprende: skeleton de carga + módulos educativos (3 niveles).
class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});
  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  bool _loading = true;
  List<LearnLevel> _levels = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Carga los módulos. Reemplazar por GET /learn/niveles cuando exista el backend.
  Future<void> _load() async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _levels = LearnData.levels();
      _loading = false;
    });
  }

  void _openLevel(LearnLevel level) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LearnLevelScreen(level: level)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    if (!isDesktop) return _mobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('learn_title'),
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: context.tDark)),
        const SizedBox(height: 4),
        Text(tr('learn_sub'),
            style: TextStyle(color: context.tMed)),
        const SizedBox(height: 16),
        if (_loading)
          const LearnListSkeleton()
        else if (_levels.isEmpty)
          EmptyState(
            icon: Icons.school_outlined,
            title: tr('no_modules'),
            subtitle: tr('no_modules_sub'),
          )
        else
          Column(
            children: [
              for (var i = 0; i < _levels.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _LevelRow(
                    level: _levels[i],
                    index: i,
                    onTap: () => _openLevel(_levels[i]),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _mobile(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.blueGradient),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SolarLogo(light: true, fontSize: 22),
                  IconButton(
                    tooltip: tr('expand_menu'),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    icon: const Icon(Icons.menu_rounded, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(tr('learn_title'),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18)),
              ),
              Center(
                child: Text(tr('learn_sub'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12.5)),
              ),
              const SizedBox(height: 14),
              if (_loading)
                const LearnListSkeleton(dark: true)
              else if (_levels.isEmpty)
                EmptyState(
                  dark: true,
                  icon: Icons.school_outlined,
                  title: tr('no_modules'),
                  subtitle: tr('no_modules_sub'),
                )
              else
                Column(
                  children: [
                    for (var i = 0; i < _levels.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _LevelRow(
                          level: _levels[i],
                          index: i,
                          onTap: () => _openLevel(_levels[i]),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fila de nivel: mismo lenguaje visual que `LearnListSkeleton`
/// (icono + título + subtítulo) más la barra de progreso.
class _LevelRow extends StatelessWidget {
  final LearnLevel level;
  final int index;
  final VoidCallback onTap;

  const _LevelRow({
    required this.level,
    required this.index,
    required this.onTap,
  });

  Color _accent(BuildContext context) {
    if (context.isDark) return AppColors.primaryBright;
    switch (index % 3) {
      case 0:
        return AppColors.primary;
      case 1:
        return AppColors.primaryLight;
      default:
        return AppColors.accentDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final accent = _accent(context);
    final cardBg = isDark ? AppColors.surfaceDark : Colors.white;
    final border = isDark ? AppColors.borderDark : AppColors.divider;

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: level.isCompleted
                  ? AppColors.success.withValues(alpha: 0.55)
                  : border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      level.isCompleted
                          ? Icons.check_circle
                          : (index % 3 == 0
                              ? Icons.wb_sunny_outlined
                              : index % 3 == 1
                                  ? Icons.solar_power_outlined
                                  : Icons.engineering_outlined),
                      color: level.isCompleted ? AppColors.success : accent,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          level.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5,
                            color: isDark ? AppColors.textWhite : AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          level.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.mutedDark : AppColors.textMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right,
                      color: isDark ? AppColors.textLight : AppColors.textMedium),
                ],
              ),
              const SizedBox(height: 12),
              LearnProgressBar(
                progress: level.progress,
                completed: level.completed,
                total: level.total,
                color: accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
