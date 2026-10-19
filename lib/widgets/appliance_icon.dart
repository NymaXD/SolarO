import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Icono representativo según el tipo de electrodoméstico del catálogo.
IconData applianceIconForTipo(String tipo) {
  final t = tipo.toLowerCase();
  if (t.contains('nevera') || t.contains('refrig')) return Icons.kitchen_outlined;
  if (t.contains('lavadora')) return Icons.local_laundry_service_outlined;
  if (t.contains('secadora')) return Icons.dry_cleaning_outlined;
  if (t.contains('aire') || t.contains('acond')) return Icons.ac_unit_rounded;
  if (t.contains('televisor') || t.contains('tv')) return Icons.tv_outlined;
  if (t.contains('microondas')) return Icons.microwave_outlined;
  if (t.contains('horno')) return Icons.microwave_outlined;
  if (t.contains('computador') || t.contains('pc')) return Icons.computer_outlined;
  if (t.contains('licuadora') || t.contains('batidora')) {
    return Icons.blender_outlined;
  }
  if (t.contains('plancha')) return Icons.iron_outlined;
  if (t.contains('bombillo') || t.contains('foco') || t.contains('luz')) {
    return Icons.lightbulb_outline_rounded;
  }
  if (t.contains('ventilador')) return Icons.wind_power_outlined;
  if (t.contains('calentador') || t.contains('ducha')) {
    return Icons.water_damage_outlined;
  }
  if (t.contains('lavavajillas')) return Icons.countertops_outlined;
  if (t.contains('cafetera')) return Icons.coffee_outlined;
  if (t.contains('congelador')) return Icons.kitchen_outlined;
  if (t.contains('aspiradora')) return Icons.cleaning_services_outlined;
  if (t.contains('radio') || t.contains('sonido') || t.contains('toca')) {
    return Icons.headphones_outlined;
  }
  if (t.contains('consola') || t.contains('dvd')) return Icons.sports_esports_outlined;
  if (t.contains('bomba')) return Icons.water_damage_outlined;
  if (t.contains('secadora') || t.contains('secado')) {
    return Icons.dry_cleaning_outlined;
  }
  return Icons.electrical_services_outlined;
}

/// Paleta de colores usada para los iconos de cada equipo.
const applianceTileColors = [
  AppColors.iconBlue,
  AppColors.iconPink,
  AppColors.iconCyan,
  AppColors.iconPurple,
  AppColors.iconYellow,
];

/// Color del icono de un equipo según su posición en la lista.
Color applianceTileColor(int index) =>
    applianceTileColors[index % applianceTileColors.length];

/// Círculo con el icono del tipo de equipo (mismo estilo en Inicio y en
/// "Mis electrodomésticos").
class ApplianceTypeIcon extends StatelessWidget {
  final String tipo;
  final int index;
  final double radius;
  final double iconSize;

  const ApplianceTypeIcon({
    super.key,
    required this.tipo,
    this.index = 0,
    this.radius = 18,
    this.iconSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    final color = applianceTileColor(index);
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.14),
      child: Icon(applianceIconForTipo(tipo), size: iconSize, color: color),
    );
  }
}
