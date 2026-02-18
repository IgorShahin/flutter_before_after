import 'package:flutter/material.dart';

import 'desktop_zoom_options.dart';

/// Grouped zoom configuration for [BeforeAfter].
@immutable
class BeforeAfterZoomOptions {
  const BeforeAfterZoomOptions({
    this.enabled = true,
    this.gestureZoomSmoothing = 1.0,
    this.zoomPanSensitivity = 1.0,
    this.desktop = const DesktopZoomOptions(),
    this.enableDoubleTapZoom = true,
    this.doubleTapZoomScale = 3.0,
    this.doubleTapZoomDuration = const Duration(milliseconds: 420),
    this.doubleTapZoomCurve = Curves.easeInOutCubic,
  })  : assert(
          gestureZoomSmoothing > 0.0 && gestureZoomSmoothing <= 1.0,
          'gestureZoomSmoothing must be in (0.0, 1.0]',
        ),
        assert(
          zoomPanSensitivity > 0.0,
          'zoomPanSensitivity must be > 0.0',
        ),
        assert(
          doubleTapZoomScale >= 1.0,
          'doubleTapZoomScale must be >= 1.0',
        );

  final bool enabled;
  final double gestureZoomSmoothing;
  final double zoomPanSensitivity;
  final DesktopZoomOptions desktop;
  final bool enableDoubleTapZoom;
  final double doubleTapZoomScale;
  final Duration doubleTapZoomDuration;
  final Curve doubleTapZoomCurve;
}
