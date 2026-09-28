import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

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
                  const Row(children: [
                    Icon(Icons.calculate_rounded, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Simulador solar', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ]),
                  const SizedBox(height: 4),
                  const Text('Ajusta los valores para estimar tu generación (demo visual).', style: TextStyle(color: AppColors.textMedium, fontSize: 13)),
                  const SizedBox(height: 16),
                  Text('Consumo mensual: ${consumption.toStringAsFixed(1)} kWh', style: const TextStyle(fontWeight: FontWeight.w700)),
                  Slider(value: consumption, min: 20, max: 500, divisions: 48, label: consumption.toStringAsFixed(0), activeColor: AppColors.primary, inactiveColor: AppColors.divider, onChanged: (v) => setState(() => consumption = v)),
                  Text('Paneles: ${panels.toInt()}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  Slider(value: panels, min: 1, max: 20, divisions: 19, label: panels.toInt().toString(), activeColor: AppColors.accentDark, inactiveColor: AppColors.divider, onChanged: (v) => setState(() => panels = v)),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
                    child: Row(
                      children: [
                        const Icon(Icons.solar_power_rounded, color: AppColors.accentDark, size: 32),
                        const SizedBox(width: 12),
                        Expanded(child: Text('Generación estimada: $estimated kWh/mes', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Simulación guardada (simulado)'))), icon: const Icon(Icons.save_outlined), label: const Text('Guardar simulación')),
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
