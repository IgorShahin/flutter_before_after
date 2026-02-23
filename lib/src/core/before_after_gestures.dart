part of '../before_after.dart';

extension _BeforeAfterGesturesX on _BeforeAfterState {
  static const double _containerScaleStartZoom = 1.0;
  static const double _containerScaleResponseFactor = 1.9;
  static const double _webPointerZoomBoost = 1.85;
  static const double _desktopPanToZoomDamping = 0.58;
  static const double _dragThreshold = 0.0005;
  static const double _zoomBoostClampSteps = 10.0;

  double _targetContainerGrowScaleFromZoom(double zoom) {
    if (zoom <= _containerScaleStartZoom) return 1.0;
    final progress = ((zoom - _containerScaleStartZoom) /
            (_effectiveContainerScaleZoomRange * _containerScaleResponseFactor))
        .clamp(0.0, 1.0);
    // Follow zoom continuously (no lag accumulation), while keeping
    // container response softer than zoom itself.
    final eased = Curves.easeOutCubic.transform(progress);
    return 1.0 + (_effectiveContainerScaleMax - 1.0) * eased;
  }

  void _updateContainerScaleFromZoom() {
    if (!_effectiveEnableContainerScaleOnZoom) return;
    final nextScale = _targetContainerGrowScaleFromZoom(
      _zoomController.effectiveZoom,
    );
    if ((_containerVisualScaleTarget - nextScale).abs() > 0.0005) {
      _setContainerVisualScaleTarget(nextScale);
    }
  }

  _VisualGeometry _visualGeometry(Size fullSize, double visualScale) {
    var fittedWidth = fullSize.width;
    var fittedHeight = fullSize.height;
    final aspectRatio = _effectiveViewportAspectRatio;
    if (aspectRatio != null && aspectRatio > 0.0) {
      final heightFromWidth = fullSize.width / aspectRatio;
      if (heightFromWidth <= fullSize.height) {
        fittedWidth = fullSize.width;
        fittedHeight = heightFromWidth;
      } else {
        fittedHeight = fullSize.height;
        fittedWidth = fullSize.height * aspectRatio;
      }
    }

    var width = fittedWidth;
    var height = fittedHeight;
    var containerScale = 1.0;

    if (_effectiveEnableContainerScaleOnZoom && visualScale > 1.0) {
      final maxScale = _effectiveContainerScaleMax;
      final progress = maxScale > 1.0
          ? ((visualScale - 1.0) / (maxScale - 1.0)).clamp(0.0, 1.0)
          : 1.0;
      final eased = Curves.easeInOutCubic.transform(progress);
      width = fittedWidth + (fullSize.width - fittedWidth) * eased;
      height = fittedHeight + (fullSize.height - fittedHeight) * eased;

      final isAtFullBounds = (width - fullSize.width).abs() < 0.5 &&
          (height - fullSize.height).abs() < 0.5;
      if (isAtFullBounds) {
        containerScale = visualScale;
      }
    } else if (!_effectiveEnableContainerScaleOnZoom) {
      width *= visualScale;
      height *= visualScale;
    }

    final offsetX = (fullSize.width - width) / 2;
    final offsetY = (fullSize.height - height) / 2;
    return _VisualGeometry(
      width: width,
      height: height,
      offsetX: offsetX,
      offsetY: offsetY,
      containerScale: containerScale,
    );
  }

  _VisualGeometry _currentVisualGeometry(Size fullSize) {
    final visualScale = _currentVisualScale();
    return _visualGeometry(fullSize, visualScale);
  }

  double _currentVisualScale() {
    if (!_hasContainerVisualScaleEffect) return 1.0;
    return _containerVisualScaleTarget.clamp(
      _minContainerVisualScale,
      _maxContainerVisualScale,
    );
  }

  Size _zoomViewportSize(_VisualGeometry visual, Size fallback) {
    if (visual.width <= 0 || visual.height <= 0) return fallback;
    return Size(visual.width, visual.height);
  }

  Offset _toZoomViewportFocal(Offset localPosition, _VisualGeometry visual) {
    final dx = (localPosition.dx - visual.offsetX).clamp(0.0, visual.width);
    final dy = (localPosition.dy - visual.offsetY).clamp(0.0, visual.height);
    return Offset(dx, dy);
  }

