import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/solar_text_field.dart';
import '../../widgets/solar_buttons.dart';

/// Enviar comentarios (solo UI, listo para POST /feedback).
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});
  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _form = GlobalKey<FormState>();
  final _msg = TextEditingController();
  int _stars = 5;

  @override
  void dispose() {
    _msg.dispose();
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary), SizedBox(width: 8), Text('Enviar comentarios', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))]),
                const SizedBox(height: 4),
                const Text('Cuéntanos qué mejorar. Se enviará al backend cuando esté listo.', style: TextStyle(color: AppColors.textMedium, fontSize: 13)),
                const SizedBox(height: 16),
                const Text('Calificación', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Row(children: [for (int i = 1; i <= 5; i++) IconButton(onPressed: () => setState(() => _stars = i), icon: Icon(i <= _stars ? Icons.star_rounded : Icons.star_outline_rounded, color: AppColors.accentDark, size: 28))]),
                const SizedBox(height: 8),
                SolarTextField(controller: _msg, label: 'Comentario', hint: 'Escribe tu comentario...', prefix: Icons.message_outlined, validator: (v) => v == null || v.trim().isEmpty ? 'Escribe un comentario' : null),
                const SizedBox(height: 16),
                SolarPrimaryButton(
                  label: 'Enviar comentario',
                  icon: Icons.send_outlined,
                  onPressed: () {
                    if (!(_form.currentState?.validate() ?? false)) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comentario guardado (demo). Se enviará con POST /feedback.')));
                    _msg.clear();
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
