import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/lang.dart';
import '../../widgets/learn_progress_bar.dart';
import '../../widgets/youtube_embed.dart';
import 'learn_level.dart';

/// Pantalla de detalle de un nivel: lecturas y videos reproducibles en la página.
///
/// El progreso se guarda localmente y está listo para sincronizarse con el
/// backend (GET /learn/progress, POST /learn/progress).
class LearnLevelScreen extends StatefulWidget {
  final LearnLevel level;
  const LearnLevelScreen({super.key, required this.level});

  @override
  State<LearnLevelScreen> createState() => _LearnLevelScreenState();
}

class _LearnLevelScreenState extends State<LearnLevelScreen> {
  late LearnLevel _level;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _level = widget.level;
  }

  /// Marca/desmarca una lección y recalcula el progreso.
  /// TODO: backend — POST /learn/progress {nivel_id, leccion_id, done}
  void _toggleLesson(String lessonId) {
    final lessons = _level.lessons
        .map((l) => l.id == lessonId ? l.copyWith(done: !l.done) : l)
        .toList();
    final doneCount = lessons.where((l) => l.done).length;

    setState(() {
      _level = LearnLevel(
        id: _level.id,
        title: _level.title,
        subtitle: _level.subtitle,
        lessons: lessons,
        completed: doneCount,
      );
      _saving = true;
    });

    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _saving = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.background,
      appBar: AppBar(
        title: Text(_level.title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Header con progreso
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              border: Border(
                bottom: BorderSide(color: isDark ? AppColors.borderDark : AppColors.divider),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_level.subtitle,
                    style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.mutedDark : AppColors.textMedium)),
                const SizedBox(height: 12),
                LearnProgressBar(
                  progress: _level.progress,
                  completed: _level.completed,
                  total: _level.total,
                ),
                if (_saving)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
              ],
            ),
          ),

          // Lecciones
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: _level.lessons.length,
              itemBuilder: (context, i) {
                final l = _level.lessons[i];
                return _LessonCard(
                  key: ValueKey(l.id),
                  lesson: l,
                  onToggle: () => _toggleLesson(l.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta expandible de una lección (lectura o video).
class _LessonCard extends StatefulWidget {
  final LearnLesson lesson;
  final VoidCallback onToggle;

  const _LessonCard({
    super.key,
    required this.lesson,
    required this.onToggle,
  });

  @override
  State<_LessonCard> createState() => _LessonCardState();
}

class _LessonCardState extends State<_LessonCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final l = widget.lesson;
    final done = l.done;
    final accent = l.isVideo ? AppColors.primaryLight : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: done
              ? AppColors.success.withValues(alpha: 0.55)
              : (isDark ? AppColors.borderDark : AppColors.divider),
        ),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        done
                            ? Icons.check_circle
                            : (l.isVideo ? Icons.play_circle_fill : Icons.menu_book_rounded),
                        color: done ? AppColors.success : accent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                              color: isDark ? AppColors.textWhite : AppColors.textDark,
                              decoration: done ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l.isVideo ? tr('learn_video') : tr('learn_reading'),
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? AppColors.mutedDark : AppColors.textMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: isDark ? AppColors.textLight : AppColors.textMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Contenido primero: lectura o video embebido.
                  if (l.isVideo && l.youtubeId != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: buildYoutubeEmbed(l.youtubeId!),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tr('learn_video_note'),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? AppColors.mutedDark : AppColors.textMedium,
                      ),
                    ),
                  ] else if (l.contenido != null)
                    ElevatedButton.icon(
                      onPressed: () => _showReadingPopup(context, l.contenido!),
                      icon: const Icon(Icons.menu_book_rounded, size: 18),
                      label: Text(tr('learn_read'),
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w800)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Después del contenido: marcar como completado.
                  Row(
                    children: [
                      Expanded(
                        child: done
                            ? Container(
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.check_circle,
                                        color: AppColors.success, size: 17),
                                    const SizedBox(width: 6),
                                    Text(tr('learn_lesson_done'),
                                        style: const TextStyle(
                                            color: AppColors.success,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12.5)),
                                  ],
                                ),
                              )
                            : ElevatedButton.icon(
                                onPressed: widget.onToggle,
                                icon: const Icon(Icons.check, size: 17),
                                label: Text(tr('learn_mark_done'),
                                    style: const TextStyle(
                                        fontSize: 12.5, fontWeight: FontWeight.w800)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  foregroundColor: AppColors.onAccent,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 9),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                      ),
                      if (done) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: widget.onToggle,
                          child: Text(tr('learn_lesson_pending'),
                              style: const TextStyle(fontSize: 11.5)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showReadingPopup(BuildContext context, String contenido) {
    final isDark = context.isDark;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Leer',
      pageBuilder: (_, _, _) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 620),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.divider,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.12),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(tr('learn_reading'),
                          style: const TextStyle(
                              color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 13)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textMedium, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      contenido,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.55,
                        color: isDark ? AppColors.textWhite : AppColors.textDark,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      transitionBuilder: (_, anim, _, child) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        child: child,
      ),
    );
  }
}
