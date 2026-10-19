import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/lang.dart';
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
        Text(tr('learn_title'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textDark)),
        const SizedBox(height: 4),
        Text(tr('learn_sub'), style: const TextStyle(color: AppColors.textMedium)),
        const SizedBox(height: 16),
        _loading
            ? const LearnListSkeleton()
            : EmptyState(
                icon: Icons.school_outlined,
                title: tr('no_modules'),
                subtitle: tr('no_modules_sub'),
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
                IconButton(tooltip: tr('expand_menu'), onPressed: () => Scaffold.of(context).openDrawer(), icon: const Icon(Icons.menu_rounded, color: Colors.white)),
              ]),
              const SizedBox(height: 12),
              Center(child: Text(tr('learn_title'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18))),
              Center(child: Text(tr('learn_sub'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 12.5))),
              const SizedBox(height: 14),
              _loading
                  ? const LearnListSkeleton(dark: true)
                  : EmptyState(
                      dark: true,
                      icon: Icons.school_outlined,
                      title: tr('no_modules'),
                      subtitle: tr('no_modules_sub'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
