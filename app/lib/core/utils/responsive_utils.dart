import 'package:flutter/material.dart';

enum DeviceType { mobile, tablet, desktop }

class ResponsiveUtils {
  ResponsiveUtils._();

  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1024) return DeviceType.desktop;
    if (width >= 600) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  static bool isMobile(BuildContext context) =>
      getDeviceType(context) == DeviceType.mobile;

  static bool isTablet(BuildContext context) =>
      getDeviceType(context) == DeviceType.tablet;

  static bool isDesktop(BuildContext context) =>
      getDeviceType(context) == DeviceType.desktop;

  static bool isWeb() {
    try {
      return const bool.fromEnvironment('dart.library.html_util');
    } catch (_) {
      return false;
    }
  }

  static double getSidebarWidth(BuildContext context) {
    final device = getDeviceType(context);
    switch (device) {
      case DeviceType.desktop:
        return 260;
      case DeviceType.tablet:
        return 76;
      case DeviceType.mobile:
        return 0;
    }
  }

  static int getGridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1400) return 4;
    if (width >= 1000) return 3;
    if (width >= 600) return 2;
    return 1;
  }

  static double getContentMaxWidth(BuildContext context) {
    final device = getDeviceType(context);
    switch (device) {
      case DeviceType.desktop:
        return 1400;
      case DeviceType.tablet:
        return 960;
      case DeviceType.mobile:
        return double.infinity;
    }
  }
}

class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final Widget Function(BuildContext) mobile;
  final Widget Function(BuildContext)? tablet;
  final Widget Function(BuildContext)? desktop;

  @override
  Widget build(BuildContext context) {
    final device = ResponsiveUtils.getDeviceType(context);
    switch (device) {
      case DeviceType.desktop:
        return desktop?.call(context) ??
            tablet?.call(context) ??
            mobile(context);
      case DeviceType.tablet:
        return tablet?.call(context) ?? mobile(context);
      case DeviceType.mobile:
        return mobile(context);
    }
  }
}
