import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/lang.dart';
import '../../theme/responsive.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/home_cards.dart';
import '../../widgets/skeletons.dart';
import '../../widgets/solar_logo.dart';
import '../appliances/appliances_screen.dart';

void openAppliances(BuildContext context) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AppliancesScreen()));
}

/// Dashboard en modo VACÍO (listo para backend).
/// No muestra datos mock: el gráfico y electrodomésticos aparecen vacíos
/// hasta que el usuario registre. Mantiene el layout del mockup.
class HomeScreen extends StatefulWidget {
  final void Function(int) onNavigate;
  const HomeScreen({super.key, required this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true; // Simula carga backend. Con API real: FutureBuilder.

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  void _go(int i) => widget.onNavigate(i);

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
            const Text('-- kWh', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 4),
            Text(tr('no_consumption'), style: const TextStyle(color: Colors.white60, fontSize: 12)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('monthly'), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 8),
                  _loading ? const ChartSkeleton(dark: true, height: 160) : const EmptyChartBox(dark: true, height: 160),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(tr('appliances'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 8),
            _loading
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(16)),
                    child: const AppliancesSkeleton(dark: true),
                  )
                : EmptyState(
                    dark: true,
                    icon: Icons.kitchen_outlined,
                    title: tr('no_appliances'),
                    subtitle: tr('no_appliances_sub'),
                    actionLabel: tr('add_equipment'),
                    onAction: () => openAppliances(context),
                  ),
            const SizedBox(height: 14),
            SolarCtaCard(title: tr('learn_cta'), icon: Icons.school_outlined, onTap: () => _go(1)),
            const SizedBox(height: 10),
            SolarOutlineCard(title: tr('edit_appliances'), icon: Icons.settings_outlined, onTap: () => openAppliances(context)),
          ],
        ),
      ),
    );
  }

  // ---------- TABLET / DESKTOP (fondo claro, vacío) ----------
  Widget _tablet(BuildContext context) {
    return SingleChildScrollView(
      padding: Responsive.pagePadding(context),
      child: Column(children: [
        _consumptionCardEmpty(),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _AppliancesEmpty(context, _loading)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(children: [
              SolarCtaCard(title: tr('solar_cta'), icon: Icons.solar_power_rounded, onTap: () => _go(2)),
              const SizedBox(height: 10),
              SolarOutlineCard(title: tr('edit_appliances'), icon: Icons.settings_outlined, onTap: () => openAppliances(context)),
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
        _consumptionCardEmpty(),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: _AppliancesEmpty(context, _loading)),
            const SizedBox(width: 16),
            Expanded(
              flex: 4,
              child: Column(children: [
                SolarCtaCard(title: tr('solar_cta'), icon: Icons.solar_power_rounded, onTap: () => _go(2)),
                const SizedBox(height: 12),
                SolarOutlineCard(title: tr('edit_appliances'), icon: Icons.settings_outlined, onTap: () => openAppliances(context)),
              ]),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _learnBanner(_go),
      ],
    );
  }

  Widget _consumptionCardEmpty() {
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
                        : Text('-- kWh', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: context.isDark ? Colors.white : AppColors.primaryDark)),
                    Text(tr('no_records'), style: TextStyle(fontSize: 12, color: context.tMed)),
                  ]),
                ),
                const Icon(Icons.wb_sunny_outlined, color: AppColors.accent, size: 36),
              ],
            ),
            const SizedBox(height: 8),
            Text(tr('monthly'), style: TextStyle(fontSize: 12, color: context.tMed)),
            const SizedBox(height: 8),
            _loading ? const ChartSkeleton(height: 180) : const EmptyChartBox(height: 180),
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

class _AppliancesEmpty extends StatelessWidget {
  final BuildContext context;
  final bool loading;
  const _AppliancesEmpty(this.context, [this.loading = false]);
  @override
  Widget build(BuildContext ctx) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('appliances'), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: ctx.tDark)),
            const SizedBox(height: 12),
            loading
                ? const AppliancesSkeleton()
                : EmptyState(
                    icon: Icons.kitchen_outlined,
                    title: tr('no_equipment_reg'),
                    subtitle: tr('no_equipment_reg_sub'),
                    actionLabel: tr('add_equipment'),
                    onAction: () => openAppliances(context),
                  ),
          ],
        ),
      ),
    );
  }
}
