part of '../before_after.dart';

extension _BeforeAfterGesturesX on _BeforeAfterState {
  _VisualGeometry _visualGeometry(Size fullSize, double visualScale) {
    final width = fullSize.width * visualScale;
    final height = fullSize.height * visualScale;
    final offsetX = (fullSize.width - width) / 2;
    final offsetY = (fullSize.height - height) / 2;
    return _VisualGeometry(
      width: width,
      height: height,
      offsetX: offsetX,
      offsetY: offsetY,
    );
  }

  void _updateProgress(double screenX, Size fullSize) {
    final visualScale = widget.enableReverseZoomVisualEffect
        ? _containerVisualScaleTarget.clamp(0.0, 1.0)
        : 1.0;
    final visual = _visualGeometry(fullSize, visualScale);
    final localX = screenX - visual.offsetX;
    final next = (localX / visual.width).clamp(0.0, 1.0);
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
    final visualScale = widget.enableReverseZoomVisualEffect
        ? _containerVisualScaleTarget.clamp(0.0, 1.0)
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
        if (_isOnThumb(localPosition, dividerScreenX, thumbCenterY, zoom)) {
          return true;
        }
        return _effectiveSliderHitZone.allowLineFallbackWhenThumbOnlyZoomed &&
            zoom > 1.001 &&
            _isOnOverlayLine(
              localPosition,
              dividerScreenX,
              visual.offsetY,
              visual.height,
              zoom,
            );
      case SliderDragMode.fullOverlay:
        return _isOnOverlayLine(
          localPosition,
          dividerScreenX,
          visual.offsetY,
          visual.height,
          zoom,
        );
    }
  }

  bool _isOnOverlayLine(
    Offset localPosition,
    double dividerScreenX,
    double offsetY,
    double visualHeight,
    double zoom,
  ) {
    final thumbSize = widget.overlayStyle.thumbSize;
    final dividerWidth = widget.overlayStyle.dividerWidth;
    final zone = _effectiveSliderHitZone;
    final zoomBoost =
        ((zoom - 1.0).clamp(0.0, double.infinity) * zone.zoomBoostPerStep)
            .clamp(0.0, zone.maxZoomBoost);
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
    double zoom,
  ) {
    final thumbSize = widget.overlayStyle.thumbSize;
    final zone = _effectiveSliderHitZone;
    final zoomBoost =
        ((zoom - 1.0).clamp(0.0, double.infinity) * zone.zoomBoostPerStep)
            .clamp(0.0, zone.maxZoomBoost);
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

    if (_effectiveEnableProgressWithTouch &&
        _effectiveSliderDragMode == SliderDragMode.fullOverlay &&
        details.pointerCount == 1 &&
        _zoomController.effectiveZoom > 1.001 &&
        _canStartSliderDrag(
          details.localFocalPoint,
          fullSize,
          _progressNotifier.value,
        )) {
      _gesture.isDragging = true;
      widget.onProgressStart?.call(_progressNotifier.value);
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
    final zoomDelta = details.scale / (_gesture.lastScale ?? 1.0);
    final smoothedZoomDelta =
        1.0 + (zoomDelta - 1.0) * _effectiveGestureZoomSmoothing;

    _zoomController.updateFromGesture(
      containerSize: fullSize,
      panDelta: panDelta,
      zoomDelta: smoothedZoomDelta,
    );

    _updateReverseZoomVisualScale(details.scale);
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
    if (_containerVisualScaleTarget != 1.0) {
      _setContainerVisualScaleTarget(1.0);
    }
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
    final desktopZoom = _effectiveDesktopZoom;
    if (!_isZoomEnabled || !desktopZoom.enabled) return;
    if (event is! PointerScrollEvent) return;

    if (desktopZoom.requiresModifier && !_isZoomModifierPressed()) {
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
              isLikelyMouse ? desktopZoom.mouseMinStep : 1.0,
            );
        final sensitivity = isLikelyMouse
            ? desktopZoom.sensitivity * desktopZoom.mouseSensitivityMultiplier
            : desktopZoom.sensitivity;

        final factor = math.exp(-effectiveDelta * sensitivity);
        _zoomController.applyDesktopZoomPan(
          containerSize: fullSize,
          focalPoint: scrollEvent.localPosition,
          zoomScaleFactor: factor,
          panDelta: Offset.zero,
          allowOvershoot: false,
          smoothing: desktopZoom.smoothing,
        );

        _updateReverseZoomVisualScale(factor);
      },
    );
  }

  void _onPointerDown(PointerDownEvent event) {
    if (event.kind == PointerDeviceKind.mouse) {
      _gesture.isPrimaryPointerDown = event.buttons == kPrimaryButton ||
          (event.buttons & kPrimaryButton) != 0;
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (event.kind == PointerDeviceKind.mouse) {
      _gesture.isPrimaryPointerDown = false;
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (event.kind == PointerDeviceKind.mouse) {
      _gesture.isPrimaryPointerDown = false;
    }
  }

  void _onPointerPanZoomStart(PointerPanZoomStartEvent event) {
    _gesture.lastTrackpadScale = 1.0;
  }

  void _onPointerPanZoomUpdate(PointerPanZoomUpdateEvent event, Size fullSize) {
    final desktopZoom = _effectiveDesktopZoom;
    if (!_isZoomEnabled || !desktopZoom.enabled) return;

    var zoomDelta = event.scale / _gesture.lastTrackpadScale;
    _gesture.lastTrackpadScale = event.scale;
    const panDelta = Offset.zero;

    if ((zoomDelta - 1.0).abs() < 0.0001) {
      final axisDelta =
          event.localPanDelta.dy.abs() >= event.localPanDelta.dx.abs()
              ? event.localPanDelta.dy
              : event.localPanDelta.dx;
      final canConvertPanToZoom = _zoomController.effectiveZoom <= 1.001 &&
          (!desktopZoom.requiresModifier || _isZoomModifierPressed());

      if (axisDelta != 0.0 && canConvertPanToZoom) {
        final effectiveDelta = axisDelta.sign *
            math.max(axisDelta.abs(), desktopZoom.panToZoomMinStep);
        final sensitivity =
            desktopZoom.sensitivity * desktopZoom.panToZoomSensitivity;
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
      smoothing: desktopZoom.smoothing,
    );

    _updateReverseZoomVisualScale(event.scale);
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
      return pressed.contains(LogicalKeyboardKey.metaLeft) ||
          pressed.contains(LogicalKeyboardKey.metaRight);
    }
    return pressed.contains(LogicalKeyboardKey.controlLeft) ||
        pressed.contains(LogicalKeyboardKey.controlRight);
  }

  bool get _isDesktopLike {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  void _updateReverseZoomVisualScale(double gestureScale) {
    if (!widget.enableReverseZoomVisualEffect) return;

    if (_zoomController.zoom > 1.001) {
      if (_containerVisualScaleTarget != 1.0) {
        _setContainerVisualScaleTarget(1.0);
      }
      return;
    }

    var nextScale = 1.0;
    if (gestureScale < 1.0) {
      final effectStrength = Curves.easeOutCubic.transform(
        (1.0 - gestureScale).clamp(0.0, 1.0),
      );
      nextScale = (1.0 - effectStrength * widget.reverseZoomMaxShrink)
          .clamp(widget.reverseZoomMinScale, 1.0);
    }

    final smoothed = _containerVisualScaleTarget +
        (nextScale - _containerVisualScaleTarget) * 0.28;
    if ((_containerVisualScaleTarget - smoothed).abs() > 0.004) {
      _queueContainerVisualScaleTarget(smoothed);
    }
  }
}
