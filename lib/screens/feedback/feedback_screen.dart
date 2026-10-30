import 'package:flutter/material.dart';

import '../../services/pqrs_store.dart';
import '../../theme/app_colors.dart';
import '../faq_screen.dart';
import '../../theme/lang.dart';
import '../../widgets/solar_buttons.dart';
import '../../widgets/solar_text_field.dart';

/// PQRS: peticiones, quejas, reclamos y sugerencias.
///
/// Cada PQRS se radica con un número consecutivo y se guarda en el
/// dispositivo. El modelo ya está listo para enviarse al backend cuando
/// exista el endpoint.
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});
  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _form = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _msg = TextEditingController();
  String _type = 'petition';
  int _stars = 0;
  bool _sending = false;

  static const _types = ['petition', 'complaint', 'claim', 'suggestion'];

  @override
  void initState() {
    super.initState();
    PqrsStore.instance.load();
  }

  @override
  void dispose() {
    _subject.dispose();
    _msg.dispose();
    super.dispose();
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'complaint':
        return AppColors.warning;
      case 'claim':
        return AppColors.error;
      case 'suggestion':
        return AppColors.success;
      default:
        return context.isDark ? AppColors.primaryBright : AppColors.primary;
    }
  }

  String _typeLabel(String type) => tr('pqrs_type_$type');

  String _date(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year} · $hh:$min';
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _sending = true);
    try {
      final entry = await PqrsStore.instance.add(
        type: _type,
        subject: _subject.text.trim(),
        message: _msg.text.trim(),
        rating: _stars,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${tr('fb_saved')} · ${entry.radicado}')),
      );
      _subject.clear();
      _msg.clear();
      setState(() {
        _type = 'petition';
        _stars = 0;
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PqrsStore.instance,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _formCard(),
              const SizedBox(height: 12),
              _historyCard(),
              const SizedBox(height: 12),
              _helpCard(),
            ],
          ),
        );
      },
    );
  }

  Widget _formCard() {
    final primary = context.isDark ? AppColors.primaryBright : AppColors.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.chat_bubble_outline_rounded, color: primary),
                const SizedBox(width: 8),
                Text(tr('fb_title'),
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: context.tDark)),
              ]),
              const SizedBox(height: 4),
              Text(tr('fb_sub'),
                  style: TextStyle(color: context.tMed, fontSize: 13)),
              const SizedBox(height: 18),
              Text(tr('pqrs_type'),
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: context.tDark)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in _types)
                    ChoiceChip(
                      label: Text(_typeLabel(t)),
                      selected: _type == t,
                      onSelected: (_) => setState(() => _type = t),
                      selectedColor: _typeColor(t),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                        color: _type == t
                            ? Colors.white
                            : (context.isDark
                                ? Colors.white
                                : AppColors.primaryDark),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              SolarTextField(
                controller: _subject,
                label: tr('pqrs_subject'),
                hint: tr('pqrs_subject_hint'),
                prefix: Icons.subject_rounded,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? tr('v_subject') : null,
              ),
              const SizedBox(height: 16),
              SolarTextField(
                controller: _msg,
                label: tr('comment_label'),
                hint: tr('comment_hint'),
                prefix: Icons.message_outlined,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? tr('v_comment') : null,
              ),
              const SizedBox(height: 16),
              Text(tr('pqrs_rating_optional'),
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: context.tDark)),
              Row(children: [
                for (int i = 1; i <= 5; i++)
                  IconButton(
                    tooltip: '${tr('rating')} $i/5',
                    onPressed: () =>
                        setState(() => _stars = _stars == i ? 0 : i),
                    icon: Icon(
                      i <= _stars
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: AppColors.accent,
                      size: 28,
                    ),
                  ),
                const Spacer(),
                if (_stars > 0)
                  Text('$_stars/5',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, color: context.tDark)),
              ]),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.isDark
                      ? AppColors.surfaceDark2
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.border),
                ),
                child: Row(children: [
                  Icon(Icons.cloud_off_outlined,
                      size: 18, color: context.tMed),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(tr('pqrs_local_note'),
                        style:
                            TextStyle(fontSize: 11.5, color: context.tMed)),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              SolarPrimaryButton(
                label: tr('send_fb'),
                icon: Icons.send_outlined,
                loading: _sending,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _historyCard() {
    final store = PqrsStore.instance;
    final primary = context.isDark ? AppColors.primaryBright : AppColors.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.assignment_outlined, color: primary),
              const SizedBox(width: 8),
              Text(tr('pqrs_my'),
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: context.tDark)),
              const Spacer(),
              if (store.entries.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${store.entries.length}',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: primary)),
                ),
            ]),
            const SizedBox(height: 12),
            if (!store.loaded)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (store.entries.isEmpty)
              _emptyHistory()
            else
              for (var i = 0; i < store.entries.length; i++) ...[
                if (i > 0) const Divider(height: 22),
                _entryTile(store.entries[i]),
              ],
          ],
        ),
      ),
    );
  }

  Widget _helpCard() {
    final primary = context.isDark ? AppColors.primaryBright : AppColors.primary;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Icon(Icons.help_outline_rounded, color: primary),
        title: Text(tr('faq_help_title'),
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: context.tDark)),
        subtitle: Text(tr('faq_help_sub'),
            style: TextStyle(fontSize: 12.5, color: context.tMed)),
        trailing: Icon(Icons.chevron_right_rounded, color: context.tMed),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const FaqScreen()),
        ),
      ),
    );
  }

  Widget _emptyHistory() {
    final primary = context.isDark ? AppColors.primaryBright : AppColors.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color:
            context.isDark ? AppColors.surfaceDark2 : AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.border),
      ),
      child: Column(children: [
        Icon(Icons.inbox_outlined, size: 30, color: primary),
        const SizedBox(height: 8),
        Text(tr('pqrs_empty'),
            textAlign: TextAlign.center,
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
                color: context.tDark)),
        const SizedBox(height: 2),
        Text(tr('pqrs_empty_sub'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: context.tMed)),
      ]),
    );
  }

  Widget _entryTile(PqrsEntry e) {
    final color = _typeColor(e.type);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _chip(_typeLabel(e.type), color),
            _chip(tr('pqrs_status_submitted'), AppColors.success),
          ],
        ),
        const SizedBox(height: 8),
        Text(e.subject,
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
                color: context.tDark)),
        const SizedBox(height: 2),
        Text(e.message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12.5, color: context.tMed)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _meta(Icons.confirmation_number_outlined,
                '${tr('pqrs_radicado')}: ${e.radicado}'),
            _meta(Icons.schedule_rounded, _date(e.createdAt)),
            if (e.status != 'synced')
              _meta(Icons.cloud_off_outlined, tr('pqrs_pending_sync')),
          ],
        ),
      ],
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w800, color: color)),
    );
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: context.tMed),
        const SizedBox(width: 4),
        Flexible(
          child: Text(text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: context.tMed)),
        ),
      ],
    );
  }
}
