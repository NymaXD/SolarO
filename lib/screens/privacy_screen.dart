import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/lang.dart';

/// Política de privacidad: página 100% estática, sin backend.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  /// Correos de contacto del equipo.
  static const _supportEmails = [
    'nirayyu.munozam@ecci.edu.co',
    'juanda.lagunaba@ecci.edu.co',
    'michaelda.moraro@ecci.edu.co',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text(tr('privacy_title'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('privacy_title'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: context.tDark)),
                    const SizedBox(height: 8),
                    Text(tr('privacy_intro'), style: TextStyle(fontSize: 13.5, color: context.tMed)),
                    const SizedBox(height: 16),
                    _section(context, Icons.data_usage_outlined, tr('privacy_use'), tr('privacy_use_body')),
                    _section(context, Icons.schedule_outlined, tr('privacy_store'), tr('privacy_store_body')),
                    _section(context, Icons.mail_outline_rounded, tr('privacy_contact'), tr('privacy_contact_body')),
                    const SizedBox(height: 8),
                    for (final email in _supportEmails)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: context.isDark ? 0.15 : 0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: context.border)),
                          child: Row(
                            children: [
                              const Icon(Icons.mail_outline_rounded, color: AppColors.primary),
                              const SizedBox(width: 10),
                              Expanded(child: Text(email, style: TextStyle(fontWeight: FontWeight.w700, color: context.tDark))),
                              IconButton(
                                tooltip: tr('copy_email'),
                                color: context.isDark ? AppColors.primaryBright : AppColors.primary,
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: email));
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('email_copied'))));
                                },
                                icon: const Icon(Icons.copy_rounded, size: 18),
                              ),
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

  static Widget _section(BuildContext context, IconData icon, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: context.isDark ? AppColors.primaryBright : AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: context.tDark)),
                const SizedBox(height: 2),
                Text(body, style: TextStyle(fontSize: 13, color: context.tMed)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
