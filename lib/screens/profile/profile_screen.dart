import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/lang.dart';
import '../../widgets/solar_buttons.dart';
import '../../widgets/solar_logo.dart';
import '../../widgets/solar_text_field.dart';
import '../../services/session_store.dart';
import '../auth/auth_screen.dart';

/// Mi perfil conectado al backend (`GET|PUT /users/me`, `PUT /users/me/password`).
/// Precarga desde la sesión y refresca contra la API al abrir.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _passForm = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _current = TextEditingController();
  final _newPass = TextEditingController();
  final _newPass2 = TextEditingController();
  bool _saving = false;
  bool _changing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// 1) pinta lo guardado en sesión al instante; 2) refresca con GET /users/me.
  Future<void> _load() async {
    final cached = await SessionStore.readUser();
    if (!mounted) return;
    if (cached != null) {
      setState(() {
        _name.text = cached.nombre;
        _email.text = cached.email;
      });
    }
    final token = await SessionStore.validToken();
    if (!mounted || token == null) return;
    try {
      final fresh = await UserService().getMe(token);
      await SessionStore.updateUser(fresh);
      if (!mounted) return;
      setState(() {
        _name.text = fresh.nombre;
        _email.text = fresh.email;
      });
    } on AuthException {
      // Sin red o sesión vencida: se queda con lo guardado en sesión.
    }
  }

  Future<void> _sessionExpired() async {
    await SessionStore.clear();
    if (!mounted) return;
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => const AuthScreen()));
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final token = await SessionStore.validToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('no_session'))));
      return;
    }
    setState(() => _saving = true);
    try {
      final updated = await UserService().updateMe(token: token, nombre: _name.text, email: _email.text);
      final current = await SessionStore.readUser();
      await SessionStore.updateUser(AuthUser(id: current?.id ?? updated.id, nombre: updated.nombre, email: updated.email));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('profile_updated'))));
    } on AuthException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        await _sessionExpired();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePassword() async {
    if (!(_passForm.currentState?.validate() ?? false)) return;
    // Se guardan y limpian de inmediato (texto + errores) para no confundir.
    final actual = _current.text;
    final nueva = _newPass.text;
    _passForm.currentState?.reset();
    _current.clear();
    _newPass.clear();
    _newPass2.clear();
    final token = await SessionStore.validToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('no_session'))));
      return;
    }
    setState(() => _changing = true);
    try {
      final msg = await UserService().updatePassword(token: token, actual: actual, nueva: nueva);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } on AuthException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        await _sessionExpired();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _changing = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _current.dispose();
    _newPass.dispose();
    _newPass2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _form,
                child: Column(
                  children: [
                    const CircleAvatar(radius: 36, backgroundColor: AppColors.primary, child: SolarLogo(light: true, fontSize: 0, iconSize: 32)),
                    const SizedBox(height: 8),
                    Text(tr('profile_title'), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: context.tDark)),
                    Text(tr('profile_sub'), style: TextStyle(color: context.tMed, fontSize: 13)),
                    const SizedBox(height: 16),
                    SolarTextField(controller: _name, label: tr('name_label'), hint: tr('your_name'), prefix: Icons.person_outline_rounded, validator: SolarValidators.personName),
                    const SizedBox(height: 12),
                    SolarTextField(controller: _email, label: tr('reg_email_label'), hint: tr('email_hint'), prefix: Icons.email_outlined, keyboardType: TextInputType.emailAddress, validator: SolarValidators.email),
                    const SizedBox(height: 16),
                    SolarPrimaryButton(label: tr('save_changes'), icon: Icons.save_outlined, loading: _saving, onPressed: _save),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _passForm,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('change_pass'), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: context.tDark)),
                    const SizedBox(height: 12),
                    SolarTextField(controller: _current, label: tr('current_pass'), hint: tr('current_pass_hint'), prefix: Icons.lock_outline_rounded, obscure: true, validator: SolarValidators.password),
                    const SizedBox(height: 12),
                    SolarTextField(controller: _newPass, label: tr('new_pass'), hint: tr('reg_pass_hint'), prefix: Icons.lock_outline_rounded, obscure: true, validator: SolarValidators.registerPassword),
                    const SizedBox(height: 12),
                    SolarTextField(
                      controller: _newPass2,
                      label: tr('confirm_pass'),
                      hint: tr('confirm_hint'),
                      prefix: Icons.lock_outline_rounded,
                      obscure: true,
                      textInputAction: TextInputAction.done,
                      validator: (v) {
                        if (v == null || v.isEmpty) return tr('confirm_empty');
                        if (v != _newPass.text) return tr('confirm_mismatch');
                        return null;
                      },
                      onSubmitted: (_) => _changePassword(),
                    ),
                    const SizedBox(height: 16),
                    SolarPrimaryButton(label: tr('update_pass'), icon: Icons.key_outlined, loading: _changing, onPressed: _changePassword),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
