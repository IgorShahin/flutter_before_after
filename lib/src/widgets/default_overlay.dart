import 'package:flutter/material.dart';

import '../options/overlay_style.dart';

/// Default overlay widget that displays a divider line and draggable thumb.
class DefaultOverlay extends StatelessWidget {
  /// Creates a default overlay.
  const DefaultOverlay({
    super.key,
    required this.width,
    required this.height,
    required this.position,
    this.style = const OverlayStyle(),
  });

  /// Total width of the overlay area.
  final double width;

  /// Total height of the overlay area.
  final double height;

  /// Current position of the divider (x coordinate).
  final Offset position;

  /// Style configuration for the overlay.
  final OverlayStyle style;

  @override
  Widget build(BuildContext context) {
    final thumbY = style.verticalThumbMove
        ? position.dy
        : height * (style.thumbPositionPercent / 100.0);

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: position.dx - style.dividerWidth / 2,
            top: 0,
            bottom: 0,
            child: Container(
              width: style.dividerWidth,
              decoration: BoxDecoration(
                color: style.dividerColor,
              ),
            ),
          ),
          Positioned(
            left: position.dx - style.thumbSize / 2,
            top: thumbY - style.thumbSize / 2,
            child: Container(
              width: style.thumbSize,
              height: style.thumbSize,
              decoration: BoxDecoration(
                color: style.thumbBackgroundColor,
                shape: style.thumbShape,
                boxShadow: style.thumbElevation > 0
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: style.thumbElevation * 2,
                          offset: Offset(0, style.thumbElevation),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                style.thumbIcon,
                color: style.thumbIconColor,
                size: style.thumbSize * 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
