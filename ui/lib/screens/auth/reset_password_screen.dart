import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/reset_token.dart';
import '../../services/used_tokens_store.dart';
import '../../theme/app_colors.dart';
import '../../theme/lang.dart';
import '../../widgets/solar_buttons.dart';
import '../../widgets/solar_logo.dart';
import '../../widgets/solar_text_field.dart';
import 'auth_screen.dart';

/// Pantalla para el enlace del correo (`/reset-password` con `?t=` igual al JWT).
/// Valida el token ANTES de mostrar el formulario: si está malformado o
/// vencido (15 min) muestra página de enlace inválido en vez del form.
/// La validez criptográfica final la impone POST /auth/reset-password.
class ResetPasswordScreen extends StatefulWidget {
  final String token;
  const ResetPasswordScreen({super.key, required this.token});

  /// Extrae `?t=` de la URL actual (web). Null si no hay token.
  static String? tokenFromUrl() {
    if (!kIsWeb) return null;
    final t = Uri.base.queryParameters['t'];
    return (t == null || t.isEmpty) ? null : t;
  }

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  bool _loading = false;
  bool? _valid; // null = verificando (loader breve)

  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  /// Valida el enlace antes de mostrar nada: formato, expiración y si YA
  /// se usó en este navegador (el JWT no es de un solo uso en el servidor).
  Future<void> _checkToken() async {
    final info = tryParseResetToken(widget.token);
    var ok = info != null && !info.isExpired;
    final jti = info?.jti;
    if (ok && jti != null) {
      ok = !(await UsedTokensStore.isUsed(jti));
    }
    if (mounted) setState(() => _valid = ok);
  }

  @override
  void dispose() {
    _pass.dispose();
    _pass2.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final msg = await AuthService().resetPassword(token: widget.token, contrasena: _pass.text);
      final used = tryParseResetToken(widget.token);
      final usedJti = used?.jti;
      if (usedJti != null) await UsedTokensStore.markUsed(usedJti, used?.expiresAt);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      _goAuth();
    } on AuthException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401 || e.statusCode == 422) {
        // Token vencido o inválido según el backend: mostrar página de enlace inválido.
        setState(() => _valid = false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goAuth() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: _valid == null
                    ? const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 32), child: CircularProgressIndicator()))
                    : (_valid! ? _formView() : _invalidView()),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _formView() {
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Center(child: SolarLogo(fontSize: 24)),
          const SizedBox(height: 16),
          Text(tr('reset_title'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.tDark)),
          Text(tr('reset_sub'), style: TextStyle(color: context.tMed, fontSize: 13)),
          const SizedBox(height: 16),
          SolarTextField(controller: _pass, label: tr('new_pass'), hint: tr('reg_pass_hint'), prefix: Icons.lock_outline_rounded, obscure: true, validator: SolarValidators.registerPassword),
          const SizedBox(height: 12),
          SolarTextField(
            controller: _pass2,
            label: tr('confirm_pass'),
            hint: tr('confirm_hint'),
            prefix: Icons.lock_outline_rounded,
            obscure: true,
            validator: (v) {
              if (v == null || v.isEmpty) return tr('confirm_empty');
              if (v != _pass.text) return tr('confirm_mismatch');
              return null;
            },
          ),
          const SizedBox(height: 16),
          SolarPrimaryButton(label: tr('save_pass'), icon: Icons.save_outlined, loading: _loading, onPressed: _submit),
          const SizedBox(height: 8),
          Center(child: SolarLinkButton(label: tr('back_login'), onPressed: _goAuth)),
        ],
      ),
    );
  }

  Widget _invalidView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Center(child: SolarLogo(fontSize: 24)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.error.withValues(alpha: 0.1)),
          child: const Icon(Icons.link_off_rounded, color: AppColors.error, size: 32),
        ),
        const SizedBox(height: 12),
        Text(tr('invalid_title'), textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.tDark)),
        const SizedBox(height: 6),
        Text(
          tr('invalid_sub'),
          textAlign: TextAlign.center,
          style: TextStyle(color: context.tMed, fontSize: 13),
        ),
        const SizedBox(height: 16),
        SolarPrimaryButton(label: tr('request_new'), icon: Icons.email_outlined, onPressed: _goAuth),
      ],
    );
  }
}
