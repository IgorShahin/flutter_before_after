import 'package:flutter/material.dart';

/// Style configuration for the overlay divider and thumb.
@immutable
class OverlayStyle {
  /// Creates an overlay style with the given parameters.
  const OverlayStyle({
    this.dividerColor = Colors.white,
    this.dividerWidth = 1.5,
    this.thumbBackgroundColor = Colors.white,
    this.thumbIconColor = Colors.grey,
    this.thumbSize = 36.0,
    this.thumbElevation = 2.0,
    this.thumbIcon = Icons.swap_horiz,
    this.thumbShape = BoxShape.circle,
    this.verticalThumbMove = false,
    this.thumbPositionPercent = 50.0,
  }) : assert(
          thumbPositionPercent >= 0.0 && thumbPositionPercent <= 100.0,
          'thumbPositionPercent must be between 0.0 and 100.0',
        );

  /// Color of the divider line.
  final Color dividerColor;

  /// Width of the divider line in logical pixels.
  final double dividerWidth;

  /// Background color of the thumb.
  final Color thumbBackgroundColor;

  /// Color of the thumb icon.
  final Color thumbIconColor;

  /// Size of the thumb in logical pixels.
  final double thumbSize;

  /// Elevation of the thumb shadow.
  final double thumbElevation;

  /// Icon displayed in the thumb.
  final IconData thumbIcon;

  /// Shape of the thumb (circle or rectangle).
  final BoxShape thumbShape;

  /// Whether the thumb can move vertically along the divider.
  final bool verticalThumbMove;

  /// Vertical position of the thumb as a percentage (0-100).
  /// Only used when [verticalThumbMove] is false.
  final double thumbPositionPercent;

  OverlayStyle copyWith({
    Color? dividerColor,
    double? dividerWidth,
    Color? thumbBackgroundColor,
    Color? thumbIconColor,
    double? thumbSize,
    double? thumbElevation,
    IconData? thumbIcon,
    BoxShape? thumbShape,
    bool? verticalThumbMove,
    double? thumbPositionPercent,
  }) {
    return OverlayStyle(
      dividerColor: dividerColor ?? this.dividerColor,
      dividerWidth: dividerWidth ?? this.dividerWidth,
      thumbBackgroundColor: thumbBackgroundColor ?? this.thumbBackgroundColor,
      thumbIconColor: thumbIconColor ?? this.thumbIconColor,
      thumbSize: thumbSize ?? this.thumbSize,
      thumbElevation: thumbElevation ?? this.thumbElevation,
      thumbIcon: thumbIcon ?? this.thumbIcon,
      thumbShape: thumbShape ?? this.thumbShape,
      verticalThumbMove: verticalThumbMove ?? this.verticalThumbMove,
      thumbPositionPercent: thumbPositionPercent ?? this.thumbPositionPercent,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OverlayStyle &&
        other.dividerColor == dividerColor &&
        other.dividerWidth == dividerWidth &&
        other.thumbBackgroundColor == thumbBackgroundColor &&
        other.thumbIconColor == thumbIconColor &&
        other.thumbSize == thumbSize &&
        other.thumbElevation == thumbElevation &&
        other.thumbIcon == thumbIcon &&
        other.thumbShape == thumbShape &&
        other.verticalThumbMove == verticalThumbMove &&
        other.thumbPositionPercent == thumbPositionPercent;
  }

  @override
  int get hashCode {
    return Object.hash(
      dividerColor,
      dividerWidth,
      thumbBackgroundColor,
      thumbIconColor,
      thumbSize,
      thumbElevation,
      thumbIcon,
      thumbShape,
      verticalThumbMove,
      thumbPositionPercent,
    );
  }
}
