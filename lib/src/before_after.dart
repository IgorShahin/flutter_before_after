import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'content_order.dart';
import 'desktop_zoom_options.dart';
import 'default_overlay.dart';
import 'labels.dart';
import 'overlay_style.dart';
import 'slider_drag_mode.dart';
import 'zoom_controller.dart';

/// A unified before/after comparison widget for arbitrary widgets.
class BeforeAfter extends StatefulWidget {
  /// Creates a before/after comparison widget.
  const BeforeAfter({
    super.key,
    required this.beforeChild,
    required this.afterChild,
    this.progress,
    this.onProgressChanged,
    this.onProgressStart,
    this.onProgressEnd,
    this.enableProgressWithTouch = true,
    this.enableZoom = true,
    this.gestureZoomSmoothing = 0.7,
    this.zoomPanSensitivity = 1.0,
    this.contentOrder = ContentOrder.beforeAfter,
    this.overlayStyle = const OverlayStyle(),
    this.beforeLabelBuilder,
    this.afterLabelBuilder,
    this.overlay,
    this.zoomController,
    this.sliderDragMode = SliderDragMode.fullOverlay,
    this.showLabels = true,
    this.fixedLabels = true,
    this.desktopZoom = const DesktopZoomOptions(),
    this.enableReverseZoomVisualEffect = false,
    this.reverseZoomMinScale = 0.92,
    this.reverseZoomMaxShrink = 0.18,
    this.reverseZoomEffectBorderRadius = 0.0,
  })  : assert(
          reverseZoomMinScale > 0 && reverseZoomMinScale <= 1.0,
          'reverseZoomMinScale must be in (0.0, 1.0]',
        ),
        assert(
          reverseZoomMaxShrink >= 0.0 && reverseZoomMaxShrink <= 0.4,
          'reverseZoomMaxShrink must be in [0.0, 0.4]',
        ),
        assert(
          reverseZoomEffectBorderRadius >= 0.0,
          'reverseZoomEffectBorderRadius must be >= 0.0',
        ),
        assert(
          zoomPanSensitivity > 0.0,
          'zoomPanSensitivity must be > 0.0',
        ),
        assert(
          gestureZoomSmoothing > 0.0 && gestureZoomSmoothing <= 1.0,
          'gestureZoomSmoothing must be in (0.0, 1.0]',
        );

  /// The "before" widget to display.
  final Widget beforeChild;

  /// The "after" widget to display.
  final Widget afterChild;

  /// The current progress of the divider (0.0 to 1.0).
  /// If null, the widget manages its own state starting at 0.5.
  final double? progress;

  /// Called when the progress changes during dragging.
  final ValueChanged<double>? onProgressChanged;

  /// Called when the user starts dragging the divider.
  final ValueChanged<double>? onProgressStart;

  /// Called when the user stops dragging the divider.
  final ValueChanged<double>? onProgressEnd;

  /// Whether the user can change the progress by dragging.
  final bool enableProgressWithTouch;

  /// Whether pinch-to-zoom is enabled.
  final bool enableZoom;

  /// Smoothing factor for pinch gesture zoom.
  ///
  /// Lower values feel softer, higher values react faster.
  final double gestureZoomSmoothing;

  /// Pan speed multiplier while zooming.
  ///
  /// `1.0` is default speed, `<1.0` slower, `>1.0` faster.
  final double zoomPanSensitivity;

  /// The order in which before and after content is displayed.
  final ContentOrder contentOrder;

  /// Style configuration for the overlay (divider and thumb).
  final OverlayStyle overlayStyle;

  /// Builder for the "before" label widget.
  final Widget Function(BuildContext context)? beforeLabelBuilder;

  /// Builder for the "after" label widget.
  final Widget Function(BuildContext context)? afterLabelBuilder;

  /// Custom overlay widget builder. If null, uses [DefaultOverlay].
  final Widget Function(Size size, Offset position)? overlay;

  /// Controller for programmatic zoom/pan control.
  final ZoomController? zoomController;

  /// Defines which part of overlay can start slider dragging.
  final SliderDragMode sliderDragMode;

  /// Whether the "before/after" labels are shown.
  final bool showLabels;

  /// Whether labels stay fixed on screen while content is zoomed/panned.
  final bool fixedLabels;

  /// Grouped desktop zoom configuration.
  final DesktopZoomOptions desktopZoom;

  /// Adds a visual "container shrink" effect while zooming out.
  ///
  /// This only affects rendering feedback and does not change actual zoom math.
  final bool enableReverseZoomVisualEffect;