  void _updateProgress(Offset localPosition, Size fullSize) {
    final visual = _currentVisualGeometry(fullSize);
    final next = _effectiveSliderOrientation == SliderOrientation.horizontal
        ? ((localPosition.dx - visual.offsetX) / visual.width).clamp(0.0, 1.0)
        : ((localPosition.dy - visual.offsetY) / visual.height).clamp(0.0, 1.0);
    if ((_progressNotifier.value - next).abs() > _dragThreshold) {
      _progressNotifier.value = next;
      _queueProgressChangedCallback(next);
    }
  }

  bool _canStartSliderDrag(
    Offset localPosition,
    Size fullSize,
    double progress,
  ) {
    final visual = _currentVisualGeometry(fullSize);
    final isHorizontal =
        _effectiveSliderOrientation == SliderOrientation.horizontal;
    final dividerScreenX = visual.offsetX + progress * visual.width;
    final dividerScreenY = visual.offsetY + progress * visual.height;
    final style = widget.overlayOptions.style;
    final thumbCenter = isHorizontal
        ? Offset(
            dividerScreenX,
            style.verticalThumbMove
                ? visual.offsetY + visual.height / 2
                : visual.offsetY +
                    visual.height * (style.thumbPositionPercent / 100.0),
          )
        : Offset(
            style.verticalThumbMove
                ? visual.offsetX + visual.width / 2
                : visual.offsetX +
                    visual.width * (style.thumbPositionPercent / 100.0),
            dividerScreenY,
          );
    final zoom = _zoomController.effectiveZoom;

    switch (_effectiveSliderDragMode) {
      case SliderDragMode.thumbOnly:
        if (_isOnThumb(localPosition, thumbCenter)) {
          return true;
        }
        return _effectiveSliderHitZone.allowLineFallbackWhenThumbOnlyZoomed &&
            zoom > 1.001 &&
            _isOnOverlayLine(
              localPosition,
              dividerScreen: isHorizontal ? dividerScreenX : dividerScreenY,
              crossAxisStart: isHorizontal ? visual.offsetY : visual.offsetX,
              crossAxisExtent: isHorizontal ? visual.height : visual.width,
              isHorizontal: isHorizontal,
            );
      case SliderDragMode.fullOverlay:
        return _isOnOverlayLine(
          localPosition,
          dividerScreen: isHorizontal ? dividerScreenX : dividerScreenY,
          crossAxisStart: isHorizontal ? visual.offsetY : visual.offsetX,
          crossAxisExtent: isHorizontal ? visual.height : visual.width,
          isHorizontal: isHorizontal,
        );
    }
  }

  bool _isOnOverlayLine(
    Offset localPosition, {
    required double dividerScreen,
    required double crossAxisStart,
    required double crossAxisExtent,
    required bool isHorizontal,
  }) {
    final style = widget.overlayOptions.style;
    final thumbSize = style.thumbSize;
    final dividerWidth = style.dividerWidth;
    final zone = _effectiveSliderHitZone;
    final zoomBoost = _sliderZoomBoost(zone);
    final hitHalfWidth = math.max(
          thumbSize / 2,
          math.max(dividerWidth * 2, zone.minLineHalfWidth),
        ) +
        zoomBoost;
    final axisDistance = isHorizontal
        ? (localPosition.dx - dividerScreen).abs()
        : (localPosition.dy - dividerScreen).abs();
    final verticalPadding = zone.verticalPadding + zoomBoost * 0.5;
    final crossAxisValue = isHorizontal ? localPosition.dy : localPosition.dx;
    final withinCrossAxis = crossAxisValue >=
            crossAxisStart - verticalPadding &&
        crossAxisValue <= crossAxisStart + crossAxisExtent + verticalPadding;
    return axisDistance <= hitHalfWidth && withinCrossAxis;
  }

