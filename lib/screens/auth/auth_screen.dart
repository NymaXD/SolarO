import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/responsive.dart';
import '../../widgets/skeletons.dart';
import '../../widgets/solar_logo.dart';
import '../../widgets/solar_text_field.dart';
import '../../widgets/solar_buttons.dart';
import '../../layout/app_shell.dart';

/// Pantalla Auth responsiva:
/// - Móvil: fondo azul full (mockup Registro) con tabs Login/Registro
/// - Desktop/Tablet: card blanca centrada + panel azul lateral
/// Solo frontend: validación visual + OAuth simulado con delay.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _loginKey = GlobalKey<FormState>();
  final _regKey = GlobalKey<FormState>();

  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _name = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPass = TextEditingController();
  final _kwh = TextEditingController();
  String? _appliance;
  bool _loading = false;
  bool _boot = true; // skeleton inicial (simula carga sesión)

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _boot = false);
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    _email.dispose();
    _pass.dispose();
    _name.dispose();
    _regEmail.dispose();
    _regPass.dispose();
    _kwh.dispose();
    super.dispose();
  }

  Future<void> _mockLogin() async {
    if (!(_loginKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 900)); // simula red
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AppShell()));
  }

  Future<void> _mockRegister() async {
    if (!(_regKey.currentState?.validate() ?? false)) return;
    // Electrodoméstico y kWh opcionales en registro: se completan en Inicio.
    // Si hay kWh, validar formato solo si no está vacío.
    if (_kwh.text.trim().isNotEmpty) {
      final err = SolarValidators.kwh(_kwh.text);
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        return;
      }
    }
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AppShell()));
  }

  void _forgot() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Recuperar contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Te enviaremos un enlace (simulado).', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            TextFormField(controller: _email, decoration: const InputDecoration(hintText: 'correo@ejemplo.com', prefixIcon: Icon(Icons.email_outlined)), validator: SolarValidators.email, autovalidateMode: AutovalidateMode.onUserInteraction),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enlace enviado (simulado). Revisa tu correo.')));
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final isDesktop = c.maxWidth >= AppBreakpoints.mobile;
        if (isDesktop) return _desktop();
        return _mobile();
      },
    );
  }

  // ---------- MÓVIL: fondo azul + watermark detrás (no abajo) ----------
  Widget _mobile() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.blueGradient),
        child: Stack(
          children: [
            // Icono watermark detrás del contenido
            const Positioned(
              top: 120,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: 0.07,
                child: Icon(Icons.solar_power_rounded, size: 280, color: Colors.white),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                child: Column(
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const SolarLogo(light: true, fontSize: 26),
                      IconButton(tooltip: 'Ayuda', onPressed: () {}, icon: const Icon(Icons.person_add_alt_outlined, color: Colors.white)),
                    ]),
                    const SizedBox(height: 8),
                    TabBar(
                      controller: _tab,
                      indicatorColor: AppColors.accent,
                      indicatorWeight: 3,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white60,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      tabs: const [Tab(text: 'Iniciar sesión'), Tab(text: 'Registro de Usuario')],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 640,
                      child: _boot
                          ? const AuthFormSkeleton(dark: true)
                          : TabBarView(controller: _tab, children: [_loginForm(dark: true), _registerForm(dark: true)]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- DESKTOP: split ----------
  Widget _desktop() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                height: 680,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Panel azul
                    Expanded(
                      flex: 5,
                      child: Container(
                        decoration: const BoxDecoration(gradient: AppColors.blueGradient),
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            SolarLogo(light: true, fontSize: 28),
                            SizedBox(height: 24),
                            Text('Ahorra y utiliza\nenergías limpias.', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, height: 1.15)),
                            SizedBox(height: 12),
                            Text('Monitorea tu consumo, aprende y simula tu sistema solar.', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            Spacer(),
                            _DesktopBullets(),
                          ],
                        ),
                      ),
                    ),
                    // Formulario
                    Expanded(
                      flex: 6,
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          children: [
                            TabBar(controller: _tab, labelColor: AppColors.primaryDark, unselectedLabelColor: AppColors.textMedium, indicatorColor: AppColors.accent, labelStyle: const TextStyle(fontWeight: FontWeight.w800), tabs: const [Tab(text: 'Iniciar sesión'), Tab(text: 'Registro')]),
                            const SizedBox(height: 16),
                            Expanded(child: _boot ? const AuthFormSkeleton() : TabBarView(controller: _tab, children: [_loginForm(dark: false), _registerForm(dark: false)])),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Formularios ----------
  Widget _loginForm({required bool dark}) {
    final sub = dark ? Colors.white70 : AppColors.textMedium;
    return Form(
      key: _loginKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Bienvenido de nuevo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: dark ? Colors.white : AppColors.textDark)),
          Text('Ingresa para ver tu consumo y ahorro.', style: TextStyle(color: sub, fontSize: 13)),
          const SizedBox(height: 16),
          SolarTextField(controller: _email, label: 'Correo / usuario', hint: 'usuario@correo.com', prefix: Icons.email_outlined, keyboardType: TextInputType.emailAddress, validator: SolarValidators.email, dark: dark),
          const SizedBox(height: 12),
          SolarTextField(controller: _pass, label: 'Contraseña', hint: '••••••••', prefix: Icons.lock_outline_rounded, obscure: true, validator: SolarValidators.password, dark: dark),
          Align(
            alignment: Alignment.centerRight,
            child: SolarLinkButton(label: '¿Olvidaste tu contraseña? Recuperar', onPressed: _forgot, color: dark ? AppColors.accent : null),
          ),
          const SizedBox(height: 8),
          SolarPrimaryButton(label: 'Iniciar sesión', icon: Icons.login_rounded, loading: _loading, onPressed: _mockLogin),
          const SizedBox(height: 12),
          Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: [
            Text('¿No tienes cuenta?', style: TextStyle(color: sub, fontSize: 13)),
            SolarLinkButton(label: 'Regístrate aquí', onPressed: () => _tab.animateTo(1), color: dark ? AppColors.accent : null),
          ]),
        ],
      ),
    );
  }

  Widget _registerForm({required bool dark}) {
    final sub = dark ? Colors.white70 : AppColors.textMedium;
    return Form(
      key: _regKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Registro de Usuario', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: dark ? Colors.white : AppColors.textDark)),
            Text('Este es el primer paso para empezar a ahorrar y utilizar energías limpias.', style: TextStyle(color: sub, fontSize: 13)),
            const SizedBox(height: 16),
            SolarTextField(controller: _name, label: 'Nombre completo', hint: 'Ingresa tu nombre completo', prefix: Icons.person_outline_rounded, validator: (v) => SolarValidators.required(v, 'Ingresa tu nombre'), dark: dark),
            const SizedBox(height: 12),
            SolarTextField(controller: _regEmail, label: 'Correo electrónico', hint: 'usuario@correo.com', prefix: Icons.email_outlined, keyboardType: TextInputType.emailAddress, validator: SolarValidators.email, dark: dark),
            const SizedBox(height: 12),
            SolarTextField(controller: _regPass, label: 'Contraseña', hint: 'Mínimo 6 caracteres', prefix: Icons.lock_outline_rounded, obscure: true, validator: SolarValidators.password, dark: dark),
            const SizedBox(height: 12),
            Text('Electrodoméstico (opcional, se completa después)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: dark ? Colors.white : AppColors.textDark)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _appliance,
              dropdownColor: dark ? AppColors.primaryDark : Colors.white,
              style: TextStyle(color: dark ? Colors.white : AppColors.textDark),
              decoration: InputDecoration(
                hintText: 'Selecciona un electrodoméstico',
                prefixIcon: const Icon(Icons.kitchen_outlined),
                filled: true,
                fillColor: dark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: dark ? Colors.white30 : AppColors.divider)),
              ),
              items: const [
                DropdownMenuItem(value: 'nevera', child: Text('Nevera')),
                DropdownMenuItem(value: 'lavadora', child: Text('Lavadora')),
                DropdownMenuItem(value: 'aire', child: Text('Aire acondicionado')),
                DropdownMenuItem(value: 'tv', child: Text('Televisor')),
                DropdownMenuItem(value: 'bombilla', child: Text('Bombilla')),
              ],
              onChanged: (v) => setState(() => _appliance = v),
            ),
            const SizedBox(height: 12),
            SolarTextField(controller: _kwh, label: 'Consumo mensual (kWh) (opcional)', hint: 'Ingresa el consumo mensual en kWh', prefix: Icons.bolt_outlined, keyboardType: const TextInputType.numberWithOptions(decimal: true), dark: dark),
            Text('Ejemplo: 15 (puedes dejarlo vacío, lo registrarás en Inicio)', style: TextStyle(color: sub, fontSize: 12)),
            const SizedBox(height: 12),
            SolarPrimaryButton(label: 'Registrarme', icon: Icons.person_add_alt_rounded, loading: _loading, onPressed: _mockRegister),
            const SizedBox(height: 8),
            Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text('¿Ya tienes una cuenta?', style: TextStyle(color: sub, fontSize: 13)),
              SolarLinkButton(label: 'Inicia sesión aquí', onPressed: () => _tab.animateTo(0), color: dark ? AppColors.accent : null),
            ]),
          ],
        ),
      ),
    );
  }
}

class _DesktopBullets extends StatelessWidget {
  const _DesktopBullets();
  @override
  Widget build(BuildContext context) {
    const items = ['Dashboard de consumo mensual', 'Catálogo de electrodomésticos', 'Módulos educativos + simulador'];
    return Column(
      children: [
        for (final t in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [const Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 18), const SizedBox(width: 8), Expanded(child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 13)))]),
          ),
      ],
    );
  }
}

/// Skeleton del formulario auth (se ve 900ms al abrir login/registro).
class AuthFormSkeleton extends StatelessWidget {
  final bool dark;
  const AuthFormSkeleton({super.key, this.dark = false});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SkeletonBox(height: 22, width: 180, radius: 6),
        SizedBox(height: 8),
        SkeletonBox(height: 14, width: 240, radius: 6),
        SizedBox(height: 16),
        SkeletonBox(height: 14, width: 120, radius: 6),
        SizedBox(height: 6),
        SkeletonBox(height: 50, radius: 10),
        SizedBox(height: 12),
        SkeletonBox(height: 14, width: 120, radius: 6),
        SizedBox(height: 6),
        SkeletonBox(height: 50, radius: 10),
        SizedBox(height: 16),
        SkeletonBox(height: 50, radius: 12),
      ],
    );
  }
}
