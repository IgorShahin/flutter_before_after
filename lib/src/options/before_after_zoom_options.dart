import 'package:flutter/material.dart';

import 'pointer_zoom_options.dart';
import 'zoom_runtime_options.dart';

/// Grouped zoom configuration for [BeforeAfter].
@immutable
class BeforeAfterZoomOptions {
  const BeforeAfterZoomOptions({
    this.enabled = true,
    this.gestureZoomSmoothing = 1.0,
    this.zoomPanSensitivity = 1.0,
    this.showPointerCursor = true,
    this.idleCursor = SystemMouseCursors.basic,
    this.zoomedCursor = SystemMouseCursors.grab,
    this.zoomedDraggingCursor = SystemMouseCursors.grabbing,
    this.pointer = const PointerZoomOptions(),
    this.runtime = const ZoomRuntimeOptions(),
    this.enableDoubleTapZoom = true,
    this.doubleTapZoomScale = 3.0,
    this.doubleTapZoomDuration = const Duration(milliseconds: 420),
    this.doubleTapZoomCurve = Curves.easeInOutCubic,
    this.enableContainerScaleOnZoom = false,
    this.containerScaleMax = 1.12,
    this.containerScaleZoomRange = 2.0,
    this.enableReverseZoomVisualEffect = false,
    this.reverseZoomMinScale = 0.92,
    this.reverseZoomMaxShrink = 0.18,
    this.reverseZoomEffectBorderRadius = 0.0,
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
        ),
        assert(
          containerScaleMax >= 1.0 && containerScaleMax <= 1.6,
          'containerScaleMax must be in [1.0, 1.6]',
        ),
        assert(
          containerScaleZoomRange > 0.0,
          'containerScaleZoomRange must be > 0.0',
        ),
        assert(
          reverseZoomMinScale > 0.0 && reverseZoomMinScale <= 1.0,
          'reverseZoomMinScale must be in (0.0, 1.0]',
        ),
        assert(
          reverseZoomMaxShrink >= 0.0 && reverseZoomMaxShrink <= 0.4,
          'reverseZoomMaxShrink must be in [0.0, 0.4]',
        ),
        assert(
          reverseZoomEffectBorderRadius >= 0.0,
          'reverseZoomEffectBorderRadius must be >= 0.0',
        );

  final bool enabled;
  final double gestureZoomSmoothing;
  final double zoomPanSensitivity;
  final bool showPointerCursor;
  final MouseCursor idleCursor;
  final MouseCursor zoomedCursor;
  final MouseCursor zoomedDraggingCursor;
  final PointerZoomOptions pointer;
  final ZoomRuntimeOptions runtime;
  final bool enableDoubleTapZoom;
  final double doubleTapZoomScale;
  final Duration doubleTapZoomDuration;
  final Curve doubleTapZoomCurve;
  final bool enableContainerScaleOnZoom;
  final double containerScaleMax;
  final double containerScaleZoomRange;
  final bool enableReverseZoomVisualEffect;
  final double reverseZoomMinScale;
  final double reverseZoomMaxShrink;
  final double reverseZoomEffectBorderRadius;
}
