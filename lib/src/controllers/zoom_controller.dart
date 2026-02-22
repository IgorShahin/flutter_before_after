import 'dart:async';

import 'package:flutter/material.dart';

/// Controller for managing zoom, pan, and rotation state.
///
/// Use this controller to programmatically control the zoom state
/// of [BeforeAfter] widget.
class ZoomController extends ChangeNotifier {
  ZoomController({
    double initialZoom = 1.0,
    Offset initialPan = Offset.zero,
    double initialRotation = 0.0,
    this.minZoom = 1.0,
    this.maxZoom = 15.0,
    this.zoomEnabled = true,
    this.panEnabled = true,
    this.rotationEnabled = false,
    this.boundPan = true,
    this.enableZoomOvershoot = true,
    this.maxZoomOvershoot = 0.22,
    this.zoomOvershootResistance = 0.35,
    this.zoomOvershootReboundDuration = const Duration(milliseconds: 180),
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

  /// Whether pinch can overshoot max zoom and then rebound.
  final bool enableZoomOvershoot;

  /// Maximum visual zoom overshoot above [maxZoom].
  final double maxZoomOvershoot;

  /// Resistance for overshoot accumulation (0..1).
  final double zoomOvershootResistance;

  /// Duration of overshoot rebound animation.
  final Duration zoomOvershootReboundDuration;

  double _zoom;
  double _zoomOvershoot = 0.0;
  Offset _pan;
  double _rotation;
  Size? _lastContainerSize;
  Timer? _reboundTimer;
  Timer? _transitionTimer;

  /// Current zoom level.
  double get zoom => _zoom;

  /// Current visual zoom including temporary overshoot.
  double get effectiveZoom => _effectiveZoom;

  double get _effectiveZoom => (_zoom + _zoomOvershoot).clamp(minZoom, maxZoom + maxZoomOvershoot);

  /// Current pan offset.
  Offset get pan => _pan;

  /// Current rotation in degrees.
  double get rotation => _rotation;

  /// Sets the zoom level, clamped to [minZoom] and [maxZoom].
  set zoom(double value) {
    final newZoom = value.clamp(minZoom, maxZoom);
    if (_zoom != newZoom) {
      _zoom = newZoom;
      _zoomOvershoot = 0.0;
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
    final oldZoom = _zoom;
    final oldOvershoot = _zoomOvershoot;
    final oldPan = _pan;
    final oldRotation = _rotation;

    _lastContainerSize = containerSize;
    _cancelTransientAnimations();
    final previousEffectiveZoom = _effectiveZoom;

    if (zoomEnabled) {
      final candidateZoom = previousEffectiveZoom * zoomDelta;
      if (candidateZoom > maxZoom && enableZoomOvershoot) {
        _zoom = maxZoom;
        final overshoot = (candidateZoom - maxZoom) * zoomOvershootResistance;
        _zoomOvershoot = overshoot.clamp(0.0, maxZoomOvershoot);
      } else {
        _zoom = candidateZoom.clamp(minZoom, maxZoom);
        _zoomOvershoot = 0.0;
      }
    }

    if (rotationEnabled) {
      _rotation += rotationDelta;
    }

    if (panEnabled) {
      var basePan = _pan;

      if (boundPan) {
        final previousMaxX = (containerSize.width * (previousEffectiveZoom - 1) / 2).clamp(0.0, double.infinity);
        final previousMaxY = (containerSize.height * (previousEffectiveZoom - 1) / 2).clamp(0.0, double.infinity);
        final maxX = (containerSize.width * (_effectiveZoom - 1) / 2).clamp(
          0.0,
          double.infinity,
        );
        final maxY = (containerSize.height * (_effectiveZoom - 1) / 2).clamp(
          0.0,
          double.infinity,
        );

        // Smooth reverse zoom by scaling pan with shrinking bounds.
        if (maxX < previousMaxX && previousMaxX > 0) {
          basePan = Offset(basePan.dx * (maxX / previousMaxX), basePan.dy);
        }
        if (maxY < previousMaxY && previousMaxY > 0) {
          basePan = Offset(basePan.dx, basePan.dy * (maxY / previousMaxY));
        }

        var newPan = basePan + panDelta;
        newPan = Offset(
          newPan.dx.clamp(-maxX, maxX),
          newPan.dy.clamp(-maxY, maxY),
        );
        _pan = newPan;
      } else {
        _pan = basePan + panDelta;
      }
    }

    _clampPanToBounds();

    final changed = oldZoom != _zoom || oldOvershoot != _zoomOvershoot || oldPan != _pan || oldRotation != _rotation;
    if (changed) {
      notifyListeners();
    }
  }

  /// Applies zoom around a focal point in container coordinates.
  ///
  /// Keeps the content point under [focalPoint] stable while zooming.
  void zoomAroundFocalPoint({
    required Size containerSize,
    required Offset focalPoint,
    required double zoomScaleFactor,
    bool allowOvershoot = false,
    double smoothing = 1.0,
  }) {
    applyDesktopZoomPan(
      containerSize: containerSize,
      focalPoint: focalPoint,
      zoomScaleFactor: zoomScaleFactor,
      panDelta: Offset.zero,
      allowOvershoot: allowOvershoot,
      smoothing: smoothing,
    );
  }

  /// Applies focal-point zoom and optional pan in a single state update.
  ///
  /// This is optimized for desktop devices where scroll/trackpad input can
  /// include both pan and zoom in one event.
  void applyDesktopZoomPan({
    required Size containerSize,
    required Offset focalPoint,
    required double zoomScaleFactor,
    Offset panDelta = Offset.zero,
    bool allowOvershoot = false,
    double smoothing = 1.0,
  }) {
    final oldZoom = _zoom;
    final oldOvershoot = _zoomOvershoot;
    final oldPan = _pan;

    _lastContainerSize = containerSize;
    if (!zoomEnabled || zoomScaleFactor == 1.0 && panDelta == Offset.zero) {
      return;
    }
    if (smoothing <= 0.0 || smoothing > 1.0) return;

    _cancelTransientAnimations();
    final previousEffectiveZoom = _effectiveZoom;
    final rawDesiredZoom = previousEffectiveZoom * zoomScaleFactor;
    final desiredZoom = previousEffectiveZoom + (rawDesiredZoom - previousEffectiveZoom) * smoothing;

    if (allowOvershoot && enableZoomOvershoot && desiredZoom > maxZoom) {
      _zoom = maxZoom;
      final overshoot = (desiredZoom - maxZoom) * zoomOvershootResistance;
      _zoomOvershoot = overshoot.clamp(0.0, maxZoomOvershoot);
    } else {
      _zoom = desiredZoom.clamp(minZoom, maxZoom);
      _zoomOvershoot = 0.0;
    }

    final newEffectiveZoom = _effectiveZoom;
    final zoomChanged = newEffectiveZoom != previousEffectiveZoom;
    if (!zoomChanged && panDelta == Offset.zero) return;

    var nextPan = _pan;
    if (zoomChanged) {
      // Keep focal content point under cursor while zoom changes.
      final center = Offset(containerSize.width / 2, containerSize.height / 2);
      final worldPoint = (focalPoint - center - _pan) / previousEffectiveZoom;
      nextPan = focalPoint - center - worldPoint * newEffectiveZoom;
    }
    if (panEnabled && panDelta != Offset.zero) {
      nextPan += panDelta;
    }

    _pan = nextPan;
    _clampPanToBounds();

    final changed = oldZoom != _zoom || oldOvershoot != _zoomOvershoot || oldPan != _pan;
    if (changed) {
      notifyListeners();
    }
  }

  /// Resets zoom, pan, and rotation to their initial values.
  void reset() {
    _cancelTransientAnimations();
    _zoom = 1.0;
    _zoomOvershoot = 0.0;
    _pan = Offset.zero;
    _rotation = 0.0;
    notifyListeners();
  }

  /// Smoothly animates to target zoom/pan state.
  void animateTo({
    required Size containerSize,
    required double targetZoom,
    Offset? targetPan,
    Offset? focalPoint,
    Duration duration = const Duration(milliseconds: 420),
    Curve curve = Curves.easeInOutCubic,
  }) {
    if (!zoomEnabled) return;

    _lastContainerSize = containerSize;
    _cancelTransientAnimations();

    final startZoom = _effectiveZoom.clamp(minZoom, maxZoom);
    final endZoom = targetZoom.clamp(minZoom, maxZoom);
    final startPan = _pan;

    final resolvedTargetPan = targetPan ??
        (() {
          if (focalPoint == null) return _pan;
          final center = Offset(containerSize.width / 2, containerSize.height / 2);
          final worldPoint = (focalPoint - center - _pan) / startZoom;
          return focalPoint - center - worldPoint * endZoom;
        })();

    if (duration <= Duration.zero) {
      _zoom = endZoom;
      _zoomOvershoot = 0.0;
      _pan = resolvedTargetPan;
      _clampPanToBounds();
      notifyListeners();
      return;
    }

    const tickMs = 16;
    final totalTicks = (duration.inMilliseconds / tickMs).ceil().clamp(1, 240);
    var tick = 0;

    _transitionTimer = Timer.periodic(const Duration(milliseconds: tickMs), (
      timer,
    ) {
      final oldZoom = _zoom;
      final oldPan = _pan;
      final oldOvershoot = _zoomOvershoot;

      tick++;
      final t = (tick / totalTicks).clamp(0.0, 1.0);
      final eased = curve.transform(t);
      _zoom = startZoom + (endZoom - startZoom) * eased;
      _zoomOvershoot = 0.0;
      _pan = Offset.lerp(startPan, resolvedTargetPan, eased) ?? resolvedTargetPan;
      _clampPanToBounds();

      if (oldZoom != _zoom || oldPan != _pan || oldOvershoot != _zoomOvershoot) {
        notifyListeners();
      }

      if (t >= 1.0) {
        timer.cancel();
      }
    });
  }

  /// Double-tap style toggle:
  /// base zoom -> [targetZoom] around [focalPoint], zoomed -> base reset.
  void toggleDoubleTapZoom({
    required Size containerSize,
    required Offset focalPoint,
    double targetZoom = 3.0,
    Duration duration = const Duration(milliseconds: 420),
    Curve curve = Curves.easeInOutCubic,
    double baseThreshold = 0.02,
  }) {
    final atBase = (_effectiveZoom - minZoom).abs() <= baseThreshold;
    if (atBase) {
      animateTo(
        containerSize: containerSize,
        targetZoom: targetZoom,
        focalPoint: focalPoint,
        duration: duration,
        curve: curve,
      );
      return;
    }

    animateTo(
      containerSize: containerSize,
      targetZoom: minZoom,
      targetPan: Offset.zero,
      duration: duration,
      curve: curve,
    );
  }

  /// Call on gesture end to spring overshoot back to max zoom.
  void onGestureEnd() {
    if (_zoomOvershoot <= 0) return;
    _transitionTimer?.cancel();
    _reboundTimer?.cancel();

    final start = _zoomOvershoot;
    final totalMs = zoomOvershootReboundDuration.inMilliseconds;
    const tickMs = 16;
    final totalTicks = (totalMs / tickMs).ceil().clamp(1, 120);
    var tick = 0;

    _reboundTimer = Timer.periodic(const Duration(milliseconds: tickMs), (
      timer,
    ) {
      final oldOvershoot = _zoomOvershoot;
      final oldPan = _pan;

      tick++;
      final t = (tick / totalTicks).clamp(0.0, 1.0);
      final eased = Curves.easeOutCubic.transform(t);
      _zoomOvershoot = start * (1.0 - eased);
      _clampPanToBounds();
      if (oldOvershoot != _zoomOvershoot || oldPan != _pan) {
        notifyListeners();
      }
      if (t >= 1.0) {
        final prevOvershoot = _zoomOvershoot;
        final prevPan = _pan;
        _zoomOvershoot = 0.0;
        _clampPanToBounds();
        if (prevOvershoot != _zoomOvershoot || prevPan != _pan) {
          notifyListeners();
        }
        timer.cancel();
      }
    });
  }

  void _cancelTransientAnimations() {
    _transitionTimer?.cancel();
    _reboundTimer?.cancel();
  }

  void _clampPanToBounds() {
    if (!boundPan || !panEnabled) return;
    final size = _lastContainerSize;
    if (size == null) return;

    final maxX = (size.width * (_effectiveZoom - 1) / 2).clamp(0.0, double.infinity);
    final maxY = (size.height * (_effectiveZoom - 1) / 2).clamp(0.0, double.infinity);
    _pan = Offset(
      _pan.dx.clamp(-maxX, maxX),
      _pan.dy.clamp(-maxY, maxY),
    );
  }

  /// Returns a [Matrix4] transformation matrix representing the current state.
  Matrix4 get transformationMatrix {
    final matrix = Matrix4.identity();
    matrix.setEntry(0, 3, _pan.dx);
    matrix.setEntry(1, 3, _pan.dy);
    matrix.setEntry(0, 0, _effectiveZoom);
    matrix.setEntry(1, 1, _effectiveZoom);
    if (_rotation != 0.0) {
      final radians = _rotation * 3.14159265359 / 180.0;
      matrix.rotateZ(radians);
    }
    return matrix;
  }

  @override
  void dispose() {
    _cancelTransientAnimations();
    super.dispose();
  }
}
