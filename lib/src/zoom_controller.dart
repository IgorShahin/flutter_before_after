import 'package:flutter/material.dart';

/// Controller for managing zoom, pan, and rotation state.
///
/// Use this controller to programmatically control the zoom state
/// of [BeforeAfterImage] or [BeforeAfterLayout] widgets.
class ZoomController extends ChangeNotifier {
  /// Creates a zoom controller with the given initial values.
  ZoomController({
    double initialZoom = 1.0,
    Offset initialPan = Offset.zero,
    double initialRotation = 0.0,
    this.minZoom = 1.0,
    this.maxZoom = 5.0,
    this.zoomEnabled = true,
    this.panEnabled = true,
    this.rotationEnabled = false,
    this.boundPan = true,
  })  : _zoom = initialZoom.clamp(minZoom, maxZoom),
        _pan = initialPan,
        _rotation = initialRotation;

  /// Minimum allowed zoom level.
  final double minZoom;

  /// Maximum allowed zoom level.
  final double maxZoom;

  /// Whether zoom gestures are enabled.
  final bool zoomEnabled;

  /// Whether pan gestures are enabled.
  final bool panEnabled;

  /// Whether rotation gestures are enabled.
  final bool rotationEnabled;

  /// Whether to bound pan within the container.
  final bool boundPan;

  double _zoom;
  Offset _pan;
  double _rotation;

  /// Current zoom level.
  double get zoom => _zoom;

  /// Current pan offset.
  Offset get pan => _pan;

  /// Current rotation in degrees.
  double get rotation => _rotation;

  /// Sets the zoom level, clamped to [minZoom] and [maxZoom].
  set zoom(double value) {
    final newZoom = value.clamp(minZoom, maxZoom);
    if (_zoom != newZoom) {
      _zoom = newZoom;
      notifyListeners();
    }
  }

  /// Sets the pan offset.
  set pan(Offset value) {
    if (_pan != value) {
      _pan = value;
      notifyListeners();
    }
  }

  /// Sets the rotation in degrees.
  set rotation(double value) {
    if (_rotation != value) {
      _rotation = value;
      notifyListeners();
    }
  }

  /// Updates the zoom state based on gesture changes.
  void updateFromGesture({
    required Size containerSize,
    Offset panDelta = Offset.zero,
    double zoomDelta = 1.0,
    double rotationDelta = 0.0,
  }) {
    // Update zoom
    if (zoomEnabled) {
      _zoom = (_zoom * zoomDelta).clamp(minZoom, maxZoom);
    }

    // Update rotation
    if (rotationEnabled) {
      _rotation += rotationDelta;
    }

    // Update pan
    if (panEnabled) {
      // panDelta is in screen coordinates, no need to multiply by zoom
      var newPan = _pan + panDelta;

      if (boundPan) {
        final maxX = (containerSize.width * (_zoom - 1) / 2).clamp(0.0, double.infinity);
        final maxY = (containerSize.height * (_zoom - 1) / 2).clamp(0.0, double.infinity);
        newPan = Offset(
          newPan.dx.clamp(-maxX, maxX),
          newPan.dy.clamp(-maxY, maxY),
        );
      }

      _pan = newPan;
    }

    notifyListeners();
  }

  /// Resets zoom, pan, and rotation to their initial values.
  void reset() {
    _zoom = 1.0;
    _pan = Offset.zero;
    _rotation = 0.0;
    notifyListeners();
  }

  /// Returns a [Matrix4] transformation matrix representing the current state.
  Matrix4 get transformationMatrix {
    final matrix = Matrix4.identity();
    matrix.setEntry(0, 3, _pan.dx);
    matrix.setEntry(1, 3, _pan.dy);
    matrix.setEntry(0, 0, _zoom);
    matrix.setEntry(1, 1, _zoom);
    if (_rotation != 0.0) {
      final radians = _rotation * 3.14159265359 / 180.0;
      matrix.rotateZ(radians);
    }
    return matrix;
  }
}

/// Data class holding zoom, pan, and rotation values.
@immutable
class ZoomData {
  /// Creates zoom data with the given values.
  const ZoomData({
    this.zoom = 1.0,
    this.pan = Offset.zero,
    this.rotation = 0.0,
  });

  /// The zoom level.
  final double zoom;

  /// The pan offset.
  final Offset pan;

  /// The rotation in degrees.
  final double rotation;

  /// Creates a copy with the given fields replaced.
  ZoomData copyWith({
    double? zoom,
    Offset? pan,
    double? rotation,
  }) {
    return ZoomData(
      zoom: zoom ?? this.zoom,
      pan: pan ?? this.pan,
      rotation: rotation ?? this.rotation,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ZoomData &&
        other.zoom == zoom &&
        other.pan == pan &&
        other.rotation == rotation;
  }

  @override
  int get hashCode => Object.hash(zoom, pan, rotation);
}