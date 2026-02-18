import 'package:flutter/foundation.dart';

/// Desktop zoom behavior configuration.
@immutable
class DesktopZoomOptions {
  const DesktopZoomOptions({
    this.enabled = true,
    this.requiresModifier = true,
    this.sensitivity = 0.0018,
    this.smoothing = 0.55,
    this.mouseSensitivityMultiplier = 7.0,
    this.mouseMinStep = 10.0,
    this.panToZoomSensitivity = 5.0,
    this.panToZoomMinStep = 8.0,
  })  : assert(sensitivity > 0.0, 'sensitivity must be > 0.0'),
        assert(
            smoothing > 0.0 && smoothing <= 1.0, 'smoothing must be in (0, 1]'),
        assert(mouseSensitivityMultiplier > 0.0,
            'mouseSensitivityMultiplier must be > 0.0'),
        assert(mouseMinStep >= 0.0, 'mouseMinStep must be >= 0.0'),
        assert(
            panToZoomSensitivity > 0.0, 'panToZoomSensitivity must be > 0.0'),
        assert(panToZoomMinStep >= 0.0, 'panToZoomMinStep must be >= 0.0');

  final bool enabled;
  final bool requiresModifier;
  final double sensitivity;
  final double smoothing;
  final double mouseSensitivityMultiplier;
  final double mouseMinStep;
  final double panToZoomSensitivity;
  final double panToZoomMinStep;
}
