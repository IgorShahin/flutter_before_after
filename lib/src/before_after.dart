import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'content_order.dart';
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
    this.contentOrder = ContentOrder.beforeAfter,
    this.overlayStyle = const OverlayStyle(),
    this.beforeLabelBuilder,
    this.afterLabelBuilder,
    this.overlay,
    this.zoomController,
    this.sliderDragMode = SliderDragMode.fullOverlay,
    this.showLabels = true,
    this.fixedLabels = true,
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
  late ValueNotifier<double> _progressNotifier;
  bool _isDragging = false;
  late ZoomController _zoomController;
  bool _ownsZoomController = false;

  Offset? _lastFocalPoint;
  double? _lastScale;
  int _lastPointerCount = 0;
  double _containerVisualScaleTarget = 1.0;

  @override
  void initState() {
    super.initState();
    _progressNotifier = ValueNotifier<double>(widget.progress ?? 0.5);
    _initZoomController();
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

  void _updateProgress(double screenX, Size size) {
    final geometry = _visualGeometry(size);
    final localX = screenX - geometry.offsetX;
    final newProgress = (localX / geometry.width).clamp(0.0, 1.0);
    _progressNotifier.value = newProgress;
    widget.onProgressChanged?.call(newProgress);
  }

  ({double width, double height, double offsetX, double offsetY})
      _visualGeometry(Size size) {
    final visualScale = widget.enableReverseZoomVisualEffect
        ? _containerVisualScaleTarget.clamp(0.0, 1.0)
        : 1.0;
    final width = size.width * visualScale;
    final height = size.height * visualScale;
    final offsetX = (size.width - width) / 2;
    final offsetY = (size.height - height) / 2;
    return (width: width, height: height, offsetX: offsetX, offsetY: offsetY);
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

  bool _canStartSliderDrag(
    Offset localPosition,
    Size size,
    double progress,
  ) {
    final geometry = _visualGeometry(size);
    final dividerScreenX = geometry.offsetX + progress * geometry.width;
    final thumbCenterY = widget.overlayStyle.verticalThumbMove
        ? geometry.offsetY + geometry.height / 2
        : geometry.offsetY +
            geometry.height *
                (widget.overlayStyle.thumbPositionPercent / 100.0);

    switch (widget.sliderDragMode) {
      case SliderDragMode.thumbOnly:
        return _isOnThumb(localPosition, dividerScreenX, thumbCenterY);
      case SliderDragMode.fullOverlay:
        return _isOnOverlayLine(
          localPosition,
          dividerScreenX,
          geometry.offsetY,
          geometry.height,
        );
    }
  }

  double _screenToContentX(double screenX, Size size) {
    if (!widget.enableZoom) return screenX;
    final centerX = size.width / 2;
    return ((screenX - centerX - _zoomController.pan.dx) /
            _zoomController.zoom) +
        centerX;
  }

  ({Widget leftChild, Widget rightChild, Widget leftLabel, Widget rightLabel})
      _resolveSideContent(BuildContext context) {
    if (widget.contentOrder == ContentOrder.beforeAfter) {
      return (
        leftChild: widget.beforeChild,
        rightChild: widget.afterChild,
        leftLabel: widget.beforeLabelBuilder?.call(context) ??
            BeforeLabel(contentOrder: widget.contentOrder),
        rightLabel: widget.afterLabelBuilder?.call(context) ??
            AfterLabel(contentOrder: widget.contentOrder),
      );
    }

    return (
      leftChild: widget.afterChild,
      rightChild: widget.beforeChild,
      leftLabel: widget.afterLabelBuilder?.call(context) ??
          AfterLabel(contentOrder: widget.contentOrder),
      rightLabel: widget.beforeLabelBuilder?.call(context) ??
          BeforeLabel(contentOrder: widget.contentOrder),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return ValueListenableBuilder<double>(
          valueListenable: _progressNotifier,
          builder: (context, progress, _) {
            final sideContent = _resolveSideContent(context);
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
                final visualSize = Size(
                  size.width * visualScale,
                  size.height * visualScale,
                );
                final dividerScreenX = progress * visualSize.width;

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
                        if (widget.showLabels && !widget.fixedLabels)
                          Align(
                            alignment: Alignment.topLeft,
                            child: sideContent.leftLabel,
                          ),
                        if (widget.showLabels && !widget.fixedLabels)
                          Align(
                            alignment: Alignment.topRight,
                            child: sideContent.rightLabel,
                          ),
                      ],
                    ),
                  );

                  if (widget.enableZoom) {
                    content = Transform(
                      transform: _zoomController.transformationMatrix,
                      alignment: Alignment.center,
                      child: content,
                    );
                  }

                  return content;
                }

                final zoomableContent = widget.enableZoom
                    ? AnimatedBuilder(
                        animation: _zoomController,
                        builder: (context, child) {
                          final dividerContentX =
                              _screenToContentX(dividerScreenX, visualSize)
                                  .clamp(0.0, visualSize.width);
                          return buildZoomableContent(dividerContentX);
                        },
                      )
                    : buildZoomableContent(dividerScreenX);

                final overlayPosition =
                    Offset(dividerScreenX, visualSize.height / 2);
                final overlay =
                    widget.overlay?.call(visualSize, overlayPosition) ??
                        DefaultOverlay(
                          width: visualSize.width,
                          height: visualSize.height,
                          position: overlayPosition,
                          style: widget.overlayStyle,
                        );

                final shrinkStrength = (1.0 - visualScale).clamp(0.0, 1.0);
                final shadowAlpha = widget.enableReverseZoomVisualEffect
                    ? (0.05 + shrinkStrength * 0.18).clamp(0.0, 0.3)
                    : 0.0;
                final radius = widget.reverseZoomEffectBorderRadius;

                return GestureDetector(
                  onScaleStart: _onScaleStart,
                  onScaleUpdate: (details) => _onScaleUpdate(details, size),
                  onScaleEnd: _onScaleEnd,
                  onDoubleTap: widget.enableZoom ? _onDoubleTap : null,
                  child: ClipRect(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Center(
                          child: SizedBox(
                            width: visualSize.width,
                            height: visualSize.height,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(radius),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: shadowAlpha),
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
                                    if (widget.showLabels && widget.fixedLabels)
                                      Align(
                                        alignment: Alignment.topLeft,
                                        child: sideContent.leftLabel,
                                      ),
                                    if (widget.showLabels && widget.fixedLabels)
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
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _onScaleStart(ScaleStartDetails details) {
    _lastFocalPoint = details.localFocalPoint;
    _lastScale = 1.0;
    _lastPointerCount = details.pointerCount;

    if (widget.enableProgressWithTouch && details.pointerCount == 1) {
      final size = context.size;
      if (size != null) {
        if (_canStartSliderDrag(
          details.localFocalPoint,
          size,
          _progressNotifier.value,
        )) {
          _isDragging = true;
          widget.onProgressStart?.call(_progressNotifier.value);
        }
      }
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details, Size size) {
    if (_isDragging) {
      _updateProgress(details.localFocalPoint.dx, size);
    } else if (widget.enableZoom && details.pointerCount >= 2) {
      if (_lastPointerCount != details.pointerCount) {
        _lastFocalPoint = details.localFocalPoint;
        _lastScale = details.scale;
        _lastPointerCount = details.pointerCount;
        return;
      }

      final panDelta = details.localFocalPoint -
          (_lastFocalPoint ?? details.localFocalPoint);
      final zoomDelta = details.scale / (_lastScale ?? 1.0);

      _zoomController.updateFromGesture(
        containerSize: size,
        panDelta: panDelta,
        zoomDelta: zoomDelta,
      );

      _updateReverseZoomVisualScale(details.scale);

      _lastFocalPoint = details.localFocalPoint;
      _lastScale = details.scale;
    } else if (widget.enableZoom &&
        _zoomController.zoom > 1.0 &&
        details.pointerCount == 1) {
      if (_lastPointerCount != details.pointerCount) {
        _lastFocalPoint = details.localFocalPoint;
        _lastPointerCount = details.pointerCount;
        return;
      }

      final panDelta = details.localFocalPoint -
          (_lastFocalPoint ?? details.localFocalPoint);
      _zoomController.updateFromGesture(
        containerSize: size,
        panDelta: panDelta,
      );

      _lastFocalPoint = details.localFocalPoint;
    } else {
      _lastPointerCount = details.pointerCount;
    }
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

  void _updateReverseZoomVisualScale(double gestureScale) {
    if (!widget.enableReverseZoomVisualEffect) return;

    // Reverse-zoom container effect is shown only near base zoom.
    if (_zoomController.zoom > 1.001) {
      if (_containerVisualScaleTarget != 1.0) {
        setState(() {
          _containerVisualScaleTarget = 1.0;
        });
      }
      return;
    }

    double nextScale = 1.0;
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