  /// Minimum visual scale used by [enableReverseZoomVisualEffect].
  final double reverseZoomMinScale;

  /// Maximum visual shrink amount used by [enableReverseZoomVisualEffect].
  final double reverseZoomMaxShrink;

  /// Corner radius for the visual reverse zoom container.
  final double reverseZoomEffectBorderRadius;

  @override
  State<BeforeAfter> createState() => _BeforeAfterState();
}

class _BeforeAfterState extends State<BeforeAfter> {
  late final ValueNotifier<double> _progressNotifier;

  late ZoomController _zoomController;
  bool _ownsZoomController = false;

  bool _isDragging = false;
  Offset? _lastFocalPoint;
  double? _lastScale;
  int _lastPointerCount = 0;
  double _lastTrackpadScale = 1.0;

  double _containerVisualScaleTarget = 1.0;

  _ResolvedDesktopZoom get _desktopZoom => _ResolvedDesktopZoom(
        enabled: widget.desktopZoom.enabled,
        requiresModifier: widget.desktopZoom.requiresModifier,
        sensitivity: widget.desktopZoom.sensitivity,
        smoothing: widget.desktopZoom.smoothing,
        mouseSensitivityMultiplier:
            widget.desktopZoom.mouseSensitivityMultiplier,
        mouseMinStep: widget.desktopZoom.mouseMinStep,
        panToZoomSensitivity: widget.desktopZoom.panToZoomSensitivity,
        panToZoomMinStep: widget.desktopZoom.panToZoomMinStep,
      );

  @override
  void initState() {
    super.initState();
    _progressNotifier = ValueNotifier<double>(widget.progress ?? 0.5);
    _initZoomController();
  }

