import 'package:flutter/material.dart';

import '../../services/appliance_service.dart';
import '../../services/auth_service.dart';
import '../../services/session_store.dart';
import '../../theme/app_colors.dart';
import '../../theme/lang.dart';
import '../../theme/responsive.dart';
import '../../widgets/appliance_icon.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/home_cards.dart';
import '../../widgets/skeletons.dart';
import '../../widgets/solar_logo.dart';
import '../appliances/appliances_screen.dart';
import '../auth/auth_screen.dart';

Future<void> openAppliances(BuildContext context, {VoidCallback? onClosed}) async {
  await Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const AppliancesScreen()));
  onClosed?.call();
}

IconData _iconForTipo(String tipo) => applianceIconForTipo(tipo);

const _tileColors = applianceTileColors;

/// Dashboard con datos reales de electrodomésticos (/appliances).
class HomeScreen extends StatefulWidget {
  final void Function(int) onNavigate;
  const HomeScreen({super.key, required this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = ApplianceService();
  List<ApplianceItemData> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final token = await SessionStore.validToken();
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        setState(() => _items = []);
        return;
      }
      final list = await _service.getAppliances(token);
      if (!mounted) return;
      setState(() => _items = list);
    } on AuthException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        await SessionStore.clear();
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AuthScreen()));
        return;
      }
      setState(() => _items = []);
    } catch (_) {
      if (!mounted) return;
      setState(() => _items = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _go(int i) => widget.onNavigate(i);

  double get _total => _items.fold<double>(0, (a, e) => a + e.kwhMonth);

  void _openAppliances() => openAppliances(context, onClosed: () {
        if (mounted) setState(() => _loading = true);
        _load();
      });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (Responsive.isDesktop(context)) return _desktop(context);
        if (Responsive.isTablet(context)) return _tablet(context);
        return _mobile(context);
      },
    );
  }

  // ---------- MÓVIL ----------
  Widget _mobile(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.blueGradient),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SolarLogo(light: true, fontSize: 22),
            const SizedBox(height: 12),
            Text(tr('consumption'), style: const TextStyle(color: Colors.white70, fontSize: 14)),
            Text(
              _total > 0 ? '${_total.toStringAsFixed(1)} kWh' : '-- kWh',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              _total > 0 ? '${_items.length} ${tr('appliances').toLowerCase()}' : tr('no_consumption'),
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('monthly'), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 8),
                  _loading
                      ? const ChartSkeleton(dark: true, height: 160)
                      : (_items.isEmpty
                          ? const EmptyChartBox(dark: true, height: 160)
                          : _BarChart(items: _items, dark: true, height: 160)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(tr('appliances'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 8),
            if (_loading)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(16)),
                child: const AppliancesSkeleton(dark: true),
              )
            else if (_items.isEmpty)
              EmptyState(
                dark: true,
                icon: Icons.kitchen_outlined,
                title: tr('no_appliances'),
                subtitle: tr('no_appliances_sub'),
                actionLabel: tr('add_equipment'),
                onAction: _openAppliances,
              )
            else
              Wrap(
                spacing: 14,
                runSpacing: 12,
                children: [
                  for (var i = 0; i < _items.length; i++)
                    ApplianceItem(
                      dark: true,
                      item: Appliance(
                        _items[i].name,
                        '${_items[i].kwhMonth.toStringAsFixed(1)} kWh',
                        _iconForTipo(_items[i].tipo),
                        _tileColors[i % _tileColors.length],
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 14),
            SolarCtaCard(title: tr('learn_cta'), icon: Icons.school_outlined, onTap: () => _go(1)),
            const SizedBox(height: 10),
            SolarOutlineCard(title: tr('edit_appliances'), icon: Icons.settings_outlined, onTap: _openAppliances),
          ],
        ),
      ),
    );
  }

  // ---------- TABLET / DESKTOP ----------
  Widget _tablet(BuildContext context) {
    return SingleChildScrollView(
      padding: Responsive.pagePadding(context),
      child: Column(children: [
        _consumptionCard(),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _AppliancesSummary(items: _items, loading: _loading, onOpen: _openAppliances)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(children: [
              SolarCtaCard(title: tr('solar_cta'), icon: Icons.solar_power_rounded, onTap: () => _go(2)),
              const SizedBox(height: 10),
              SolarOutlineCard(title: tr('edit_appliances'), icon: Icons.settings_outlined, onTap: _openAppliances),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        _learnBanner(_go),
      ]),
    );
  }

  Widget _desktop(BuildContext context) {
    return Column(
      children: [
        _consumptionCard(),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: _AppliancesSummary(items: _items, loading: _loading, onOpen: _openAppliances)),
            const SizedBox(width: 16),
            Expanded(
              flex: 4,
              child: Column(children: [
                SolarCtaCard(title: tr('solar_cta'), icon: Icons.solar_power_rounded, onTap: () => _go(2)),
                const SizedBox(height: 12),
                SolarOutlineCard(title: tr('edit_appliances'), icon: Icons.settings_outlined, onTap: _openAppliances),
              ]),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _learnBanner(_go),
      ],
    );
  }

  Widget _consumptionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(tr('consumption'), style: TextStyle(fontSize: 13, color: context.tMed)),
                    _loading
                        ? const SkeletonBox(height: 32, width: 140, radius: 6)
                        : Text(
                            _total > 0 ? '${_total.toStringAsFixed(1)} kWh' : '-- kWh',
                            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: context.isDark ? Colors.white : AppColors.primaryDark),
                          ),
                    Text(
                      _total > 0 ? '${_items.length} ${tr('appliances').toLowerCase()}' : tr('no_records'),
                      style: TextStyle(fontSize: 12, color: context.tMed),
                    ),
                  ]),
                ),
                const Icon(Icons.wb_sunny_outlined, color: AppColors.accent, size: 36),
              ],
            ),
            const SizedBox(height: 8),
            Text(tr('monthly'), style: TextStyle(fontSize: 12, color: context.tMed)),
            const SizedBox(height: 8),
            _loading
                ? const ChartSkeleton(height: 180)
                : (_items.isEmpty
                    ? const EmptyChartBox(height: 180)
                    : _BarChart(items: _items, height: 200)),
          ],
        ),
      ),
    );
  }

  Widget _learnBanner(void Function(int) onTap) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.15), shape: BoxShape.circle), child: const Icon(Icons.school_outlined, color: AppColors.accentDark, size: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tr('banner_title'), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: context.tDark)),
                const SizedBox(height: 4),
                Text(tr('banner_sub'), style: TextStyle(fontSize: 13, color: context.tMed)),
              ]),
            ),
            ElevatedButton(
              onPressed: () => onTap(1),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: Text(tr('go_learn')),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gráfico de barras verticales de consumo mensual por electrodoméstico.
class _BarChart extends StatelessWidget {
  final List<ApplianceItemData> items;
  final bool dark;
  final double height;
  const _BarChart({required this.items, this.dark = false, this.height = 180});

  @override
  Widget build(BuildContext context) {
    final isDark = dark || context.isDark;
    final maxKwh = items.fold<double>(0, (a, e) => e.kwhMonth > a ? e.kwhMonth : a);
    final textColor = isDark ? Colors.white : AppColors.textDark;
    final subColor = isDark ? Colors.white70 : AppColors.textMedium;
    final shown = items.length > 8 ? items.take(8).toList() : items;

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < shown.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      shown[i].kwhMonth.toStringAsFixed(1),
                      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: textColor),
                    ),
                    const SizedBox(height: 3),
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: maxKwh > 0
                              ? (shown[i].kwhMonth / maxKwh).clamp(0.06, 1.0)
                              : 0.06,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFFFFD54D), AppColors.accent],
                              ),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Icon(
                      _iconForTipo(shown[i].tipo),
                      size: 16,
                      color: isDark ? Colors.white70 : AppColors.primary,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      shown[i].name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 9.5, color: subColor),
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

/// Tarjeta "Tus electrodomésticos" con datos reales.
class _AppliancesSummary extends StatelessWidget {
  final List<ApplianceItemData> items;
  final bool loading;
  final VoidCallback onOpen;
  const _AppliancesSummary({required this.items, required this.loading, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('appliances'), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: context.tDark)),
            const SizedBox(height: 12),
            if (loading)
              const AppliancesSkeleton()
            else if (items.isEmpty)
              EmptyState(
                icon: Icons.kitchen_outlined,
                title: tr('no_equipment_reg'),
                subtitle: tr('no_equipment_reg_sub'),
                actionLabel: tr('add_equipment'),
                onAction: onOpen,
              )
            else ...[
              for (var i = 0; i < items.length; i++)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: ApplianceTypeIcon(
                      tipo: items[i].tipo, index: i, radius: 18, iconSize: 18),
                  title: Text('${items[i].name} x${items[i].quantity}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  subtitle: Text(items[i].tipo, style: TextStyle(fontSize: 12, color: context.tMed)),
                  trailing: Text('${items[i].kwhMonth.toStringAsFixed(1)} kWh', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: context.isDark ? Colors.white : AppColors.primaryDark)),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text(tr('edit_appliances')),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
