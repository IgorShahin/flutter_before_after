import 'package:flutter/material.dart';

import 'overlay_style.dart';

typedef BeforeAfterOverlayBuilder = Widget Function(
  Size size,
  Offset position,
);

/// Grouped overlay configuration for [BeforeAfter].
@immutable
class BeforeAfterOverlayOptions {
  const BeforeAfterOverlayOptions({
    this.style = const OverlayStyle(),
    this.builder,
  });

  /// Style used by [DefaultOverlay] when [builder] is null.
  final OverlayStyle style;

  /// Custom overlay builder. When set, [style] is ignored.
  final BeforeAfterOverlayBuilder? builder;
}
