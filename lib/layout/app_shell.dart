import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/lang.dart';
import '../theme/responsive.dart';
import '../widgets/solar_logo.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/learn/learn_screen.dart';
import '../screens/simulator/simulator_screen.dart';
import '../screens/feedback/feedback_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../services/session_store.dart';
import '../widgets/account_menu.dart';
import '../widgets/notifications_panel.dart';

/// Shell adaptativo con 6 secciones:
/// Desktop: sidebar permanente. Móvil: bottom nav (3) + drawer (todas).
class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static List<String> get _titles => [tr('nav_home'), tr('nav_learn'), tr('nav_sim'), tr('nav_feedback'), tr('nav_profile'), tr('nav_settings')];

  void _go(int i) => setState(() => _index = i);

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr('logout_title')),
        content: Text(tr('logout_sub')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr('cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr('logout')),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await SessionStore.clear(); // JWT stateless: basta borrar el token local.
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    final pages = [
      HomeScreen(onNavigate: _go),
      const LearnScreen(),
      const SimulatorScreen(),
      const FeedbackScreen(),
      const ProfileScreen(),
      const SettingsScreen(),
    ];

    if (isDesktop) return _desktopScaffold(pages);
    return _mobileScaffold(pages);
  }

  // ---------- MÓVIL/TABLET ----------
  Widget _mobileScaffold(List<Widget> pages) {
    // Bottom solo muestra las 3 principales; el resto va por drawer.
    final bottomIndex = _index <= 2 ? _index : 0;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_titles[_index], style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: context.tDark)),
        actions: [
          IconButton(tooltip: tr('notifs'), onPressed: () => NotificationsPanel.show(context), icon: const Icon(Icons.notifications_none_rounded)),
          AccountMenuButton(onProfile: () => _go(4), onLogout: _logout),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(gradient: AppColors.blueGradient),
                child: const SolarLogo(light: true, fontSize: 22),
              ),
              for (int i = 0; i < _titles.length; i++)
                ListTile(
                  leading: Icon([Icons.home_outlined, Icons.school_outlined, Icons.calculate_outlined, Icons.chat_bubble_outline_rounded, Icons.person_outline_rounded, Icons.settings_outlined][i]),
                  title: Text(_titles[i]),
                  selected: i == _index,
                  selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
                  onTap: () {
                    Navigator.pop(context);
                    _go(i);
                  },
                ),
              const Divider(),
              ListTile(leading: const Icon(Icons.logout_rounded, color: AppColors.error), title: Text(tr('logout')), onTap: () {
                Navigator.pop(context);
                _logout();
              }),
            ],
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: KeyedSubtree(key: ValueKey(_index), child: pages[_index]),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: bottomIndex,
        onDestinationSelected: _go,
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home_rounded), label: tr('nav_home')),
          NavigationDestination(icon: const Icon(Icons.school_outlined), selectedIcon: const Icon(Icons.school_rounded), label: tr('nav_learn')),
          NavigationDestination(icon: const Icon(Icons.calculate_outlined), selectedIcon: const Icon(Icons.calculate_rounded), label: tr('nav_sim')),
        ],
      ),
    );
  }

  // ---------- DESKTOP: sidebar colapsable ----------
  bool _sidebarOpen = true;

  Widget _desktopScaffold(List<Widget> pages) {
    final items = [
      (Icons.home_outlined, tr('nav_home')),
      (Icons.school_outlined, tr('nav_learn')),
      (Icons.calculate_outlined, tr('nav_sim')),
      (Icons.chat_bubble_outline_rounded, tr('nav_feedback')),
      (Icons.person_outline_rounded, tr('nav_profile')),
      (Icons.settings_outlined, tr('nav_settings')),
    ];
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            width: _sidebarOpen ? 240 : 76,
            decoration: const BoxDecoration(gradient: AppColors.blueGradient),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: _sidebarOpen
                        ? const SolarLogo(light: true, fontSize: 24)
                        : const Icon(Icons.solar_power_rounded, color: Colors.white, size: 30),
                  ),
                  for (int i = 0; i < items.length; i++)
                    _sideItem(i, items[i].$1, items[i].$2, i == _index, () => _go(i)),
                  const Spacer(),
                  _sideItem(-1, Icons.logout_rounded, tr('logout'), false, _logout),
                  if (_sidebarOpen) ...[
                    const SizedBox(height: 12),
                    // Dibujo: casa + paneles solares
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Opacity(
                        opacity: 0.9,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.home_rounded, size: 44, color: Colors.white38),
                            SizedBox(width: 6),
                            Icon(Icons.solar_power_rounded, size: 56, color: Colors.white54),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(color: Colors.white24, height: 1),
                  ),
                  // Flecha al pie para plegar/desplegar el menú
                  IconButton(
                    tooltip: _sidebarOpen ? tr('collapse_menu') : tr('expand_menu'),
                    onPressed: () => setState(() => _sidebarOpen = !_sidebarOpen),
                    icon: Icon(_sidebarOpen ? Icons.chevron_left_rounded : Icons.chevron_right_rounded, color: Colors.white70, size: 28),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  color: context.cardBg,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Text(_titles[_index], style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.tDark)),
                      const Spacer(),
                      IconButton(tooltip: tr('notifs'), onPressed: () => NotificationsPanel.show(context), icon: Icon(Icons.notifications_none_rounded, color: context.tDark)),
                      AccountMenuButton(onProfile: () => _go(4), onLogout: _logout),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: CenteredContent(child: AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: KeyedSubtree(key: ValueKey(_index), child: pages[_index]))),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sideItem(int idx, IconData icon, String label, bool selected, VoidCallback onTap) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: _sidebarOpen
          ? Row(children: [
              Icon(icon, color: selected ? AppColors.accent : Colors.white70, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(color: selected ? Colors.white : Colors.white70, fontWeight: selected ? FontWeight.w800 : FontWeight.w500, fontSize: 13.5))),
            ])
          : Center(child: Icon(icon, color: selected ? AppColors.accent : Colors.white70, size: 22)),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Tooltip(
        message: _sidebarOpen ? '' : label,
        child: Material(
          color: selected ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            hoverColor: Colors.white10,
            child: content,
          ),
        ),
      ),
    );
  }
}
