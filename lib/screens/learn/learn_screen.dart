import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/responsive.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeletons.dart';
import '../../widgets/solar_logo.dart';

/// Aprende con skeleton inicial + vacío (listo para backend).
class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});
  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    if (!isDesktop) return _mobile(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Aprende sobre energía solar', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textDark)),
        const SizedBox(height: 4),
        const Text('Explora nuestros módulos educativos y conviértete en un experto en energía limpia.', style: TextStyle(color: AppColors.textMedium)),
        const SizedBox(height: 16),
        _loading
            ? const LearnListSkeleton()
            : const EmptyState(
                icon: Icons.school_outlined,
                title: 'Sin módulos por ahora',
                subtitle: 'Los cursos aparecerán aquí cuando estén disponibles. Vuelve pronto.',
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
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const SolarLogo(light: true, fontSize: 22),
                IconButton(onPressed: () {}, icon: const Icon(Icons.menu_rounded, color: Colors.white)),
              ]),
              const SizedBox(height: 12),
              const Center(child: Text('Aprende sobre energía solar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18))),
              const Center(child: Text('Explora nuestros módulos educativos y\nconviértete en un experto en energía limpia.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 12.5))),
              const SizedBox(height: 14),
              _loading
                  ? const LearnListSkeleton(dark: true)
                  : const EmptyState(
                      dark: true,
                      icon: Icons.school_outlined,
                      title: 'Sin módulos por ahora',
                      subtitle: 'Los cursos aparecerán aquí cuando estén disponibles.',
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
