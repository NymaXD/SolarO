import 'package:flutter/material.dart';

import '../../services/appliance_service.dart';
import '../../services/auth_service.dart';
import '../../services/session_store.dart';
import '../../theme/app_colors.dart';
import '../../theme/lang.dart';
import '../../widgets/solar_text_field.dart';
import '../auth/auth_screen.dart';

/// Sección Mis electrodomésticos: conectada al backend (/appliances).
class AppliancesScreen extends StatefulWidget {
  const AppliancesScreen({super.key});

  @override
  State<AppliancesScreen> createState() => _AppliancesScreenState();
}

class _AppliancesScreenState extends State<AppliancesScreen> {
  final _service = ApplianceService();
  List<ApplianceItemData> items = [];
  Map<String, int> _catalog = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = await SessionStore.validToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => const AuthScreen()));
      return;
    }
    if (mounted) setState(() => _loading = true);
    try {
      final catalogFuture = _safeCatalog(token);
      final list = await _service.getAppliances(token);
      _catalog = await catalogFuture;
      if (!mounted) return;
      setState(() {
        items = list;
        _error = null;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = tr('err_generic'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<Map<String, int>> _safeCatalog(String token) async {
    try {
      return await _service.getCatalog(token);
    } catch (_) {
      return <String, int>{};
    }
  }

  Future<void> _openEditor(ApplianceItemData? existing) async {
    if (_catalog.isEmpty) {
      try {
        final token = await SessionStore.validToken();
        if (token == null || token.isEmpty) return;
        _catalog = await _service.getCatalog(token);
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(tr('catalog_error'))));
        return;
      }
    }
    if (!mounted) return;
    final result = await showDialog<ApplianceItemData?>(
      context: context,
      builder: (_) => _ApplianceDialog(existing: existing, catalog: _catalog),
    );
    if (!mounted || result == null) return;
    setState(() => _loading = true);
    try {
      final token = await SessionStore.validToken();
      if (token == null || token.isEmpty) return;
      if (existing == null) {
        await _service.createAppliance(token, result);
      } else {
        await _service.updateAppliance(token, result);
      }
      await _load();
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(ApplianceItemData item) async {
    final id = item.id;
    if (id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr('delete_title')),
        content: Text(tr('delete_sub')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(tr('cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr('delete')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final token = await SessionStore.validToken();
    if (token == null || token.isEmpty) return;
    if (mounted) setState(() => _loading = true);
    try {
      await _service.deleteAppliance(token, id);
      await _load();
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = items.fold<double>(0, (a, e) => a + e.kwhMonth);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(tr('my_appliances')),
        leading: IconButton(
            tooltip: tr('back'),
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context)),
      ),
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
                        Expanded(
                            child: Text(tr('ap_sub'),
                                style: const TextStyle(
                                    color: AppColors.textMedium, fontSize: 13))),
                        ElevatedButton.icon(
                            onPressed: () => _openEditor(null),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: Text(tr('add'))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else if (_error != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(children: [
                        Text(_error!, style: const TextStyle(color: AppColors.error)),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _load, child: Text(tr('retry'))),
                      ]),
                    ),
                  )
                else if (items.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(children: [
                        const Icon(Icons.kitchen_outlined,
                            size: 40, color: AppColors.textMedium),
                        const SizedBox(height: 8),
                        Text(tr('no_equipment'),
                            style: const TextStyle(fontWeight: FontWeight.w800)),
                        Text(tr('no_equipment_reg'),
                            style: const TextStyle(
                                color: AppColors.textMedium, fontSize: 13)),
                      ]),
                    ),
                  )
                else ...[
                  Column(children: [
                    for (final it in items)
                      Card(
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                shape: BoxShape.circle),
                            child: const Icon(Icons.bolt_outlined,
                                color: AppColors.primary),
                          ),
                          title: Text('${it.name} x${it.quantity}',
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(
                            '${it.tipo} • ${it.powerW.toStringAsFixed(0)}W • '
                            '${it.hoursPerDay}${tr('fld_hours_short')} • '
                            '${it.daysPerWeek}${tr('fld_days_short')}\n'
                            '${it.kwhMonth.toStringAsFixed(1)} ${tr('kwh_month')}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                  tooltip: tr('edit'),
                                  icon: const Icon(Icons.edit_outlined, size: 20),
                                  onPressed: () => _openEditor(it)),
                              IconButton(
                                  tooltip: tr('delete'),
                                  icon: const Icon(Icons.delete_outline_rounded,
                                      size: 20, color: AppColors.error),
                                  onPressed: () => _delete(it)),
                            ],
                          ),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 4),
                  Card(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(children: [
                        const Icon(Icons.calculate_outlined,
                            color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          '${tr('total_est')}: ${total.toStringAsFixed(1)} ${tr('kwh_month')}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ]),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Diálogo para agregar/editar un electrodoméstico.
class _ApplianceDialog extends StatefulWidget {
  final ApplianceItemData? existing;
  final Map<String, int> catalog;
  const _ApplianceDialog({this.existing, required this.catalog});

  @override
  State<_ApplianceDialog> createState() => _ApplianceDialogState();
}

class _ApplianceDialogState extends State<_ApplianceDialog> {
  static const _defaultHours = 8.0;

  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _days;
  late String? _tipo;
  int _qty = 1;
  double _kwh = 0;

  double get _power => (widget.catalog[_tipo] ?? 0).toDouble();
  int get _daysVal => (int.tryParse(_days.text.trim()) ?? 7).clamp(1, 7);

  double get _maxKwh => (_power / 1000) * 24 * _daysVal * 4.33 * _qty;
  double get _minKwh => (_power / 1000) * 0.1 * _daysVal * 4.33 * _qty;

  double get _hours {
    final base = (_power / 1000) * _daysVal * 4.33 * _qty;
    if (base <= 0) return 0;
    return (_kwh / base).clamp(0.0, 24.0);
  }

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _name = TextEditingController(text: ex?.name ?? '');
    _days = TextEditingController(
        text: ex != null ? ex.daysPerWeek.toString() : '7');
    _qty = ex?.quantity ?? 1;
    _tipo = ex?.tipo;
    if (_tipo == null && widget.catalog.isNotEmpty) {
      _tipo = widget.catalog.keys.first;
    }
    final hours = ex?.hoursPerDay ?? _defaultHours;
    _kwh = (_power / 1000) * hours * _daysVal * 4.33 * _qty;
  }

  @override
  void dispose() {
    _name.dispose();
    _days.dispose();
    super.dispose();
  }

  void _clampKwh() {
    final maxK = _maxKwh;
    if (maxK > 0) _kwh = _kwh.clamp(_minKwh, maxK);
  }

  void _setQty(int delta) {
    final next = (_qty + delta).clamp(1, 99);
    if (next == _qty) return;
    setState(() {
      _qty = next;
      _clampKwh();
    });
  }

  void _onTypeChanged(String? v) {
    setState(() {
      _tipo = v;
      _kwh = (_power / 1000) * _defaultHours * _daysVal * 4.33 * _qty;
    });
  }

  String _num(double v) {
    final r = double.parse(v.toStringAsFixed(1));
    return r == r.roundToDouble()
        ? r.toStringAsFixed(0)
        : r.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final tipos = widget.catalog.keys.toList();
    final accent = context.isDark ? AppColors.accent : AppColors.accentDark;
    final maxK = _maxKwh;
    final sliderMax = maxK > _minKwh ? maxK : _minKwh + 1;
    final sliderValue = _kwh.clamp(_minKwh, sliderMax);
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Row(
        children: [
          Icon(Icons.kitchen_outlined, color: accent, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.existing == null ? tr('add_title') : tr('edit_title'),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SolarTextField(
                    controller: _name,
                    label: tr('fld_name'),
                    hint: tr('fld_name_hint'),
                    prefix: Icons.kitchen_outlined,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? tr('v_required')
                        : null),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _tipo,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: tr('fld_type'),
                    prefixIcon: const Icon(Icons.category_outlined, size: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  items: [
                    for (final t in tipos)
                      DropdownMenuItem(
                        value: t,
                        child: Text('$t · ${widget.catalog[t]} W',
                            overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: _onTypeChanged,
                  validator: (v) =>
                      v == null || v.isEmpty ? tr('v_required') : null,
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.insights_rounded, size: 17, color: accent),
                        const SizedBox(width: 6),
                        Text(tr('estimate'),
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5,
                                color: context.tDark)),
                      ]),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _power > 0 ? _num(_kwh) : '--',
                            style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                height: 1,
                                color: accent),
                          ),
                          const SizedBox(width: 6),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text(tr('kwh_month'),
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: context.tMed)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _power > 0
                            ? '${_power.toStringAsFixed(0)} W · ${_num(_hours)} ${tr('fld_hours_short')} · $_daysVal ${tr('fld_days_short')} · x$_qty'
                            : tr('estimate_hint'),
                        style: TextStyle(fontSize: 11.5, color: context.tMed),
                      ),
                      if (_power > 0) ...[
                        const SizedBox(height: 8),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: accent,
                            inactiveTrackColor: context.border,
                            thumbColor: accent,
                            overlayColor: accent.withValues(alpha: 0.15),
                            trackHeight: 3,
                          ),
                          child: Slider(
                            value: sliderValue,
                            min: _minKwh,
                            max: sliderMax,
                            label: '${_num(_kwh)} ${tr('kwh_month')}',
                            onChanged: (v) => setState(() => _kwh = v),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${_num(_minKwh)} ${tr('kwh_month')}',
                                style: TextStyle(
                                    fontSize: 10.5, color: context.tMed)),
                            Text('${_num(sliderMax)} ${tr('kwh_month')}',
                                style: TextStyle(
                                    fontSize: 10.5, color: context.tMed)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SolarTextField(
                    controller: _days,
                    label: tr('fld_days'),
                    hint: '1 - 7',
                    prefix: Icons.calendar_month_outlined,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(_clampKwh),
                    validator: _daysV),
                const SizedBox(height: 8),
                Row(children: [
                  Text(tr('qty'),
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: context.tDark)),
                  const Spacer(),
                  IconButton(
                      tooltip: tr('less'),
                      onPressed: () => _setQty(-1),
                      icon: const Icon(Icons.remove_circle_outline)),
                  Text('$_qty',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15)),
                  IconButton(
                      tooltip: tr('more'),
                      onPressed: () => _setQty(1),
                      icon: const Icon(Icons.add_circle_outline)),
                ]),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text(tr('cancel'))),
        ElevatedButton(
          onPressed: () {
            if (!(_form.currentState?.validate() ?? false)) return;
            if (_power <= 0) return;
            final data = ApplianceItemData(
              id: widget.existing?.id,
              name: _name.text.trim(),
              tipo: _tipo!,
              powerW: _power,
              hoursPerDay: double.parse(_hours.toStringAsFixed(2)),
              daysPerWeek: _daysVal,
              quantity: _qty,
            );
            Navigator.pop(context, data);
          },
          child: Text(widget.existing == null ? tr('add') : tr('save')),
        ),
      ],
    );
  }

  String? _daysV(String? v) {
    if (v == null || v.trim().isEmpty) return tr('v_required');
    final n = int.tryParse(v.trim());
    if (n == null) return tr('e_num');
    if (n < 1 || n > 7) return '1 - 7';
    return null;
  }
}
