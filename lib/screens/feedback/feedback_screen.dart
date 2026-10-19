import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/lang.dart';
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
                Row(children: [
                  Icon(Icons.chat_bubble_outline_rounded, color: context.isDark ? AppColors.primaryBright : AppColors.primary),
                  const SizedBox(width: 8),
                  Text(tr('fb_title'), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: context.tDark)),
                ]),
                const SizedBox(height: 4),
                Text(tr('fb_sub'), style: TextStyle(color: context.tMed, fontSize: 13)),
                const SizedBox(height: 16),
                Text(tr('rating'), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: context.tDark)),
                Row(children: [for (int i = 1; i <= 5; i++) IconButton(tooltip: '${tr('rating')} $i/5', onPressed: () => setState(() => _stars = i), icon: Icon(i <= _stars ? Icons.star_rounded : Icons.star_outline_rounded, color: AppColors.accent, size: 28))]),
                const SizedBox(height: 8),
                SolarTextField(controller: _msg, label: tr('comment_label'), hint: tr('comment_hint'), prefix: Icons.message_outlined, validator: (v) => v == null || v.trim().isEmpty ? tr('v_comment') : null),
                const SizedBox(height: 16),
                SolarPrimaryButton(
                  label: tr('send_fb'),
                  icon: Icons.send_outlined,
                  onPressed: () {
                    if (!(_form.currentState?.validate() ?? false)) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('fb_saved'))));
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