  @override
  void didUpdateWidget(BeforeAfter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progress != null && widget.progress != _progressNotifier.value) {
      _progressNotifier.value = widget.progress!;
    }
    if (widget.zoomController != oldWidget.zoomController) {
      if (_ownsZoomController) {
        _zoomController.dispose();
      }
      _initZoomController();
    }
  }

  @override
  void dispose() {
    _progressNotifier.dispose();
    if (_ownsZoomController) {
      _zoomController.dispose();
    }
    super.dispose();
  }

  void _initZoomController() {
    if (widget.zoomController != null) {
      _zoomController = widget.zoomController!;
      _ownsZoomController = false;
    } else {
      _zoomController = ZoomController();
      _ownsZoomController = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sideContent = _resolveSideContent(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final fullSize = Size(constraints.maxWidth, constraints.maxHeight);

        return ValueListenableBuilder<double>(
          valueListenable: _progressNotifier,
          builder: (context, progress, _) {
            return TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: 1.0,
                end: widget.enableReverseZoomVisualEffect
                    ? _containerVisualScaleTarget
                    : 1.0,
              ),
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              builder: (context, visualScale, _) {
                final visual = _visualGeometry(fullSize, visualScale);

                final scene = _BeforeAfterScene(
                  fullSize: fullSize,
                  visual: visual,
                  progress: progress,
                  sideContent: sideContent,
                  enableZoom: widget.enableZoom,
                  showLabels: widget.showLabels,
                  fixedLabels: widget.fixedLabels,
                  enableReverseZoomVisualEffect:
                      widget.enableReverseZoomVisualEffect,
                  reverseZoomEffectBorderRadius:
                      widget.reverseZoomEffectBorderRadius,
                  overlayBuilder: widget.overlay,
                  overlayStyle: widget.overlayStyle,
                  zoomController: _zoomController,
                );

                return GestureDetector(
                  onScaleStart: _onScaleStart,
                  onScaleUpdate: (details) => _onScaleUpdate(details, fullSize),
                  onScaleEnd: _onScaleEnd,
                  onDoubleTap: widget.enableZoom ? _onDoubleTap : null,
                  child: Listener(
                    onPointerSignal: (event) =>
                        _onPointerSignal(event, fullSize),
                    onPointerPanZoomStart: _onPointerPanZoomStart,
                    onPointerPanZoomUpdate: (event) =>
                        _onPointerPanZoomUpdate(event, fullSize),
                    onPointerPanZoomEnd: _onPointerPanZoomEnd,
                    child: scene,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  _SideContent _resolveSideContent(BuildContext context) {
    if (widget.contentOrder == ContentOrder.beforeAfter) {
      return _SideContent(
        leftChild: widget.beforeChild,
        rightChild: widget.afterChild,
        leftLabel: widget.beforeLabelBuilder?.call(context) ??
            BeforeLabel(contentOrder: widget.contentOrder),
        rightLabel: widget.afterLabelBuilder?.call(context) ??
            AfterLabel(contentOrder: widget.contentOrder),
      );
    }

    return _SideContent(
      leftChild: widget.afterChild,
      rightChild: widget.beforeChild,
      leftLabel: widget.afterLabelBuilder?.call(context) ??
          AfterLabel(contentOrder: widget.contentOrder),
      rightLabel: widget.beforeLabelBuilder?.call(context) ??
          BeforeLabel(contentOrder: widget.contentOrder),
    );
  }

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
    _progressNotifier.value = next;
    widget.onProgressChanged?.call(next);
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

    switch (widget.sliderDragMode) {
      case SliderDragMode.thumbOnly:
        return _isOnThumb(localPosition, dividerScreenX, thumbCenterY);
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
    final hitHalfWidth =
        math.max(thumbSize / 2, math.max(dividerWidth * 2, 12));
    final dx = (localPosition.dx - dividerScreenX).abs();
    final withinVertical = localPosition.dy >= offsetY &&
        localPosition.dy <= offsetY + visualHeight;
    return dx <= hitHalfWidth && withinVertical;
  }

  bool _isOnThumb(
    Offset localPosition,
    double dividerScreenX,
    double thumbCenterY,
  ) {
    final thumbSize = widget.overlayStyle.thumbSize;
    final hitRadius = math.max(thumbSize / 2, 24.0);

    final dx = (localPosition.dx - dividerScreenX).abs();
    final dy = (localPosition.dy - thumbCenterY).abs();

    if (widget.overlayStyle.thumbShape == BoxShape.circle) {
      return math.sqrt(dx * dx + dy * dy) <= hitRadius;
    }
    return dx <= hitRadius && dy <= hitRadius;
  }

  void _onScaleStart(ScaleStartDetails details) {
    _lastFocalPoint = details.localFocalPoint;
    _lastScale = 1.0;
    _lastPointerCount = details.pointerCount;

    if (widget.enableProgressWithTouch && details.pointerCount == 1) {
      final fullSize = context.size;
      if (fullSize == null) return;
      if (_canStartSliderDrag(
          details.localFocalPoint, fullSize, _progressNotifier.value)) {
        _isDragging = true;
        widget.onProgressStart?.call(_progressNotifier.value);
      }
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details, Size fullSize) {
    if (_isDragging) {
      _updateProgress(details.localFocalPoint.dx, fullSize);
      return;
    }

    if (widget.enableZoom && details.pointerCount >= 2) {
      _handlePinchUpdate(details, fullSize);
      return;
    }

    if (widget.enableZoom &&
        _zoomController.zoom > 1.0 &&
        details.pointerCount == 1) {
      _handlePanUpdate(details, fullSize);
      return;
    }

    _lastPointerCount = details.pointerCount;
  }

  void _handlePinchUpdate(ScaleUpdateDetails details, Size fullSize) {
    if (_lastPointerCount != details.pointerCount) {
      _lastFocalPoint = details.localFocalPoint;
      _lastScale = details.scale;
      _lastPointerCount = details.pointerCount;
      return;
    }

    final rawPanDelta =
        details.localFocalPoint - (_lastFocalPoint ?? details.localFocalPoint);
    final panDelta = rawPanDelta * widget.zoomPanSensitivity;
    final zoomDelta = details.scale / (_lastScale ?? 1.0);
    final smoothedZoomDelta =
        1.0 + (zoomDelta - 1.0) * widget.gestureZoomSmoothing;

    _zoomController.updateFromGesture(
      containerSize: fullSize,
      panDelta: panDelta,
      zoomDelta: smoothedZoomDelta,
    );

    _updateReverseZoomVisualScale(details.scale);
    _lastFocalPoint = details.localFocalPoint;
    _lastScale = details.scale;
  }

  void _handlePanUpdate(ScaleUpdateDetails details, Size fullSize) {
    if (_lastPointerCount != details.pointerCount) {
      _lastFocalPoint = details.localFocalPoint;
      _lastPointerCount = details.pointerCount;
      return;
    }

    final rawPanDelta =
        details.localFocalPoint - (_lastFocalPoint ?? details.localFocalPoint);
    final panDelta = rawPanDelta * widget.zoomPanSensitivity;
    _zoomController.updateFromGesture(
      containerSize: fullSize,
      panDelta: panDelta,
    );

    _lastFocalPoint = details.localFocalPoint;
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (_isDragging) {
      widget.onProgressEnd?.call(_progressNotifier.value);
      _isDragging = false;
    }
    if (_containerVisualScaleTarget != 1.0) {
      setState(() {
        _containerVisualScaleTarget = 1.0;
      });
    }
    if (widget.enableZoom) {
      _zoomController.onGestureEnd();
    }
    _lastFocalPoint = null;
    _lastScale = null;
    _lastPointerCount = 0;
  }

  void _onDoubleTap() {
    _zoomController.reset();
  }

  void _onPointerSignal(PointerSignalEvent event, Size fullSize) {
    if (!widget.enableZoom || !_desktopZoom.enabled) return;
    if (event is! PointerScrollEvent) return;

    final isLikelyMouse = event.kind == PointerDeviceKind.mouse ||
        event.kind == PointerDeviceKind.unknown;
    if (_desktopZoom.requiresModifier &&
        !_isZoomModifierPressed() &&
        !isLikelyMouse) {
      return;
    }

    final axisDelta = event.scrollDelta.dy.abs() >= event.scrollDelta.dx.abs()
        ? event.scrollDelta.dy
        : event.scrollDelta.dx;
    if (axisDelta == 0) return;

    final effectiveDelta = axisDelta.sign *
        math.max(
            axisDelta.abs(), isLikelyMouse ? _desktopZoom.mouseMinStep : 1.0);
    final sensitivity = isLikelyMouse
        ? _desktopZoom.sensitivity * _desktopZoom.mouseSensitivityMultiplier
        : _desktopZoom.sensitivity;

    final factor = math.exp(-effectiveDelta * sensitivity);
    _zoomController.applyDesktopZoomPan(
      containerSize: fullSize,
      focalPoint: event.localPosition,
      zoomScaleFactor: factor,
      panDelta: Offset.zero,
      allowOvershoot: false,
      smoothing: _desktopZoom.smoothing,
    );

    _updateReverseZoomVisualScale(factor);
  }

  void _onPointerPanZoomStart(PointerPanZoomStartEvent event) {
    _lastTrackpadScale = 1.0;
  }

  void _onPointerPanZoomUpdate(PointerPanZoomUpdateEvent event, Size fullSize) {
    if (!widget.enableZoom || !_desktopZoom.enabled) return;

    var zoomDelta = event.scale / _lastTrackpadScale;
    _lastTrackpadScale = event.scale;
    var panDelta = event.localPanDelta * widget.zoomPanSensitivity;

    if ((zoomDelta - 1.0).abs() < 0.0001) {
      if (_desktopZoom.requiresModifier && !_isZoomModifierPressed()) {
        return;
      }
      final axisDelta =
          event.localPanDelta.dy.abs() >= event.localPanDelta.dx.abs()
              ? event.localPanDelta.dy
              : event.localPanDelta.dx;
      if (axisDelta != 0.0) {
        final effectiveDelta = axisDelta.sign *
            math.max(axisDelta.abs(), _desktopZoom.panToZoomMinStep);
        final sensitivity =
            _desktopZoom.sensitivity * _desktopZoom.panToZoomSensitivity;
        zoomDelta = math.exp(-effectiveDelta * sensitivity);
        panDelta = Offset.zero;
      }
    }

    if ((zoomDelta - 1.0).abs() > 0.0001) {
      _zoomController.applyDesktopZoomPan(
        containerSize: fullSize,
        focalPoint: event.localPosition,
        zoomScaleFactor: zoomDelta,
        panDelta: panDelta,
        allowOvershoot: true,
        smoothing: _desktopZoom.smoothing,
      );
    } else {
      _zoomController.updateFromGesture(
        containerSize: fullSize,
        panDelta: panDelta,
      );
    }

    _updateReverseZoomVisualScale(event.scale);
  }

  void _onPointerPanZoomEnd(PointerPanZoomEndEvent event) {
    _lastTrackpadScale = 1.0;
    if (widget.enableZoom) {
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

  void _updateReverseZoomVisualScale(double gestureScale) {
    if (!widget.enableReverseZoomVisualEffect) return;

    if (_zoomController.zoom > 1.001) {
      if (_containerVisualScaleTarget != 1.0) {
        setState(() {
          _containerVisualScaleTarget = 1.0;
        });
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
      setState(() {
        _containerVisualScaleTarget = smoothed;
      });
    }
  }
}

class _BeforeAfterScene extends StatelessWidget {
  const _BeforeAfterScene({
    required this.fullSize,
    required this.visual,
    required this.progress,
    required this.sideContent,
    required this.enableZoom,
    required this.showLabels,
    required this.fixedLabels,
    required this.enableReverseZoomVisualEffect,
    required this.reverseZoomEffectBorderRadius,
    required this.overlayBuilder,
    required this.overlayStyle,
    required this.zoomController,
  });

  final Size fullSize;
  final _VisualGeometry visual;
  final double progress;
  final _SideContent sideContent;
  final bool enableZoom;
  final bool showLabels;
  final bool fixedLabels;
  final bool enableReverseZoomVisualEffect;
  final double reverseZoomEffectBorderRadius;
  final Widget Function(Size size, Offset position)? overlayBuilder;
  final OverlayStyle overlayStyle;
  final ZoomController zoomController;

  @override
  Widget build(BuildContext context) {
    final dividerScreenX = progress * visual.width;
    final overlayPosition = Offset(dividerScreenX, visual.height / 2);

    Widget buildZoomableContent(double dividerContentX) {
      Widget content = RepaintBoundary(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(child: sideContent.rightChild),
            Positioned.fill(
              child: ClipRect(
                clipper: _LeftRectClipper(dividerContentX),
                child: sideContent.leftChild,
              ),
            ),
            if (showLabels && !fixedLabels)
              Align(
                alignment: Alignment.topLeft,
                child: sideContent.leftLabel,
              ),
            if (showLabels && !fixedLabels)
              Align(
                alignment: Alignment.topRight,
                child: sideContent.rightLabel,
              ),
          ],
        ),
      );

      if (enableZoom) {
        content = Transform(
          transform: zoomController.transformationMatrix,
          alignment: Alignment.center,
          child: content,
        );
      }
      return content;
    }

    final zoomableContent = enableZoom
        ? AnimatedBuilder(
            animation: zoomController,
            builder: (context, _) {
              final centerX = visual.width / 2;
              final dividerContentX =
                  ((dividerScreenX - centerX - zoomController.pan.dx) /
                              zoomController.effectiveZoom +
                          centerX)
                      .clamp(0.0, visual.width);
              return buildZoomableContent(dividerContentX);
            },
          )
        : buildZoomableContent(dividerScreenX);

    final overlay = overlayBuilder?.call(
          Size(visual.width, visual.height),
          overlayPosition,
        ) ??
        DefaultOverlay(
          width: visual.width,
          height: visual.height,
          position: overlayPosition,
          style: overlayStyle,
        );

    final shrinkStrength =
        (1.0 - visual.width / fullSize.width).clamp(0.0, 1.0);
    final shadowAlpha = enableReverseZoomVisualEffect
        ? (0.05 + shrinkStrength * 0.18).clamp(0.0, 0.3)
        : 0.0;
    final radius = reverseZoomEffectBorderRadius;

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: SizedBox(
              width: visual.width,
              height: visual.height,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: shadowAlpha),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      zoomableContent,
                      if (showLabels && fixedLabels)
                        Align(
                          alignment: Alignment.topLeft,
                          child: sideContent.leftLabel,
                        ),
                      if (showLabels && fixedLabels)
                        Align(
                          alignment: Alignment.topRight,
                          child: sideContent.rightLabel,
                        ),
                      RepaintBoundary(child: overlay),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResolvedDesktopZoom {
  const _ResolvedDesktopZoom({
    required this.enabled,
    required this.requiresModifier,
    required this.sensitivity,
    required this.smoothing,
    required this.mouseSensitivityMultiplier,
    required this.mouseMinStep,
    required this.panToZoomSensitivity,
    required this.panToZoomMinStep,
  });

  final bool enabled;
  final bool requiresModifier;
  final double sensitivity;
  final double smoothing;
  final double mouseSensitivityMultiplier;
  final double mouseMinStep;
  final double panToZoomSensitivity;
  final double panToZoomMinStep;
}

class _VisualGeometry {
  const _VisualGeometry({
    required this.width,
    required this.height,
    required this.offsetX,
    required this.offsetY,
  });

  final double width;
  final double height;
  final double offsetX;
  final double offsetY;
}

class _SideContent {
  const _SideContent({
    required this.leftChild,
    required this.rightChild,
    required this.leftLabel,
    required this.rightLabel,
  });

  final Widget leftChild;
  final Widget rightChild;
  final Widget leftLabel;
  final Widget rightLabel;
}

class _LeftRectClipper extends CustomClipper<Rect> {
  _LeftRectClipper(this.dividerX);

  final double dividerX;

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, dividerX, size.height);
  }

  @override
  bool shouldReclip(_LeftRectClipper oldClipper) {
    return dividerX != oldClipper.dividerX;
  }
}
