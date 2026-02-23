import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum DemoPlatformKind {
  web,
  desktop,
  mobile,
}

@immutable
class DemoPlatformProfile {
  const DemoPlatformProfile({
    required this.kind,
    required this.screenWidth,
  });

  final DemoPlatformKind kind;
  final double screenWidth;

  static DemoPlatformProfile from(BuildContext context, double screenWidth) {
    if (kIsWeb) {
      return DemoPlatformProfile(
        kind: DemoPlatformKind.web,
        screenWidth: screenWidth,
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return DemoPlatformProfile(
          kind: DemoPlatformKind.desktop,
          screenWidth: screenWidth,
        );
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        return DemoPlatformProfile(
          kind: DemoPlatformKind.mobile,
          screenWidth: screenWidth,
        );
    }
  }

  bool get isWeb => kind == DemoPlatformKind.web;
  bool get isDesktop => kind == DemoPlatformKind.desktop;
  bool get isMobile => kind == DemoPlatformKind.mobile;

  bool get isWideLayout => screenWidth >= 980 && !isMobile;

  String get title {
    if (isWeb) return 'Web Demo Showcase';
    if (isDesktop) return 'Desktop Demo Showcase';
    return 'Mobile Demo Showcase';
  }

  String get platformBadge {
    if (isWeb) return 'Web';
    if (isDesktop) return 'Desktop';
    return 'Mobile';
  }

  String get modifierLabel {
    if (isMobile) return 'Pinch';
    if (defaultTargetPlatform == TargetPlatform.macOS || isWeb) {
      return 'Cmd';
    }
    return 'Ctrl';
  }

  String get interactionHint {
    if (isMobile) {
      return 'Pinch to zoom, drag to pan, and move slider to compare.';
    }
    return 'Hold $modifierLabel and scroll to zoom, then drag to pan.';
  }

  double get previewHeight {
    if (isMobile) return 460;
    if (isWeb) return 540;
    return 520;
  }
}
