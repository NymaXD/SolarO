import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/lang.dart';
import '../../widgets/solar_text_field.dart';
import 'appliances_store.dart';

/// Sección Mis electrodomésticos: CRUD 100% funcional en memoria (frontend).
/// Botones "Agregar equipo" y "Editar electrodomésticos" abren esta pantalla.
class AppliancesScreen extends StatelessWidget {
  const AppliancesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text(tr('my_appliances')), leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context))),
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
                        Expanded(child: Text(tr('ap_sub'), style: const TextStyle(color: AppColors.textMedium, fontSize: 13))),
                        ElevatedButton.icon(onPressed: () => _openEditor(context, null), icon: const Icon(Icons.add_rounded, size: 18), label: Text(tr('add'))),
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
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(children: [
                            const Icon(Icons.kitchen_outlined, size: 40, color: AppColors.textMedium),
                            const SizedBox(height: 8),
                            Text(tr('no_equipment'), style: const TextStyle(fontWeight: FontWeight.w800)),
                            Text(tr('no_equipment_hint'), style: const TextStyle(color: AppColors.textMedium, fontSize: 13)),
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
                            subtitle: Text('${it.powerW.toStringAsFixed(0)}W • ${it.hoursPerDay}${tr('fld_hours_short')}\n${it.kwhMonth.toStringAsFixed(1)} ${tr('kwh_month')}', style: const TextStyle(fontSize: 12)),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(tooltip: tr('edit'), icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _openEditor(context, it)),
                                IconButton(tooltip: tr('delete'), icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error), onPressed: () => _confirmDelete(context, it.id)),
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
                            Text('${tr('total_est')}: ${_total(items).toStringAsFixed(1)} ${tr('kwh_month')}', style: const TextStyle(fontWeight: FontWeight.w800)),
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
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: Text(tr('delete_title')), content: Text(tr('delete_sub')), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr('cancel'))), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white), onPressed: () => Navigator.pop(context, true), child: Text(tr('delete')))]));
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
      title: Text(widget.existing == null ? tr('add_title') : tr('edit_title')),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SolarTextField(controller: _name, label: tr('fld_name'), hint: tr('fld_name_hint'), prefix: Icons.kitchen_outlined, validator: (v) => v == null || v.trim().isEmpty ? tr('v_required') : null),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: SolarTextField(controller: _power, label: tr('fld_power'), hint: tr('fld_power_hint'), prefix: Icons.bolt_outlined, keyboardType: TextInputType.number, validator: (v) => _num(v))),
                  const SizedBox(width: 10),
                  Expanded(child: SolarTextField(controller: _hours, label: tr('fld_hours'), hint: tr('fld_hours_hint'), prefix: Icons.schedule_outlined, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) => _hoursV(v))),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Text(tr('qty'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
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
        TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('cancel'))),
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
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('added'))));
            } else {
              AppliancesStore.instance.update(widget.existing!.id, data);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('updated'))));
            }
            Navigator.pop(context);
          },
          child: Text(widget.existing == null ? tr('add') : tr('save')),
        ),
      ],
    );
  }

  String? _num(String? v) {
    if (v == null || v.trim().isEmpty) return tr('v_required');
    final n = double.tryParse(v.replaceAll(',', '.'));
    if (n == null) return tr('e_num');
    if (n <= 0) return tr('e_positive');
    if (n > 10000) return tr('e_too_high');
    return null;
  }

  String? _hoursV(String? v) {
    if (v == null || v.trim().isEmpty) return tr('v_required');
    final n = double.tryParse(v.replaceAll(',', '.'));
    if (n == null) return tr('e_num');
    if (n < 0 || n > 24) return tr('e_hours');
    return null;
  }
}
