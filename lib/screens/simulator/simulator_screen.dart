import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/lang.dart';

/// Simulador SOLO frontend (sin cálculo real): sliders + resumen visual.
/// Mantiene el mismo lenguaje visual para no romper consistencia.
class SimulatorScreen extends StatefulWidget {
  const SimulatorScreen({super.key});
  @override
  State<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends State<SimulatorScreen> {
  double panels = 6;
  double consumption = 128.6;

  @override
  Widget build(BuildContext context) {
    final estimated = (panels * 45.5).toStringAsFixed(1); // mock
    final inactive = context.isDark ? AppColors.borderDark : AppColors.divider;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.calculate_rounded, color: context.isDark ? AppColors.primaryBright : AppColors.primary),
                    const SizedBox(width: 8),
                    Text(tr('sim_title'), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: context.tDark)),
                  ]),
                  const SizedBox(height: 4),
                  Text(tr('sim_sub'), style: TextStyle(color: context.tMed, fontSize: 13)),
                  const SizedBox(height: 16),
                  Text('${tr('monthly_use')}: ${consumption.toStringAsFixed(1)} kWh', style: TextStyle(fontWeight: FontWeight.w700, color: context.tDark)),
                  Slider(value: consumption, min: 20, max: 500, divisions: 48, label: consumption.toStringAsFixed(0), activeColor: context.isDark ? AppColors.primaryBright : AppColors.primary, inactiveColor: inactive, onChanged: (v) => setState(() => consumption = v)),
                  Text('${tr('panels')}: ${panels.toInt()}', style: TextStyle(fontWeight: FontWeight.w700, color: context.tDark)),
                  Slider(value: panels, min: 1, max: 20, divisions: 19, label: panels.toInt().toString(), activeColor: AppColors.accent, inactiveColor: inactive, onChanged: (v) => setState(() => panels = v)),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: context.isDark ? 0.15 : 0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: context.border)),
                    child: Row(
                      children: [
                        const Icon(Icons.solar_power_rounded, color: AppColors.accent, size: 32),
                        const SizedBox(width: 12),
                        Expanded(child: Text('${tr('est_gen')}: $estimated ${tr('kwh_month')}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: context.tDark))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('sim_saved')))), icon: const Icon(Icons.save_outlined), label: Text(tr('save_sim'))),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
