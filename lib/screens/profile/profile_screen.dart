import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/solar_text_field.dart';
import '../../widgets/solar_buttons.dart';
import '../../widgets/solar_logo.dart';

/// Mi perfil (solo UI, listo para GET/PUT /me).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _form,
            child: Column(
              children: [
                const CircleAvatar(radius: 36, backgroundColor: AppColors.primary, child: SolarLogo(light: true, fontSize: 0, iconSize: 32)),
                const SizedBox(height: 8),
                const Text('Mi perfil', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const Text('Vacío hasta conectar backend. Edita y guarda (demo).', style: TextStyle(color: AppColors.textMedium, fontSize: 13)),
                const SizedBox(height: 16),
                SolarTextField(controller: _name, label: 'Nombre completo', hint: 'Tu nombre', prefix: Icons.person_outline_rounded, validator: (v) => v == null || v.isEmpty ? 'Requerido' : null),
                const SizedBox(height: 12),
                SolarTextField(controller: _email, label: 'Correo', hint: 'correo@ejemplo.com', prefix: Icons.email_outlined, keyboardType: TextInputType.emailAddress, validator: SolarValidators.email),
                const SizedBox(height: 16),
                SolarPrimaryButton(
                  label: 'Guardar cambios',
                  icon: Icons.save_outlined,
                  onPressed: () {
                    if (!(_form.currentState?.validate() ?? false)) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil guardado (demo). Usará PUT /me.')));
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
