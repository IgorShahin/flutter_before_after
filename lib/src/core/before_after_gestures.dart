part of '../before_after.dart';

extension _BeforeAfterGesturesX on _BeforeAfterState {
  static const double _containerScaleStartZoom = 1.0;
  static const double _containerScaleResponseFactor = 1.9;
  static const double _containerScaleSmoothing = 0.16;
  static const double _webPointerZoomBoost = 1.85;
  static const double _desktopPanToZoomDamping = 0.58;

  double _targetContainerGrowScaleFromZoom(double zoom) {
    if (zoom <= _containerScaleStartZoom) return 1.0;
    final progress = ((zoom - _containerScaleStartZoom) /
            (_effectiveContainerScaleZoomRange * _containerScaleResponseFactor))
        .clamp(0.0, 1.0);
    // Keep response slower than zoom, but with immediate start from first delta.
    return 1.0 + (_effectiveContainerScaleMax - 1.0) * progress;
  }

  void _updateContainerScaleFromZoom() {
    if (!_effectiveEnableContainerScaleOnZoom) return;
    final nextScale = _targetContainerGrowScaleFromZoom(
      _zoomController.effectiveZoom,
    );

    // Start immediately with first zoom delta.
    if (_containerVisualScaleTarget <= 1.0005 && nextScale > 1.0005) {
      final immediate = 1.0 + (nextScale - 1.0) * 0.4;
      _setContainerVisualScaleTarget(immediate);
      return;
    }

    final smoothed = _containerVisualScaleTarget +
        (nextScale - _containerVisualScaleTarget) * _containerScaleSmoothing;
    if ((_containerVisualScaleTarget - smoothed).abs() > 0.0015) {
      _setContainerVisualScaleTarget(smoothed);
    } else if ((nextScale - 1.0).abs() < 0.0005 &&
        _containerVisualScaleTarget != 1.0) {
      _setContainerVisualScaleTarget(1.0);
    }
  }

