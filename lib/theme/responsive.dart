import 'package:flutter/material.dart';

/// Breakpoints únicos para toda la app.
/// Móvil < 650 | Tablet 650-1099 | Desktop >= 1100
class AppBreakpoints {
  static const double mobile = 650;
  static const double tablet = 1100;
  static const double maxContent = 1200;
}

enum DeviceType { mobile, tablet, desktop }

class Responsive {
  static DeviceType of(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < AppBreakpoints.mobile) return DeviceType.mobile;
    if (w < AppBreakpoints.tablet) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  static bool isMobile(BuildContext context) => of(context) == DeviceType.mobile;
  static bool isTablet(BuildContext context) => of(context) == DeviceType.tablet;
  static bool isDesktop(BuildContext context) => of(context) == DeviceType.desktop;

  /// Padding lateral adaptativo: 16 móvil, 24 tablet, centrado con maxWidth en desktop.
  static EdgeInsets pagePadding(BuildContext context) {
    switch (of(context)) {
      case DeviceType.mobile:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
      case DeviceType.tablet:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
      case DeviceType.desktop:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 20);
    }
  }

  /// Columnas para grids según ancho.
  static int gridColumns(BuildContext context, {int mobile = 2, int tablet = 3, int desktop = 5}) {
    switch (of(context)) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet;
      case DeviceType.desktop:
        return desktop;
    }
  }
}

/// Wrapper que centra el contenido en desktop con ancho máximo.
class CenteredContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const CenteredContent({super.key, required this.child, this.maxWidth = AppBreakpoints.maxContent});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
