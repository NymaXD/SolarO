import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
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

  static const _titles = ['Inicio', 'Aprende', 'Simulador', 'Enviar comentarios', 'Mi perfil', 'Configuración'];

  void _go(int i) => setState(() => _index = i);

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres salir? Volverás a la pantalla de inicio de sesión.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const SolarLogo(fontSize: 20),
        actions: [
          IconButton(tooltip: 'Notificaciones', onPressed: () => NotificationsPanel.show(context), icon: const Icon(Icons.notifications_none_rounded)),
          PopupMenuButton<String>(
            tooltip: 'Cuenta',
            icon: const Icon(Icons.account_circle_outlined),
            onSelected: (v) {
              if (v == 'profile') _go(4);
              if (v == 'logout') _logout();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'profile', child: Text('Mi perfil')),
              PopupMenuItem(value: 'logout', child: Text('Cerrar sesión')),
            ],
          ),
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
              ListTile(leading: const Icon(Icons.logout_rounded, color: AppColors.error), title: const Text('Cerrar sesión'), onTap: () {
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
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school_rounded), label: 'Aprende'),
          NavigationDestination(icon: Icon(Icons.calculate_outlined), selectedIcon: Icon(Icons.calculate_rounded), label: 'Simulador'),
        ],
      ),
    );
  }

  // ---------- DESKTOP ----------
  Widget _desktopScaffold(List<Widget> pages) {
    const items = [
      (Icons.home_outlined, 'Inicio'),
      (Icons.school_outlined, 'Aprende'),
      (Icons.calculate_outlined, 'Simulador'),
      (Icons.chat_bubble_outline_rounded, 'Enviar comentarios'),
      (Icons.person_outline_rounded, 'Mi perfil'),
      (Icons.settings_outlined, 'Configuración'),
    ];
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          Container(
            width: 240,
            decoration: const BoxDecoration(gradient: AppColors.blueGradient),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(padding: EdgeInsets.all(20), child: SolarLogo(light: true, fontSize: 24)),
                  for (int i = 0; i < items.length; i++)
                    _sideItem(i, items[i].$1, items[i].$2, i == _index, () => _go(i)),
                  const Spacer(),
                  _sideItem(-1, Icons.logout_rounded, 'Cerrar sesión', false, _logout),
                  const SizedBox(height: 12),
                  // Dibujo restaurado: casa + paneles solares
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
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    children: [
                      Text(_titles[_index], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                      const Spacer(),
                      IconButton(tooltip: 'Notificaciones', onPressed: () => NotificationsPanel.show(context), icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textDark)),
                      PopupMenuButton<String>(
                        tooltip: 'Cuenta',
                        icon: const Icon(Icons.account_circle_outlined, color: AppColors.textDark),
                        onSelected: (v) {
                          if (v == 'profile') _go(4);
                          if (v == 'logout') _logout();
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'profile', child: Text('Mi perfil')),
                          PopupMenuItem(value: 'logout', child: Text('Cerrar sesión')),
                        ],
                      ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: selected ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          hoverColor: Colors.white10,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(children: [
              Icon(icon, color: selected ? AppColors.accent : Colors.white70, size: 20),
              const SizedBox(width: 10),
              Text(label, style: TextStyle(color: selected ? Colors.white : Colors.white70, fontWeight: selected ? FontWeight.w800 : FontWeight.w500, fontSize: 13.5)),
            ]),
          ),
        ),
      ),
    );
  }
}
