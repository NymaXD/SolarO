import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/learn_service.dart';
import '../../services/session_store.dart';
import '../../services/settings_store.dart';
import '../../theme/app_colors.dart';
import '../../theme/lang.dart';
import '../../theme/responsive.dart';
import '../../widgets/learn_progress_bar.dart';
import '../../widgets/skeletons.dart';
import 'learn_level.dart';
import 'learn_level_screen.dart';

/// Aprende: skeleton de carga + módulos educativos (3 niveles).
///
/// El contenido se reconstruye en cada build con [LearnData.levels], así que
/// cambiar de idioma actualiza títulos y lecturas. El progreso real llega de
/// `GET /learn/progress` y se refresca al volver de un nivel.
class LearnScreen extends StatefulWidget {
  final LearnService? service;

  const LearnScreen({super.key, this.service});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  late final LearnService _service;

  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  Map<int, Set<int>> _completed = const {};

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? LearnService();
    _load();
  }

  /// Carga el progreso del usuario. Si falla, los niveles se muestran igual
  /// (sin marcas) y aparece un aviso con opción de reintentar.
  Future<void> _load({bool showSkeleton = true}) async {
    if (mounted) {
      setState(() {
        if (showSkeleton) _loading = true;
        _refreshing = !showSkeleton;
        _error = null;
      });
    }

    try {
      final token = await SessionStore.validToken();
      if (token == null) {
        throw AuthException(tr('session_expired'), 401);
      }
      final progress = await _service.getProgress(token);
      if (!mounted) return;
      setState(() {
        _completed = {
          for (final item in progress.values) item.level: item.completed,
        };
        _loading = false;
        _refreshing = false;
        _error = null;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _refreshing = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _refreshing = false;
        _error = tr('err_generic');
      });
    }
  }

  List<LearnLevel> get _levels => LearnData.levels()
      .map((level) => level.withProgress(_completed[level.number] ?? const {}))
      .toList();

  Future<void> _openLevel(LearnLevel level) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LearnLevelScreen(level: level, service: _service),
      ),
    );
    // Al volver se refresca el progreso: el detalle pudo marcarlo o quitarlo.
    if (mounted) await _load(showSkeleton: false);
  }

  @override
  Widget build(BuildContext context) {
    // El contenido se reconstruye al cambiar el idioma (los textos viven en
    // LearnData y no en el estado).
    return ListenableBuilder(
      listenable: SettingsStore.instance,
      builder: (context, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
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
        Text(tr('learn_sub'), style: TextStyle(color: context.tMed)),
        const SizedBox(height: 16),
        if (_refreshing) ...[
          const LinearProgressIndicator(minHeight: 2),
          const SizedBox(height: 8),
        ],
        if (_error != null) ...[
          _errorBanner(),
          const SizedBox(height: 12),
        ],
        if (_loading)
          const LearnListSkeleton()
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
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(tr('learn_title'),
                    style: TextStyle(
                        color: context.tDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 18)),
              ),
              Center(
                child: Text(tr('learn_sub'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.tMed, fontSize: 12.5)),
              ),
              const SizedBox(height: 14),
              if (_refreshing) ...[
                const LinearProgressIndicator(minHeight: 2),
                const SizedBox(height: 8),
              ],
              if (_error != null) ...[
                _errorBanner(),
                const SizedBox(height: 12),
              ],
              if (_loading)
                const LearnListSkeleton()
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

  Widget _errorBanner() {
    final dark = context.isDark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: dark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined,
              size: 18, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(fontSize: 12, color: context.tDark),
            ),
          ),
          TextButton(
            onPressed: _refreshing ? null : () => _load(showSkeleton: false),
            child: Text(tr('retry'),
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w800)),
          ),
        ],
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
                            color:
                                isDark ? AppColors.textWhite : AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          level.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.mutedDark
                                : AppColors.textMedium,
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
