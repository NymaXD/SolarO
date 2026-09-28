import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/solar_text_field.dart';
import 'appliances_store.dart';

/// Sección Mis electrodomésticos: CRUD 100% funcional en memoria (frontend).
/// Botones "Agregar equipo" y "Editar electrodomésticos" abren esta pantalla.
class AppliancesScreen extends StatelessWidget {
  const AppliancesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mis electrodomésticos'), leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Expanded(child: Text('Registra tus equipos para calcular su consumo. Todo funciona en local (demo).', style: TextStyle(color: AppColors.textMedium, fontSize: 13))),
                        ElevatedButton.icon(onPressed: () => _openEditor(context, null), icon: const Icon(Icons.add_rounded, size: 18), label: const Text('Agregar')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedBuilder(
                  animation: AppliancesStore.instance,
                  builder: (_, _) {
                    final items = AppliancesStore.instance.items;
                    if (items.isEmpty) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(28),
                          child: Column(children: [
                            Icon(Icons.kitchen_outlined, size: 40, color: AppColors.textMedium),
                            SizedBox(height: 8),
                            Text('Sin equipos aún', style: TextStyle(fontWeight: FontWeight.w800)),
                            Text('Toca Agregar para crear el primero.', style: TextStyle(color: AppColors.textMedium, fontSize: 13)),
                          ]),
                        ),
                      );
                    }
                    return Column(children: [
                      for (final it in items)
                        Card(
                          child: ListTile(
                            leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), shape: BoxShape.circle), child: const Icon(Icons.bolt_outlined, color: AppColors.primary)),
                            title: Text('${it.name} x${it.quantity}', style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text('${it.powerW.toStringAsFixed(0)}W • ${it.hoursPerDay}h/día\n${it.kwhMonth.toStringAsFixed(1)} kWh/mes', style: const TextStyle(fontSize: 12)),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(tooltip: 'Editar', icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _openEditor(context, it)),
                                IconButton(tooltip: 'Eliminar', icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error), onPressed: () => _confirmDelete(context, it.id)),
                              ],
                            ),
                          ),
                        ),
                      Card(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(children: [
                            const Icon(Icons.calculate_outlined, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text('Total estimado: ${_total(items).toStringAsFixed(1)} kWh/mes', style: const TextStyle(fontWeight: FontWeight.w800)),
                          ]),
                        ),
                      ),
                    ]);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static double _total(List<ApplianceItemData> items) => items.fold(0, (a, e) => a + e.kwhMonth);

  static Future<void> _confirmDelete(BuildContext context, String id) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Eliminar'), content: const Text('¿Eliminar este equipo?'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white), onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar'))]));
    if (ok == true) AppliancesStore.instance.remove(id);
  }

  static void _openEditor(BuildContext context, ApplianceItemData? existing) {
    showDialog(context: context, builder: (_) => _ApplianceDialog(existing: existing));
  }
}

class _ApplianceDialog extends StatefulWidget {
  final ApplianceItemData? existing;
  const _ApplianceDialog({this.existing});
  @override
  State<_ApplianceDialog> createState() => _ApplianceDialogState();
}

class _ApplianceDialogState extends State<_ApplianceDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _power = TextEditingController(text: widget.existing != null ? widget.existing!.powerW.toStringAsFixed(0) : '');
  late final TextEditingController _hours = TextEditingController(text: widget.existing != null ? widget.existing!.hoursPerDay.toString() : '');
  late int _qty = widget.existing?.quantity ?? 1;

  @override
  void dispose() {
    _name.dispose();
    _power.dispose();
    _hours.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Agregar equipo' : 'Editar equipo'),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SolarTextField(controller: _name, label: 'Nombre', hint: 'Ej: Nevera', prefix: Icons.kitchen_outlined, validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: SolarTextField(controller: _power, label: 'Potencia (W)', hint: 'Ej: 350', prefix: Icons.bolt_outlined, keyboardType: TextInputType.number, validator: (v) => _num(v, 'W'))),
                  const SizedBox(width: 10),
                  Expanded(child: SolarTextField(controller: _hours, label: 'Horas/día', hint: 'Ej: 8', prefix: Icons.schedule_outlined, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) => _hoursV(v))),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  const Text('Cantidad:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(width: 8),
                  IconButton(onPressed: () => setState(() => _qty = (_qty - 1).clamp(1, 20)), icon: const Icon(Icons.remove_circle_outline)),
                  Text('$_qty', style: const TextStyle(fontWeight: FontWeight.w800)),
                  IconButton(onPressed: () => setState(() => _qty = (_qty + 1).clamp(1, 20)), icon: const Icon(Icons.add_circle_outline)),
                ]),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            if (!(_form.currentState?.validate() ?? false)) return;
            final data = ApplianceItemData(
              id: widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
              name: _name.text.trim(),
              powerW: double.parse(_power.text.replaceAll(',', '.')),
              hoursPerDay: double.parse(_hours.text.replaceAll(',', '.')),
              quantity: _qty,
            );
            if (widget.existing == null) {
              AppliancesStore.instance.add(data);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Equipo agregado (demo local)')));
            } else {
              AppliancesStore.instance.update(widget.existing!.id, data);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Equipo actualizado')));
            }
            Navigator.pop(context);
          },
          child: Text(widget.existing == null ? 'Agregar' : 'Guardar'),
        ),
      ],
    );
  }

  String? _num(String? v, String unit) {
    if (v == null || v.trim().isEmpty) return 'Requerido';
    final n = double.tryParse(v.replaceAll(',', '.'));
    if (n == null) return 'Solo números';
    if (n <= 0) return '> 0 $unit';
    if (n > 10000) return 'Muy alto';
    return null;
  }

  String? _hoursV(String? v) {
    if (v == null || v.trim().isEmpty) return 'Requerido';
    final n = double.tryParse(v.replaceAll(',', '.'));
    if (n == null) return 'Solo números';
    if (n < 0 || n > 24) return '0 - 24 h';
    return null;
  }
}
