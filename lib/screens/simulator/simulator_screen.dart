import 'package:flutter/material.dart';

import '../../services/appliance_service.dart';
import '../../services/session_store.dart';
import '../../theme/app_colors.dart';
import '../../theme/lang.dart';

/// Simulador solar: a partir del consumo mensual estima el sistema FV
/// (paneles, inversor, batería opcional) y sus costos en USD.
///
/// Modelo usado (valores de referencia, editables en el código):
///  - Generación panel (kWh/mes) = W/1000 · horas de sol pico · PR(0.8) · 30.4
///  - Paneles = ceil(consumo / generación por panel)
///  - Inversor = potencia FV · 1.15, redondeado a 0.5 kW
///  - Batería = energía nocturna / (DoD 0.9 · eficiencia 0.95)
class SimulatorScreen extends StatefulWidget {
  const SimulatorScreen({super.key});

  @override
  State<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends State<SimulatorScreen> {
  final _service = ApplianceService();

  // Parámetros del modelo
  static const double _pr = 0.8; // performance ratio
  static const double _daysMonth = 30.4;
  static const double _dod = 0.9; // profundidad de descarga de la batería
  static const double _eff = 0.95; // eficiencia ida/vuelta
  static const double _priceWatt = 0.30; // USD por W de panel
  static const double _priceKwInverter = 150; // USD por kW de inversor
  static const double _priceKwhBattery = 250; // USD por kWh de batería
  static const double _installPct = 0.20; // instalación sobre el equipo
  static const List<double> _batterySizes = [
    1, 2, 3, 5, 10, 15, 20, 30, 40, 50,
  ];
  static const List<double> _panelWatts = [250, 400, 450, 550, 700];

  // Estado
  double _consumption = 150;
  double _sunHours = 4.5;
  double _tariff = 0.15;
  double _panelW = 450;
  bool _battery = false;
  double _nightShare = 0.35;
  double? _devicesKwh;
  bool _loadingDevices = true;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  /// Trae el consumo real de los equipos registrados para usarlo de base.
  Future<void> _loadDevices() async {
    try {
      final token = await SessionStore.validToken();
      if (token == null || token.isEmpty) return;
      final items = await _service.getAppliances(token);
      final total = items.fold<double>(0, (a, e) => a + e.kwhMonth);
      if (!mounted) return;
      setState(() {
        _devicesKwh = total > 0 ? total : null;
        if (total > 0) _consumption = total;
        _loadingDevices = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingDevices = false);
    }
  }

  // ---------------- Cálculos ----------------
  double get _genPerPanel =>
      (_panelW / 1000) * _sunHours * _pr * _daysMonth;

  int get _panels {
    if (_genPerPanel <= 0) return 1;
    return (_consumption / _genPerPanel).ceil().clamp(1, 500);
  }

  double get _totalGen => _panels * _genPerPanel;
  double get _coverage => _consumption <= 0 ? 0 : _totalGen / _consumption * 100;
  double get _surplus => (_totalGen - _consumption).clamp(0, double.infinity);
  double get _pvKw => _panels * _panelW / 1000;

  double get _inverterKw {
    final kw = _pvKw * 1.15;
    return ((kw / 0.5).ceil() * 0.5).clamp(0.5, 100);
  }

  int get _inverters => _inverterKw > 5 ? 2 : 1;

  double get _batteryKwh {
    if (!_battery) return 0;
    // La batería se dimensiona con el consumo DIARIO nocturno, no el mensual.
    final dailyKwh = _consumption / _daysMonth;
    final need = dailyKwh * _nightShare / (_dod * _eff);
    for (final size in _batterySizes) {
      if (size >= need) return size;
    }
    return need.ceilToDouble();
  }

  double get _costPanels => _panels * _panelW * _priceWatt;
  // El precio es por kW total instalado; partir el sistema en 2 equipos
  // no duplica la capacidad ni el costo.
  double get _costInverter => _inverterKw * _priceKwInverter;
  double get _costBattery => _batteryKwh * _priceKwhBattery;
  double get _costInstall =>
      (_costPanels + _costInverter + _costBattery) * _installPct;
  double get _costTotal =>
      _costPanels + _costInverter + _costBattery + _costInstall;

  double get _billNow => _consumption * _tariff;
  double get _savingMonthly =>
      (_consumption.clamp(0, _totalGen)) * _tariff;
  double get _savingYear => _savingMonthly * 12;
  double get _paybackMonths =>
      _savingMonthly <= 0 ? 0 : _costTotal / _savingMonthly;

  String _fill(String key, Map<String, String> values) {
    var out = tr(key);
    values.forEach((k, v) => out = out.replaceAll('{$k}', v));
    return out;
  }

  String _money(double v) => '\$${v.toStringAsFixed(0)}';

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final wide = box.maxWidth >= 900;
      final inputs = _inputsCard();
      final results = _resultsColumn();
      if (!wide) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            inputs,
            const SizedBox(height: 16),
            results,
          ]),
        );
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 420, child: inputs),
            const SizedBox(width: 16),
            Expanded(child: results),
          ],
        ),
      );
    });
  }

  Widget _inputsCard() {
    final accent = context.isDark ? AppColors.accent : AppColors.accentDark;
    final track = context.isDark ? AppColors.borderDark : AppColors.divider;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.tune_rounded,
                  color: context.isDark ? AppColors.primaryBright : AppColors.primary),
              const SizedBox(width: 8),
              Text(tr('sim_inputs'),
                  style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16, color: context.tDark)),
            ]),
            const SizedBox(height: 16),
            _label(tr('monthly_use'),
                '${_consumption.toStringAsFixed(1)} ${tr('kwh_month')}',
                icon: Icons.bolt_outlined),
            Slider(
              value: _consumption.clamp(0, 2000),
              max: 2000,
              divisions: 200,
              label: '${_consumption.toStringAsFixed(0)} kWh',
              activeColor: accent,
              inactiveColor: track,
              onChanged: (v) => setState(() => _consumption = v),
            ),
            if (_loadingDevices)
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: LinearProgressIndicator(minHeight: 2),
              )
            else if (_devicesKwh != null)
              Row(children: [
                Expanded(
                  child: Text(
                    '${tr('sim_from_devices')} ${_devicesKwh!.toStringAsFixed(1)} ${tr('kwh_month')}',
                    style: TextStyle(fontSize: 12, color: context.tMed),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      setState(() => _consumption = _devicesKwh!),
                  child: Text(tr('sim_use_devices')),
                ),
              ]),
            const SizedBox(height: 10),
            _label(tr('sim_sun_hours'),
                '${_sunHours.toStringAsFixed(1)} h/día',
                icon: Icons.wb_sunny_outlined),
            Slider(
              value: _sunHours,
              min: 2,
              max: 12,
              divisions: 100,
              label: '${_sunHours.toStringAsFixed(1)} h',
              activeColor: accent,
              inactiveColor: track,
              onChanged: (v) => setState(() => _sunHours = v),
            ),
            Text(tr('sim_sun_hours_hint'),
                style: TextStyle(fontSize: 11.5, color: context.tMed)),
            const SizedBox(height: 14),
            _label(tr('sim_tariff'),
                '\$${_tariff.toStringAsFixed(2)} / kWh',
                icon: Icons.receipt_long_outlined),
            Slider(
              value: _tariff,
              min: 0.05,
              max: 0.6,
              divisions: 55,
              label: '\$${_tariff.toStringAsFixed(2)}',
              activeColor: accent,
              inactiveColor: track,
              onChanged: (v) => setState(() => _tariff = v),
            ),
            Text(tr('sim_tariff_hint'),
                style: TextStyle(fontSize: 11.5, color: context.tMed)),
            const SizedBox(height: 14),
            Text(tr('sim_panel_type'),
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13.5, color: context.tDark)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final w in _panelWatts)
                  ChoiceChip(
                    label: Text('$w W'),
                    selected: _panelW == w,
                    onSelected: (_) => setState(() => _panelW = w),
                    selectedColor: accent,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      color: _panelW == w
                          ? AppColors.onAccent
                          : (context.isDark ? Colors.white : AppColors.primaryDark),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _battery,
              onChanged: (v) => setState(() => _battery = v),
              title: Text(tr('sim_battery'),
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13.5, color: context.tDark)),
              subtitle: Text(tr('sim_battery_hint'),
                  style: TextStyle(fontSize: 12, color: context.tMed)),
            ),
            if (_battery) ...[
              _label(tr('sim_night_share'),
                  '${(_nightShare * 100).toStringAsFixed(0)}%', icon: Icons.dark_mode_outlined),
              Slider(
                value: _nightShare,
                min: 0.1,
                max: 0.8,
                divisions: 14,
                label: '${(_nightShare * 100).toStringAsFixed(0)}%',
                activeColor: accent,
                inactiveColor: track,
                onChanged: (v) => setState(() => _nightShare = v),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _label(String label, String value, {required IconData icon}) {
    return Row(children: [
      Icon(icon, size: 16, color: context.tMed),
      const SizedBox(width: 6),
      Expanded(
        child: Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 13.5, color: context.tDark)),
      ),
      Text(value,
          style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
              color: context.isDark ? AppColors.primaryBright : AppColors.primary)),
    ]);
  }

  Widget _resultsColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _panelsCard(),
        const SizedBox(height: 16),
        _inverterCard(),
        const SizedBox(height: 16),
        _batteryCard(),
        const SizedBox(height: 16),
        _costsCard(),
      ],
    );
  }

  Widget _resultCard({
    required IconData icon,
    required String title,
    required Widget child,
    Color? iconColor,
  }) {
    final color = iconColor ??
        (context.isDark ? AppColors.primaryBright : AppColors.primary);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15, color: context.tDark)),
            ]),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _panelsCard() {
    final accent = context.isDark ? AppColors.accent : AppColors.accentDark;
    return _resultCard(
      icon: Icons.solar_power_rounded,
      title: tr('panels'),
      iconColor: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _fill('sim_panels_needed', {
              'n': '$_panels',
              'w': _panelW.toStringAsFixed(0),
            }),
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w900, color: accent),
          ),
          const SizedBox(height: 4),
          Text(
            _fill('sim_panels_hint', {
              'kwp': _pvKw.toStringAsFixed(2),
              'kwh': _totalGen.toStringAsFixed(1),
            }),
            style: TextStyle(fontSize: 12.5, color: context.tMed),
          ),
          const SizedBox(height: 10),
          _progress(_coverage / 100, _fill('sim_coverage', {'p': _coverage.toStringAsFixed(0)})),
          if (_surplus > 0.5) ...[
            const SizedBox(height: 6),
            Text(_fill('sim_surplus', {'kwh': _surplus.toStringAsFixed(1)}),
                style: TextStyle(fontSize: 12, color: context.tMed)),
          ],
          const SizedBox(height: 14),
          _compareBars(),
        ],
      ),
    );
  }

  Widget _inverterCard() {
    // Si el sistema usa varios equipos, el texto muestra la potencia de cada uno.
    final perUnit = _inverterKw / _inverters;
    final kwText = perUnit.toStringAsFixed(perUnit == perUnit.roundToDouble() ? 0 : 1);
    final text = _inverters == 1
        ? _fill('sim_inverter_needed', {'kw': kwText})
        : _fill('sim_inverters_needed', {'n': '$_inverters', 'kw': kwText});
    return _resultCard(
      icon: Icons.electrical_services_outlined,
      title: tr('sim_inverter'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: context.isDark ? Colors.white : AppColors.primaryDark,
              )),
          const SizedBox(height: 4),
          Text(tr('sim_inverter_hint'),
              style: TextStyle(fontSize: 12.5, color: context.tMed)),
        ],
      ),
    );
  }

  Widget _batteryCard() {
    if (!_battery) {
      return _resultCard(
        icon: Icons.battery_5_bar_outlined,
        title: tr('sim_battery'),
        child: Row(children: [
          Icon(Icons.info_outline_rounded, size: 18, color: context.tMed),
          const SizedBox(width: 8),
          Expanded(
            child: Text(tr('sim_no_battery'),
                style: TextStyle(fontSize: 13, color: context.tMed)),
          ),
        ]),
      );
    }
    final usable = _consumption / _daysMonth * _nightShare;
    return _resultCard(
      icon: Icons.battery_charging_full_rounded,
      title: tr('sim_battery'),
      iconColor: context.isDark ? AppColors.accent : AppColors.accentDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_fill('sim_battery_needed', {'kwh': _batteryKwh.toStringAsFixed(0)}),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: context.isDark ? Colors.white : AppColors.primaryDark,
              )),
          const SizedBox(height: 4),
          Text(_fill('sim_battery_usable', {'kwh': usable.toStringAsFixed(1)}),
              style: TextStyle(fontSize: 12.5, color: context.tMed)),
        ],
      ),
    );
  }

  Widget _costsCard() {
    return _resultCard(
      icon: Icons.payments_outlined,
      title: tr('sim_costs'),
      child: Column(
        children: [
          _costRow(tr('sim_cost_now'), _money(_billNow), highlight: false),
          _costRow(tr('sim_cost_saving'), _money(_savingMonthly), highlight: true),
          _costRow(tr('sim_cost_saving_year'), _money(_savingYear), highlight: true),
          const Divider(height: 22),
          _costRow(tr('sim_cost_panels'), _money(_costPanels)),
          _costRow(tr('sim_cost_inverter'), _money(_costInverter)),
          if (_battery) _costRow(tr('sim_cost_battery'), _money(_costBattery)),
          _costRow(tr('sim_cost_install'), _money(_costInstall)),
          const Divider(height: 22),
          _costRow(tr('sim_cost_total'), _money(_costTotal), bold: true),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.45)),
            ),
            child: Row(children: [
              Icon(Icons.trending_up_rounded,
                  color: context.isDark ? AppColors.accent : AppColors.accentDark),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _paybackMonths >= 12
                      ? _fill('sim_payback_years',
                          {'n': (_paybackMonths / 12).toStringAsFixed(1)})
                      : _fill('sim_payback_months',
                          {'n': _paybackMonths.toStringAsFixed(0)}),
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: context.tDark),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 10),
          Text(tr('sim_prices_note'),
              style: TextStyle(fontSize: 11, color: context.tMed)),
        ],
      ),
    );
  }

  Widget _costRow(String label, String value,
      {bool highlight = false, bool bold = false}) {
    final color = highlight
        ? (context.isDark ? AppColors.accent : AppColors.accentDark)
        : context.tDark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Expanded(
          child: Text(label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                color: color,
              )),
        ),
        Text(value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w800,
              color: color,
            )),
      ]),
    );
  }

  Widget _progress(double value, String label) {
    final accent = context.isDark ? AppColors.accent : AppColors.accentDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w700, color: context.tDark)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: value.clamp(0, 1),
            minHeight: 8,
            backgroundColor:
                context.isDark ? AppColors.borderDark : AppColors.divider,
            valueColor: AlwaysStoppedAnimation<Color>(accent),
          ),
        ),
      ],
    );
  }

  /// Comparativa visual: consumo vs. generación estimada.
  Widget _compareBars() {
    final max = _consumption > _totalGen ? _consumption : _totalGen;
    if (max <= 0) return const SizedBox.shrink();
    final accent = context.isDark ? AppColors.accent : AppColors.accentDark;
    Widget bar(String label, double value, Color color) {
      final pct = (value / max * 100).clamp(2, 100);
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(label,
                    style: TextStyle(fontSize: 11.5, color: context.tMed)),
              ),
              Text('${value.toStringAsFixed(1)} ${tr('kwh_month')}',
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: context.tDark)),
            ]),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: pct / 100,
                minHeight: 7,
                backgroundColor:
                    context.isDark ? AppColors.borderDark : AppColors.divider,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('sim_compare'),
            style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 12.5, color: context.tDark)),
        const SizedBox(height: 8),
        bar(tr('sim_compare_usage'), _consumption,
            context.isDark ? AppColors.primaryBright : AppColors.primary),
        bar(tr('sim_compare_gen'), _totalGen, accent),
      ],
    );
  }
}
