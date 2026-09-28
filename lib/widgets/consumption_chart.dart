import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Datos mock solo para UI (sin backend).
class MonthlyConsumption {
  final String month;
  final double kwh;
  const MonthlyConsumption(this.month, this.kwh);
}

const kDemoConsumption = [
  MonthlyConsumption('Ene', 120.4),
  MonthlyConsumption('Feb', 98.7),
  MonthlyConsumption('Mar', 110.2),
  MonthlyConsumption('Abr', 132.6),
  MonthlyConsumption('May', 145.3),
  MonthlyConsumption('Jun', 128.6),
  MonthlyConsumption('Jul', 116.8),
];

/// Gráfico de barras 100% custom (sin dependencias) fiel al mockup:
/// barras amarillas degradadas + valor encima + eje meses.
class ConsumptionChart extends StatelessWidget {
  final List<MonthlyConsumption> data;
  final double height;
  final bool dark;
  const ConsumptionChart({super.key, this.data = kDemoConsumption, this.height = 210, this.dark = false});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        // Escala fija 0-200 kWh como en el mockup (evita recalcular max).

        return SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Eje Y simplificado
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  _Y('200'), _Y('150'), _Y('100'), _Y('50'), _Y('0'),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final d in data)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                d.kwh.toStringAsFixed(1),
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: dark ? Colors.white70 : AppColors.textMedium),
                              ),
                              const SizedBox(height: 4),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeOutCubic,
                                height: (height - 60) * (d.kwh / 200).clamp(0.05, 1.0),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Color(0xFFFFD54D), AppColors.accent],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(d.month, style: TextStyle(fontSize: 10, color: dark ? Colors.white60 : AppColors.textMedium)),
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                height: 6,
                                width: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: d.month == 'Jun' ? AppColors.accent : (dark ? Colors.white24 : const Color(0xFFCBD5E1)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Leyenda desktop
              if (c.maxWidth > 500) ...[
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: const [
                    _Legend(dot: AppColors.accent, label: '2026'),
                    SizedBox(height: 6),
                    _Legend(dot: AppColors.primary, label: '2025'),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Y extends StatelessWidget {
  final String t;
  const _Y(this.t);
  @override
  Widget build(BuildContext context) => Text(t, style: const TextStyle(fontSize: 9, color: AppColors.textMedium));
}

class _Legend extends StatelessWidget {
  final Color dot;
  final String label;
  const _Legend({required this.dot, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)), const SizedBox(width: 4), Text(label, style: const TextStyle(fontSize: 11))]);
}