  _VisualGeometry _visualGeometry(Size fullSize, double visualScale) {
    var fittedWidth = fullSize.width;
    var fittedHeight = fullSize.height;
    final aspectRatio = widget.viewportAspectRatio;
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
      width = lerpDouble(fittedWidth, fullSize.width, eased) ?? fittedWidth;
      height = lerpDouble(fittedHeight, fullSize.height, eased) ?? fittedHeight;

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

  void _updateProgress(double screenX, Size fullSize) {
    final visualScale = _hasContainerVisualScaleEffect
        ? _containerVisualScaleTarget.clamp(
            _minContainerVisualScale,
            _maxContainerVisualScale,
          )
        : 1.0;
    final visual = _visualGeometry(fullSize, visualScale);
    final next = ((screenX - visual.offsetX) / visual.width).clamp(0.0, 1.0);
    if ((_progressNotifier.value - next).abs() > 0.0005) {
      _progressNotifier.value = next;
      _queueProgressChangedCallback(next);
    }
  }

  bool _canStartSliderDrag(
    Offset localPosition,
    Size fullSize,
    double progress,
  ) {
    final visualScale = _hasContainerVisualScaleEffect
        ? _containerVisualScaleTarget.clamp(
            _minContainerVisualScale,
            _maxContainerVisualScale,
          )
        : 1.0;
    final visual = _visualGeometry(fullSize, visualScale);
    final dividerScreenX = visual.offsetX + progress * visual.width;
    final thumbCenterY = widget.overlayStyle.verticalThumbMove
        ? visual.offsetY + visual.height / 2
        : visual.offsetY +
            visual.height * (widget.overlayStyle.thumbPositionPercent / 100.0);
    final zoom = _zoomController.effectiveZoom;

    switch (_effectiveSliderDragMode) {
      case SliderDragMode.thumbOnly:
        if (_isOnThumb(localPosition, dividerScreenX, thumbCenterY)) {
          return true;
        }
        return _effectiveSliderHitZone.allowLineFallbackWhenThumbOnlyZoomed &&
            zoom > 1.001 &&
            _isOnOverlayLine(
              localPosition,
              dividerScreenX,
              visual.offsetY,
              visual.height,
            );
      case SliderDragMode.fullOverlay:
        return _isOnOverlayLine(
          localPosition,
          dividerScreenX,
          visual.offsetY,
          visual.height,
        );
    }
  }

  bool _isOnOverlayLine(
    Offset localPosition,
    double dividerScreenX,
    double offsetY,
    double visualHeight,
  ) {
    final thumbSize = widget.overlayStyle.thumbSize;
    final dividerWidth = widget.overlayStyle.dividerWidth;
    final zone = _effectiveSliderHitZone;
    const zoomBoost = 0.0;
    final hitHalfWidth = math.max(
          thumbSize / 2,
          math.max(dividerWidth * 2, zone.minLineHalfWidth),
        ) +
        zoomBoost;
    final dx = (localPosition.dx - dividerScreenX).abs();
    final verticalPadding = zone.verticalPadding + zoomBoost * 0.5;
    final withinVertical = localPosition.dy >= offsetY - verticalPadding &&
        localPosition.dy <= offsetY + visualHeight + verticalPadding;
    return dx <= hitHalfWidth && withinVertical;
  }

  bool _isOnThumb(
    Offset localPosition,
    double dividerScreenX,
    double thumbCenterY,
  ) {
    final thumbSize = widget.overlayStyle.thumbSize;
    final zone = _effectiveSliderHitZone;
    const zoomBoost = 0.0;
    final hitRadius = math.max(thumbSize / 2, zone.minThumbRadius) + zoomBoost;

    final dx = (localPosition.dx - dividerScreenX).abs();
    final dy = (localPosition.dy - thumbCenterY).abs();

    if (widget.overlayStyle.thumbShape == BoxShape.circle) {
      return math.sqrt(dx * dx + dy * dy) <= hitRadius;
    }
    return dx <= hitRadius && dy <= hitRadius;
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
      _updateProgress(details.localFocalPoint.dx, fullSize);
      return;
    }

    if (_isZoomEnabled && details.pointerCount >= 2) {
      _handlePinchUpdate(details, fullSize);
      return;
    }

    if (_isZoomEnabled &&
        _zoomController.zoom > 1.0 &&
        details.pointerCount == 1) {
      if (_isDesktopLike && !_gesture.isPrimaryPointerDown) {
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
    final panDelta = rawPanDelta * _effectiveZoomPanSensitivity;
    final rawZoomDelta = details.scale / (_gesture.lastScale ?? 1.0);
    final smoothedZoomDelta =
        1.0 + (rawZoomDelta - 1.0) * _effectiveGestureZoomSmoothing;
    final zoomDelta =
        (smoothedZoomDelta - 1.0).abs() < 0.0015 ? 1.0 : smoothedZoomDelta;

    _zoomController.applyDesktopZoomPan(
      containerSize: fullSize,
      focalPoint: details.localFocalPoint,
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
    _zoomController.updateFromGesture(
      containerSize: fullSize,
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
    final focalPoint = _gesture.lastDoubleTapFocalPoint ??
        Offset(fullSize.width / 2, fullSize.height / 2);
    _zoomController.toggleDoubleTapZoom(
      containerSize: fullSize,
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
        _zoomController.applyDesktopZoomPan(
          containerSize: fullSize,
          focalPoint: scrollEvent.localPosition,
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
      if (_gesture.isPrimaryPointerDown != isDown) {
        _gesture.isPrimaryPointerDown = isDown;
        _refreshPointerCursor();
      }
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (event.kind == PointerDeviceKind.mouse) {
      if (_gesture.isPrimaryPointerDown) {
        _gesture.isPrimaryPointerDown = false;
        _refreshPointerCursor();
      }
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (event.kind == PointerDeviceKind.mouse) {
      if (_gesture.isPrimaryPointerDown) {
        _gesture.isPrimaryPointerDown = false;
        _refreshPointerCursor();
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

    _zoomController.applyDesktopZoomPan(
      containerSize: fullSize,
      focalPoint: event.localPosition,
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
    final enableReverse = widget.enableReverseZoomVisualEffect;
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
      nextScale = (1.0 - effectStrength * widget.reverseZoomMaxShrink)
          .clamp(widget.reverseZoomMinScale, 1.0);
    }

    final smoothed = _containerVisualScaleTarget +
        (nextScale - _containerVisualScaleTarget) * 0.18;
    if ((_containerVisualScaleTarget - smoothed).abs() > 0.0015) {
      _setContainerVisualScaleTarget(smoothed);
    }
  }
}
