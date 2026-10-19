import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/lang.dart';
import '../../theme/responsive.dart';
import '../../widgets/lang_switcher.dart';
import '../../widgets/skeletons.dart';
import '../../widgets/solar_logo.dart';
import '../../widgets/solar_text_field.dart';
import '../../widgets/solar_buttons.dart';
import '../../layout/app_shell.dart';
import '../../services/auth_service.dart';
import '../../services/session_store.dart';

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
    super.dispose();
  }

  /// Login real contra POST /auth/login. Guarda JWT y entra al AppShell.
  Future<void> _mockLogin() async {
    if (!(_loginKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final session = await AuthService().login(email: _email.text, contrasena: _pass.text);
      await SessionStore.save(session);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AppShell()));
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Registro real contra POST /auth/register. Al crear, pasa al Login
  /// con el correo precargado para iniciar sesión.
  Future<void> _mockRegister() async {
    if (!(_regKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await AuthService().register(nombre: _name.text, email: _regEmail.text, contrasena: _regPass.text);
      if (!mounted) return;
      _email.text = _regEmail.text.trim().toLowerCase();
      _tab.animateTo(0);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('reg_ok'))));
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Recuperación real contra POST /auth/forgot-password.
  void _forgot() {
    final messenger = ScaffoldMessenger.of(context);
    final emailCtrl = TextEditingController(text: _email.text);
    final formKey = GlobalKey<FormState>();
    bool sending = false;
    late StatefulBuilder dialog;
    dialog = StatefulBuilder(
      builder: (ctx, setDlg) {
        Future<void> submit() async {
          if (!(formKey.currentState?.validate() ?? false)) return;
          setDlg(() => sending = true);
          try {
            final msg = await AuthService().forgotPassword(email: emailCtrl.text);
            if (!ctx.mounted || !mounted) return;
            Navigator.pop(ctx);
            messenger.showSnackBar(SnackBar(content: Text(msg)));
          } on AuthException catch (e) {
            if (!ctx.mounted || !mounted) return;
            setDlg(() => sending = false);
            messenger.showSnackBar(SnackBar(content: Text(e.message)));
          }
        }

        return AlertDialog(
          title: Text(tr('forgot_title')),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(tr('forgot_sub'), style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.send,
                  onFieldSubmitted: (_) => submit(),
                  decoration: const InputDecoration(hintText: 'correo@ejemplo.com', prefixIcon: Icon(Icons.email_outlined)),
                  validator: SolarValidators.email,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: sending ? null : () => Navigator.pop(ctx), child: Text(tr('cancel'))),
            ElevatedButton(
              onPressed: sending ? null : submit,
              child: sending
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : Text(tr('send')),
            ),
          ],
        );
      },
    );
    showDialog(context: context, builder: (_) => dialog).then((_) => emailCtrl.dispose());
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
                    Row(children: [
                      const SolarLogo(light: true, fontSize: 26),
                      const Spacer(),
                      const LangSwitcher(dark: true),
                      IconButton(tooltip: tr('help'), onPressed: () {}, icon: const Icon(Icons.person_add_alt_outlined, color: Colors.white)),
                    ]),
                    const SizedBox(height: 8),
                    TabBar(
                      controller: _tab,
                      indicatorColor: AppColors.accent,
                      indicatorWeight: 3,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white60,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      tabs: [Tab(text: tr('login_tab')), Tab(text: tr('reg_title'))],
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                          children: [
                            const SolarLogo(light: true, fontSize: 28),
                            const SizedBox(height: 24),
                            Text(tr('hero_title'), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, height: 1.15)),
                            const SizedBox(height: 12),
                            Text(tr('hero_sub'), style: const TextStyle(color: Colors.white70, fontSize: 14)),
                            const Spacer(),
                            const _DesktopBullets(),
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
                            const Align(alignment: Alignment.centerRight, child: LangSwitcher()),
                            TabBar(controller: _tab, labelColor: context.tDark, unselectedLabelColor: context.tMed, indicatorColor: AppColors.accent, labelStyle: const TextStyle(fontWeight: FontWeight.w800), tabs: [Tab(text: tr('login_tab')), Tab(text: tr('register_tab'))]),
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
    final sub = dark ? Colors.white70 : context.tMed;
    return Form(
      key: _loginKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(tr('login_title'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: dark ? Colors.white : context.tDark)),
          Text(tr('login_sub'), style: TextStyle(color: sub, fontSize: 13)),
          const SizedBox(height: 16),
          SolarTextField(controller: _email, label: tr('email_label'), hint: tr('email_hint'), prefix: Icons.email_outlined, keyboardType: TextInputType.emailAddress, validator: SolarValidators.email, dark: dark),
          const SizedBox(height: 12),
          SolarTextField(controller: _pass, label: tr('pass_label'), hint: tr('pass_hint_login'), prefix: Icons.lock_outline_rounded, obscure: true, textInputAction: TextInputAction.done, validator: SolarValidators.registerPassword, onSubmitted: (_) => _mockLogin(), dark: dark),
          Align(
            alignment: Alignment.centerRight,
            child: SolarLinkButton(label: tr('forgot_link'), onPressed: _forgot, color: dark ? AppColors.accent : null),
          ),
          const SizedBox(height: 8),
          SolarPrimaryButton(label: tr('login_btn'), icon: Icons.login_rounded, loading: _loading, onPressed: _mockLogin),
          const SizedBox(height: 12),
          Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: [
            Text(tr('no_account'), style: TextStyle(color: sub, fontSize: 13)),
            SolarLinkButton(label: tr('register_link'), onPressed: () => _tab.animateTo(1), color: dark ? AppColors.accent : null),
          ]),
        ],
      ),
    );
  }

  Widget _registerForm({required bool dark}) {
    final sub = dark ? Colors.white70 : context.tMed;
    return Form(
      key: _regKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(tr('reg_title'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: dark ? Colors.white : context.tDark)),
            Text(tr('reg_sub'), style: TextStyle(color: sub, fontSize: 13)),
            const SizedBox(height: 16),
            SolarTextField(controller: _name, label: tr('name_label'), hint: tr('name_hint'), prefix: Icons.person_outline_rounded, validator: SolarValidators.personName, dark: dark),
            const SizedBox(height: 12),
            SolarTextField(controller: _regEmail, label: tr('reg_email_label'), hint: tr('email_hint'), prefix: Icons.email_outlined, keyboardType: TextInputType.emailAddress, validator: SolarValidators.email, dark: dark),
            const SizedBox(height: 12),
            SolarTextField(controller: _regPass, label: tr('pass_label'), hint: tr('reg_pass_hint'), prefix: Icons.lock_outline_rounded, obscure: true, textInputAction: TextInputAction.done, validator: SolarValidators.registerPassword, onSubmitted: (_) => _mockRegister(), dark: dark),
            const SizedBox(height: 12),
            SolarPrimaryButton(label: tr('register_btn'), icon: Icons.person_add_alt_rounded, loading: _loading, onPressed: _mockRegister),
            const SizedBox(height: 8),
            Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text(tr('have_account'), style: TextStyle(color: sub, fontSize: 13)),
              SolarLinkButton(label: tr('login_here'), onPressed: () => _tab.animateTo(0), color: dark ? AppColors.accent : null),
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
    final items = [tr('feat_dashboard'), tr('feat_catalog'), tr('feat_modules')];
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
