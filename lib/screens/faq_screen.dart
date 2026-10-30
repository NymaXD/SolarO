import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/support_contacts.dart';
import '../theme/app_colors.dart';
import '../theme/lang.dart';

/// Preguntas frecuentes + datos de contacto del equipo.
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const _faqs = [
    ('faq_q1', 'faq_a1'),
    ('faq_q2', 'faq_a2'),
    ('faq_q3', 'faq_a3'),
    ('faq_q4', 'faq_a4'),
    ('faq_q5', 'faq_a5'),
    ('faq_q6', 'faq_a6'),
    ('faq_q7', 'faq_a7'),
    ('faq_q8', 'faq_a8'),
  ];

  Future<void> _copy(BuildContext context, String email) async {
    await Clipboard.setData(ClipboardData(text: email));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(tr('email_copied'))));
  }

  Future<void> _mail(BuildContext context, String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) await _copy(context, email);
  }

  @override
  Widget build(BuildContext context) {
    final primary = context.isDark ? AppColors.primaryBright : AppColors.primary;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text(tr('faq_title'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.help_outline_rounded, color: primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(tr('faq_title'),
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    color: context.tDark)),
                          ),
                        ]),
                        const SizedBox(height: 4),
                        Text(tr('faq_sub'),
                            style:
                                TextStyle(fontSize: 13, color: context.tMed)),
                        const SizedBox(height: 6),
                        for (final f in _faqs)
                          ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            childrenPadding: const EdgeInsets.only(
                                left: 4, right: 4, bottom: 12),
                            iconColor: primary,
                            collapsedIconColor: context.tMed,
                            title: Text(tr(f.$1),
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                    color: context.tDark)),
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(tr(f.$2),
                                    style: TextStyle(
                                        fontSize: 13,
                                        height: 1.45,
                                        color: context.tMed)),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.support_agent_rounded, color: primary),
                          const SizedBox(width: 8),
                          Text(tr('contact_title'),
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: context.tDark)),
                        ]),
                        const SizedBox(height: 4),
                        Text(tr('contact_sub'),
                            style:
                                TextStyle(fontSize: 13, color: context.tMed)),
                        const SizedBox(height: 14),
                        for (final c in supportContacts)
                          _contactTile(context, c, primary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _contactTile(
      BuildContext context, SupportContact contact, Color primary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.surfaceDark2 : AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.border),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: primary.withValues(alpha: 0.14),
          child: Text(
            _initials(contact.name),
            style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 12, color: primary),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(contact.name,
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: context.tDark)),
              const SizedBox(height: 2),
              Text(contact.email,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: context.tMed)),
            ],
          ),
        ),
        IconButton(
          tooltip: tr('copy_email'),
          onPressed: () => _copy(context, contact.email),
          icon: Icon(Icons.copy_rounded, size: 18, color: primary),
        ),
        IconButton(
          tooltip: tr('contact_mail'),
          onPressed: () => _mail(context, contact.email),
          icon: Icon(Icons.mail_outline_rounded, size: 20, color: primary),
        ),
      ]),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    final first = parts.first.substring(0, 1);
    final last = parts.length > 1 ? parts.last.substring(0, 1) : '';
    return '$first$last'.toUpperCase();
  }
}
