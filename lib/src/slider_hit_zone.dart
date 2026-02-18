import 'package:flutter/foundation.dart';

/// Configuration for slider capture/hit zone behavior.
@immutable
class SliderHitZone {
  const SliderHitZone({
    this.minLineHalfWidth = 22.0,
    this.minThumbRadius = 34.0,
    this.zoomBoostPerStep = 10.0,
    this.maxZoomBoost = 32.0,
    this.verticalPadding = 20.0,
    this.allowLineFallbackWhenThumbOnlyZoomed = false,
  })  : assert(minLineHalfWidth >= 0.0, 'minLineHalfWidth must be >= 0'),
        assert(minThumbRadius >= 0.0, 'minThumbRadius must be >= 0'),
        assert(zoomBoostPerStep >= 0.0, 'zoomBoostPerStep must be >= 0'),
        assert(maxZoomBoost >= 0.0, 'maxZoomBoost must be >= 0'),
        assert(verticalPadding >= 0.0, 'verticalPadding must be >= 0');

  /// Minimum half-width for divider line hit zone.
  final double minLineHalfWidth;

  /// Minimum hit radius for thumb.
  final double minThumbRadius;

  /// Extra hit size added for each zoom step above 1x.
  final double zoomBoostPerStep;

  /// Maximum extra hit size added from zoom.
  final double maxZoomBoost;

  /// Extra vertical padding for line hit-testing.
  final double verticalPadding;

  /// In [SliderDragMode.thumbOnly], allows line hit fallback while zoomed.
  final bool allowLineFallbackWhenThumbOnlyZoomed;
}