  bool _isOnThumb(
    Offset localPosition,
    Offset thumbCenter,
  ) {
    final style = widget.overlayOptions.style;
    final thumbSize = style.thumbSize;
    final zone = _effectiveSliderHitZone;
    final zoomBoost = _sliderZoomBoost(zone);
    final hitRadius = math.max(thumbSize / 2, zone.minThumbRadius) + zoomBoost;

    final dx = (localPosition.dx - thumbCenter.dx).abs();
    final dy = (localPosition.dy - thumbCenter.dy).abs();

    if (style.thumbShape == BoxShape.circle) {
      final squaredDistance = dx * dx + dy * dy;
      final squaredRadius = hitRadius * hitRadius;
      return squaredDistance <= squaredRadius;
    }
    return dx <= hitRadius && dy <= hitRadius;
  }

  double _sliderZoomBoost(SliderHitZone zone) {
    final zoomSteps = (_zoomController.effectiveZoom - 1.0).clamp(
      0.0,
      _zoomBoostClampSteps,
    );
    return (zoomSteps * zone.zoomBoostPerStep).clamp(0.0, zone.maxZoomBoost);
  }

  void _onScaleStart(ScaleStartDetails details) {
    _gesture.lastFocalPoint = details.localFocalPoint;
    _gesture.lastScale = 1.0;
    _gesture.lastPointerCount = details.pointerCount;

    if (_effectiveEnableProgressWithTouch && details.pointerCount == 1) {
      final fullSize = context.size;
      if (fullSize == null) return;
      if (_canStartSliderDrag(
          details.localFocalPoint, fullSize, _progressNotifier.value)) {
        _gesture.isDragging = true;
        widget.onProgressStart?.call(_progressNotifier.value);
      }
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details, Size fullSize) {
    if (_gesture.isDragging) {
      _updateProgress(details.localFocalPoint, fullSize);
      return;
    }

    if (_isZoomEnabled && details.pointerCount >= 2) {
      _handlePinchUpdate(details, fullSize);
      return;
    }

    if (_isZoomEnabled &&
        _zoomController.zoom > 1.0 &&
        details.pointerCount == 1) {
      if (_isDesktopLike && !_isPrimaryPointerDownNotifier.value) {
        _gesture.lastPointerCount = details.pointerCount;
        return;
      }
      _handlePanUpdate(details, fullSize);
      return;
    }

    _gesture.lastPointerCount = details.pointerCount;
  }

  void _handlePinchUpdate(ScaleUpdateDetails details, Size fullSize) {
    if (_gesture.lastPointerCount != details.pointerCount) {
      _gesture.lastFocalPoint = details.localFocalPoint;
      _gesture.lastScale = details.scale;
      _gesture.lastPointerCount = details.pointerCount;
      return;
    }

    final rawPanDelta = details.localFocalPoint -
        (_gesture.lastFocalPoint ?? details.localFocalPoint);
    final panDelta = _isDesktopLike
        ? Offset.zero
        : rawPanDelta * _effectiveZoomPanSensitivity;
    final rawZoomDelta = details.scale / (_gesture.lastScale ?? 1.0);
    final smoothedZoomDelta =
        1.0 + (rawZoomDelta - 1.0) * _effectiveGestureZoomSmoothing;
    final zoomDelta =
        (smoothedZoomDelta - 1.0).abs() < 0.0015 ? 1.0 : smoothedZoomDelta;
    final visual = _currentVisualGeometry(fullSize);
    final zoomViewportSize = _zoomViewportSize(visual, fullSize);
    final focalPoint = _toZoomViewportFocal(details.localFocalPoint, visual);

    _zoomController.applyDesktopZoomPan(
      containerSize: zoomViewportSize,
      focalPoint: focalPoint,
      zoomScaleFactor: zoomDelta,
      panDelta: panDelta,
      allowOvershoot: true,
      smoothing: 1.0,
    );

    _updateContainerVisualScaleEffect(details.scale);
    _gesture.lastFocalPoint = details.localFocalPoint;
    _gesture.lastScale = details.scale;
  }

  void _handlePanUpdate(ScaleUpdateDetails details, Size fullSize) {
    if (_gesture.lastPointerCount != details.pointerCount) {
      _gesture.lastFocalPoint = details.localFocalPoint;
      _gesture.lastPointerCount = details.pointerCount;
      return;
    }

    final rawPanDelta = details.localFocalPoint -
        (_gesture.lastFocalPoint ?? details.localFocalPoint);
    final panDelta = rawPanDelta * _effectiveZoomPanSensitivity;
    final visual = _currentVisualGeometry(fullSize);
    final zoomViewportSize = _zoomViewportSize(visual, fullSize);
    _zoomController.updateFromGesture(
      containerSize: zoomViewportSize,
      panDelta: panDelta,
    );

    _gesture.lastFocalPoint = details.localFocalPoint;
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (_gesture.isDragging) {
      widget.onProgressEnd?.call(_progressNotifier.value);
      _gesture.isDragging = false;
    }
    _updateContainerVisualScaleEffect(1.0);
    if (_isZoomEnabled) {
      _zoomController.onGestureEnd();
    }
    _gesture.resetAfterScaleEnd();
  }

  void _onDoubleTapDown(TapDownDetails details) {
    _gesture.lastDoubleTapFocalPoint = details.localPosition;
  }

  void _onDoubleTap(Size fullSize) {
    final visual = _currentVisualGeometry(fullSize);
    final zoomViewportSize = _zoomViewportSize(visual, fullSize);
    final fallbackFocal = Offset(
        visual.offsetX + visual.width / 2, visual.offsetY + visual.height / 2);
    final rawFocalPoint = _gesture.lastDoubleTapFocalPoint ?? fallbackFocal;
    final focalPoint = _toZoomViewportFocal(rawFocalPoint, visual);
    _zoomController.toggleDoubleTapZoom(
      containerSize: zoomViewportSize,
      focalPoint: focalPoint,
      targetZoom: _effectiveDoubleTapZoomScale,
      duration: _effectiveDoubleTapZoomDuration,
      curve: _effectiveDoubleTapZoomCurve,
    );
  }

  void _onPointerSignal(PointerSignalEvent event, Size fullSize) {
    final pointerZoom = _effectivePointerZoom;
    if (!_isZoomEnabled || !pointerZoom.enabled) return;
    if (event is! PointerScrollEvent) return;

    if (pointerZoom.requiresModifier && !_isZoomModifierPressed()) {
      return;
    }

    GestureBinding.instance.pointerSignalResolver.register(
      event,
      (resolvedEvent) {
        final scrollEvent = resolvedEvent as PointerScrollEvent;
        final isLikelyMouse = scrollEvent.kind == PointerDeviceKind.mouse ||
            scrollEvent.kind == PointerDeviceKind.unknown;
        final axisDelta =
            scrollEvent.scrollDelta.dy.abs() >= scrollEvent.scrollDelta.dx.abs()
                ? scrollEvent.scrollDelta.dy
                : scrollEvent.scrollDelta.dx;
        if (axisDelta == 0) return;

        final effectiveDelta = axisDelta.sign *
            math.max(
              axisDelta.abs(),
              isLikelyMouse ? pointerZoom.mouseMinStep : 1.0,
            );
        final sensitivity = isLikelyMouse
            ? pointerZoom.sensitivity * pointerZoom.mouseSensitivityMultiplier
            : pointerZoom.sensitivity;
        final normalizedSensitivity =
            kIsWeb ? sensitivity * _webPointerZoomBoost : sensitivity;

        final factor = math.exp(-effectiveDelta * normalizedSensitivity);
        final visual = _currentVisualGeometry(fullSize);
        final zoomViewportSize = _zoomViewportSize(visual, fullSize);
        final focalPoint =
            _toZoomViewportFocal(scrollEvent.localPosition, visual);
        _zoomController.applyDesktopZoomPan(
          containerSize: zoomViewportSize,
          focalPoint: focalPoint,
          zoomScaleFactor: factor,
          panDelta: Offset.zero,
          allowOvershoot: false,
          smoothing: pointerZoom.smoothing,
        );

        _updateContainerVisualScaleEffect(factor);
      },
    );
  }

  void _onPointerDown(PointerDownEvent event) {
    if (event.kind == PointerDeviceKind.mouse) {
      final isDown = event.buttons == kPrimaryButton ||
          (event.buttons & kPrimaryButton) != 0;
      if (_isPrimaryPointerDownNotifier.value != isDown) {
        _isPrimaryPointerDownNotifier.value = isDown;
      }
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (event.kind == PointerDeviceKind.mouse) {
      if (_isPrimaryPointerDownNotifier.value) {
        _isPrimaryPointerDownNotifier.value = false;
      }
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (event.kind == PointerDeviceKind.mouse) {
      if (_isPrimaryPointerDownNotifier.value) {
        _isPrimaryPointerDownNotifier.value = false;
      }
    }
  }

  void _onPointerPanZoomStart(PointerPanZoomStartEvent event) {
    _gesture.lastTrackpadScale = 1.0;
  }

  void _onPointerPanZoomUpdate(PointerPanZoomUpdateEvent event, Size fullSize) {
    final pointerZoom = _effectivePointerZoom;
    if (!_isZoomEnabled || !pointerZoom.enabled) return;

    var zoomDelta = event.scale / _gesture.lastTrackpadScale;
    _gesture.lastTrackpadScale = event.scale;
    const panDelta = Offset.zero;

    if ((zoomDelta - 1.0).abs() < 0.0001) {
      final axisDelta =
          event.localPanDelta.dy.abs() >= event.localPanDelta.dx.abs()
              ? event.localPanDelta.dy
              : event.localPanDelta.dx;
      final canConvertPanToZoom =
          !pointerZoom.requiresModifier || _isZoomModifierPressed();

      if (axisDelta != 0.0 && canConvertPanToZoom) {
        final effectiveDelta = axisDelta.sign *
            math.max(axisDelta.abs(), pointerZoom.panToZoomMinStep * 0.35);
        final sensitivity = pointerZoom.sensitivity *
            pointerZoom.panToZoomSensitivity *
            _desktopPanToZoomDamping;
        zoomDelta = math.exp(-effectiveDelta * sensitivity);
      }
    }

    if ((zoomDelta - 1.0).abs() <= 0.0001) return;
    final visual = _currentVisualGeometry(fullSize);
    final zoomViewportSize = _zoomViewportSize(visual, fullSize);
    final focalPoint = _toZoomViewportFocal(event.localPosition, visual);

    _zoomController.applyDesktopZoomPan(
      containerSize: zoomViewportSize,
      focalPoint: focalPoint,
      zoomScaleFactor: zoomDelta,
      panDelta: panDelta,
      allowOvershoot: true,
      smoothing: pointerZoom.smoothing,
    );

    _updateContainerVisualScaleEffect(event.scale);
  }

  void _onPointerPanZoomEnd(PointerPanZoomEndEvent event) {
    _gesture.lastTrackpadScale = 1.0;
    if (_isZoomEnabled) {
      _zoomController.onGestureEnd();
    }
  }

  bool _isZoomModifierPressed() {
    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      if (pressed.contains(LogicalKeyboardKey.meta)) return true;
      return pressed.contains(LogicalKeyboardKey.metaLeft) ||
          pressed.contains(LogicalKeyboardKey.metaRight);
    }
    if (pressed.contains(LogicalKeyboardKey.control)) return true;
    return pressed.contains(LogicalKeyboardKey.controlLeft) ||
        pressed.contains(LogicalKeyboardKey.controlRight);
  }

  bool get _isDesktopLike {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  void _updateContainerVisualScaleEffect(double gestureScale) {
    final enableReverse = _effectiveEnableReverseZoomVisualEffect;
    final enableGrow = _effectiveEnableContainerScaleOnZoom;
    if (!enableReverse && !enableGrow) return;

    // When grow-on-zoom is enabled, container scale is derived only from
    // effective zoom to avoid gesture-vs-zoom source conflicts (jank).
    if (enableGrow) return;

    var nextScale = 1.0;
    if (enableReverse && gestureScale < 1.0) {
      final effectStrength = Curves.easeOutCubic.transform(
        (1.0 - gestureScale).clamp(0.0, 1.0),
      );
      nextScale = (1.0 - effectStrength * _effectiveReverseZoomMaxShrink)
          .clamp(_effectiveReverseZoomMinScale, 1.0);
    }

    final smoothed = _containerVisualScaleTarget +
        (nextScale - _containerVisualScaleTarget) * 0.18;
    if ((_containerVisualScaleTarget - smoothed).abs() > 0.0015) {
      _setContainerVisualScaleTarget(smoothed);
    }
  }
}
