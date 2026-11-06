import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/lang.dart';

class SolarNotification {
  final String title;
  final String body;
  final String time;
  final IconData icon;
  bool read;
  SolarNotification({required this.title, required this.body, required this.time, required this.icon, this.read = false});
}

/// Panel tipo YouTube: dropdown con lista y "marcar leídas".
/// Empieza vacío; TODO-BACKEND: llenar con GET /notifications.
class NotificationsPanel extends StatefulWidget {
  const NotificationsPanel({super.key});
  @override
  State<NotificationsPanel> createState() => _NotificationsPanelState();

  /// Helper: abre como dropdown arriba-derecha en desktop y bottom-sheet en móvil.
  static void show(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 700;
    if (isWide) {
      showDialog(
        context: context,
        barrierColor: Colors.black12,
        builder: (_) => const Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: EdgeInsets.only(top: 56, right: 16),
            child: SizedBox(width: 380, child: NotificationsPanel()),
          ),
        ),
      );
    } else {
      showModalBottomSheet(context: context, showDragHandle: true, isScrollControlled: true, builder: (_) => const Padding(padding: EdgeInsets.only(bottom: 16), child: NotificationsPanel()));
    }
  }
}

class _NotificationsPanelState extends State<NotificationsPanel> {
  final List<SolarNotification> _items = [];

  @override
  Widget build(BuildContext context) {
    final unread = _items.where((e) => !e.read).length;
    return Material(
      color: context.cardBg,
      borderRadius: BorderRadius.circular(16),
      elevation: 8,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
              child: Row(
                children: [
                  Text(tr('notifs_title') + (unread > 0 ? ' ($unread)' : ''), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: context.tDark)),
                  const Spacer(),
                  if (_items.isNotEmpty)
                    TextButton(
                      onPressed: () => setState(() {
                        for (final e in _items) {
                          e.read = true;
                        }
                      }),
                      child: Text(tr('mark_read'), style: const TextStyle(fontSize: 12)),
                    ),
                  IconButton(tooltip: tr('close'), onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, size: 20)),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: _items.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withValues(alpha: 0.08)),
                            child: const Icon(Icons.notifications_none_rounded, size: 30, color: AppColors.primary),
                          ),
                          const SizedBox(height: 10),
                          Text(tr('no_notifs'), style: TextStyle(fontWeight: FontWeight.w700, color: context.tMed)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: _items.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final n = _items[i];
                        return ListTile(
                          leading: Stack(
                            children: [
                              CircleAvatar(backgroundColor: AppColors.primary.withValues(alpha: 0.08), child: Icon(n.icon, color: AppColors.primary, size: 20)),
                              if (!n.read) Positioned(right: 0, top: 0, child: Container(width: 10, height: 10, decoration: BoxDecoration(color: AppColors.info, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
                            ],
                          ),
                          title: Text(n.title, style: TextStyle(fontWeight: n.read ? FontWeight.w500 : FontWeight.w800, fontSize: 13.5)),
                          subtitle: Text('${n.body}\n${n.time}', style: const TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                          isThreeLine: true,
                          onTap: () => setState(() => n.read = true),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
