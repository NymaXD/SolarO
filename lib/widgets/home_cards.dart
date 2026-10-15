import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class Appliance {
  final String name;
  final String kwh;
  final IconData icon;
  final Color color;
  const Appliance(this.name, this.kwh, this.icon, this.color);
}

const kDemoAppliances = [
  Appliance('Nevera', '45.2 kWh', Icons.kitchen_outlined, AppColors.iconBlue),
  Appliance('Lavadora', '28.1 kWh', Icons.local_laundry_service_outlined, AppColors.iconPink),
  Appliance('Aire\nacondicionado', '32.1 kWh', Icons.ac_unit_rounded, AppColors.iconCyan),
  Appliance('Televisor', '12.7 kWh', Icons.tv_outlined, AppColors.iconPurple),
  Appliance('Bombilla', '8.6 kWh', Icons.lightbulb_outline_rounded, AppColors.iconYellow),
];

/// Item circular de electrodoméstico (mockup móvil + desktop).
class ApplianceItem extends StatelessWidget {
  final Appliance item;
  final bool dark;
  const ApplianceItem({super.key, required this.item, this.dark = false});

  @override
  Widget build(BuildContext context) {
    final dd = dark || context.isDark;
    final sub = dd ? Colors.white70 : AppColors.textMedium;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dd ? Colors.white.withValues(alpha: 0.12) : item.color.withValues(alpha: 0.12),
          ),
          child: Icon(item.icon, color: dd ? Colors.white : item.color, size: 26),
        ),
        const SizedBox(height: 6),
        Text(item.name, textAlign: TextAlign.center, maxLines: 2, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: dd ? Colors.white : AppColors.textDark)),
        Text(item.kwh, style: TextStyle(fontSize: 10, color: sub)),
      ],
    );
  }
}

/// CTA amarillo "Aprende / Implementa" con hover.
class SolarCtaCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  const SolarCtaCard({super.key, required this.title, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        hoverColor: Colors.black12,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: AppColors.onAccent),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.onAccent))),
              const Icon(Icons.chevron_right_rounded, color: AppColors.onAccent),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card blanca con borde para acciones secundarias.
class SolarOutlineCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  const SolarOutlineCard({super.key, required this.title, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Material(
      color: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.divider)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        hoverColor: AppColors.primary.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: isDark ? AppColors.primaryBright : AppColors.primary),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isDark ? Colors.white : AppColors.primaryDark))),
              Icon(Icons.chevron_right_rounded, color: isDark ? AppColors.mutedDark : AppColors.textMedium),
            ],
          ),
        ),
      ),
    );
  }
}
