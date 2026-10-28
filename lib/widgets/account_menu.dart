import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/session_store.dart';
import '../theme/app_colors.dart';
import '../theme/lang.dart';

/// Menú de cuenta (avatar arriba + topbar): muestra nombre y correo
/// guardados en la sesión y ofrece Mi perfil / Cerrar sesión.
class AccountMenuButton extends StatelessWidget {
  final VoidCallback onProfile;
  final VoidCallback onLogout;
  final Color iconColor;
  final Color? avatarBackground;
  final Color? avatarForeground;
  const AccountMenuButton({
    super.key,
    required this.onProfile,
    required this.onLogout,
    this.iconColor = AppColors.textDark,
    this.avatarBackground,
    this.avatarForeground,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AuthUser?>(
      future: SessionStore.readUser(),
      builder: (context, snap) {
        final user = snap.data;
        final initial = (user?.nombre.trim().isNotEmpty == true) ? user!.nombre.trim()[0].toUpperCase() : '?';
        return PopupMenuButton<String>(
          tooltip: tr('nav_profile'),
          icon: user == null
              ? Icon(Icons.account_circle_outlined, color: iconColor)
              : CircleAvatar(
                  radius: 14,
                  backgroundColor: avatarBackground ?? AppColors.primary,
                  child: Text(initial,
                      style: TextStyle(
                          color: avatarForeground ?? Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13)),
                ),
          onSelected: (v) {
            if (v == 'profile') onProfile();
            if (v == 'logout') onLogout();
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              enabled: false,
              child: Row(
                children: [
                  CircleAvatar(radius: 18, backgroundColor: AppColors.primary.withValues(alpha: 0.12), child: Text(initial, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(user?.nombre ?? tr('no_session'), overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: context.tDark)),
                        Text(user?.email ?? '', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: context.tMed)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(value: 'profile', child: Row(children: [const Icon(Icons.person_outline_rounded, size: 20), const SizedBox(width: 8), Text(tr('nav_profile'))])),
            PopupMenuItem(value: 'logout', child: Row(children: [const Icon(Icons.logout_rounded, size: 20, color: AppColors.error), const SizedBox(width: 8), Text(tr('logout'))])),
          ],
        );
      },
    );
  }
}
