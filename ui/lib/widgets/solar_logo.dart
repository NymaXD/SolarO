import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Logo SolarO con icono (sidebar y drawer). `light=true` para fondos azules.
class SolarLogo extends StatelessWidget {
  final bool light;
  final double iconSize;
  final double fontSize;
  const SolarLogo({super.key, this.light = false, this.iconSize = 30, this.fontSize = 24});

  @override
  Widget build(BuildContext context) {
    final autoLight = light || context.isDark;
    final textColor = autoLight ? Colors.white : AppColors.primaryDark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.solar_power_rounded, size: iconSize, color: autoLight ? Colors.white : AppColors.primary),
            Positioned(
              top: -6,
              right: -4,
              child: Icon(Icons.wb_sunny_rounded, size: iconSize * 0.45, color: AppColors.accent),
            ),
          ],
        ),
        const SizedBox(width: 6),
        RichText(
          text: TextSpan(
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -0.5),
            children: [
              const TextSpan(text: 'Solar'),
              TextSpan(text: 'O', style: TextStyle(color: autoLight ? AppColors.accent : AppColors.accentDark)),
            ],
          ),
        ),
      ],
    );
  }
}
