import 'package:flutter/foundation.dart';

import '../enums/slider_drag_mode.dart';
import '../enums/slider_orientation.dart';
import 'slider_hit_zone.dart';

/// Grouped slider interaction configuration for [BeforeAfter].
@immutable
class BeforeAfterInteractionOptions {
  const BeforeAfterInteractionOptions({
    this.enableProgressWithTouch = true,
    this.sliderDragMode = SliderDragMode.fullOverlay,
    this.sliderOrientation = SliderOrientation.horizontal,
    this.sliderHitZone = const SliderHitZone(),
  });

  final bool enableProgressWithTouch;
  final SliderDragMode sliderDragMode;
  final SliderOrientation sliderOrientation;
  final SliderHitZone sliderHitZone;
}
