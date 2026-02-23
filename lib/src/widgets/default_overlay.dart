import 'package:flutter/material.dart';

import '../enums/slider_orientation.dart';
import '../options/overlay_style.dart';

/// Default overlay widget that displays a divider line and draggable thumb.
class DefaultOverlay extends StatelessWidget {
  /// Creates a default overlay.
  const DefaultOverlay({
    super.key,
    required this.width,
    required this.height,
    required this.position,
    this.orientation = SliderOrientation.horizontal,
    this.style = const OverlayStyle(),
  });

  /// Total width of the overlay area.
  final double width;

  /// Total height of the overlay area.
  final double height;

  /// Current position of the divider (x coordinate).
  final Offset position;

  /// Divider orientation.
  final SliderOrientation orientation;

  /// Style configuration for the overlay.
  final OverlayStyle style;

  @override
  Widget build(BuildContext context) {
    final isHorizontal = orientation == SliderOrientation.horizontal;
    final thumbY = isHorizontal
        ? (style.verticalThumbMove
            ? position.dy
            : height * (style.thumbPositionPercent / 100.0))
        : position.dy;
    final thumbX = isHorizontal
        ? position.dx
        : (style.verticalThumbMove
            ? position.dx
            : width * (style.thumbPositionPercent / 100.0));
    final icon = isHorizontal
        ? style.thumbIcon
        : (style.thumbIcon == Icons.swap_horiz
            ? Icons.swap_vert
            : style.thumbIcon);

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: isHorizontal ? position.dx - style.dividerWidth / 2 : 0,
            right: isHorizontal ? null : 0,
            top: isHorizontal ? 0 : position.dy - style.dividerWidth / 2,
            bottom: isHorizontal ? 0 : null,
            child: Container(
              width: isHorizontal ? style.dividerWidth : null,
              height: isHorizontal ? null : style.dividerWidth,
              decoration: BoxDecoration(
                color: style.dividerColor,
              ),
            ),
          ),
          Positioned(
            left: thumbX - style.thumbSize / 2,
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
                icon,
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
