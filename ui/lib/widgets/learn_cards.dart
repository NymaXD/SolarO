import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class LearnModule {
  final int index;
  final String title;
  final String desc;
  final IconData icon;
  final double progress; // 0..1, 0 = no iniciado
  const LearnModule({required this.index, required this.title, required this.desc, required this.icon, this.progress = 0});
}

const kDemoModules = [
  LearnModule(index: 1, title: 'Fundamentos de la energía solar', desc: 'Conoce los conceptos básicos y la energía del sol.', icon: Icons.school_outlined, progress: 0.75),
  LearnModule(index: 2, title: 'Cómo funcionan los paneles solares', desc: 'Descubre cómo la luz del sol se convierte en electricidad.', icon: Icons.solar_power_outlined),
  LearnModule(index: 3, title: 'Baterías de almacenamiento', desc: 'Aprende a almacenar energía para usarla cuando la necesites.', icon: Icons.battery_charging_full_outlined),
  LearnModule(index: 4, title: 'Inversor de energía', desc: 'Entiende cómo se adapta la energía para tu hogar.', icon: Icons.electrical_services_outlined),
  LearnModule(index: 5, title: 'Sistemas solares en el hogar', desc: 'Conoce los componentes de un sistema solar residencial.', icon: Icons.home_outlined),
  LearnModule(index: 6, title: 'Beneficios de la energía solar', desc: 'Descubre las ventajas económicas y ambientales de la energía solar.', icon: Icons.volunteer_activism_outlined),
];

/// Card de módulo. En móvil oscuro usa fondo translúcido; en desktop fondo blanco.
/// Diseño fiel al mockup: número, icono circular, título, desc, chevron + barra 75%.
class LearnModuleCard extends StatelessWidget {
  final LearnModule module;
  final bool dark;
  final VoidCallback? onTap;
  const LearnModuleCard({super.key, required this.module, this.dark = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final dd = dark || context.isDark;
    final bg = dark
        ? Colors.white.withValues(alpha: 0.06)
        : (context.isDark ? AppColors.surfaceDark : Colors.white);
    final border = dark
        ? Colors.white.withValues(alpha: 0.14)
        : (context.isDark ? AppColors.borderDark : AppColors.divider);
    final titleColor = dd ? Colors.white : AppColors.textDark;
    final descColor = dd ? Colors.white70 : AppColors.textMedium;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          hoverColor: AppColors.accent.withValues(alpha: 0.12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Número + icono
                Stack(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dark ? AppColors.accent.withValues(alpha: 0.15) : AppColors.accent.withValues(alpha: 0.18),
                      ),
                      child: Icon(module.icon, color: dd ? AppColors.accent : AppColors.primary, size: 26),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.error),
                        child: Center(child: Text('${module.index}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800))),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(module.title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: titleColor)),
                      const SizedBox(height: 2),
                      Text(module.desc, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: descColor)),
                      if (module.progress > 0) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(value: module.progress, minHeight: 5, backgroundColor: dd ? Colors.white24 : const Color(0xFFE2E8F5), valueColor: const AlwaysStoppedAnimation(AppColors.accent)),
                        ),
                        const SizedBox(height: 4),
                        Text('${(module.progress * 100).toInt()}% completado', style: TextStyle(fontSize: 11, color: descColor)),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: descColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
