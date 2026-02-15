import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'content_order.dart';
import 'default_overlay.dart';
import 'labels.dart';
import 'overlay_style.dart';
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
    this.beforeLabel,
    this.afterLabel,
    this.beforeLabelBuilder,
    this.afterLabelBuilder,
    this.overlay,
    this.zoomController,
    this.fixedLabels = true,
  });

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

  /// Custom widget for the "before" label. If null, uses default [BeforeLabel].
  final Widget? beforeLabel;

  /// Custom widget for the "after" label. If null, uses default [AfterLabel].
  final Widget? afterLabel;

  /// Builder for the "before" label widget.
  final Widget Function(BuildContext context)? beforeLabelBuilder;

  /// Builder for the "after" label widget.
  final Widget Function(BuildContext context)? afterLabelBuilder;

  /// Custom overlay widget builder. If null, uses [DefaultOverlay].
  final Widget Function(Size size, Offset position)? overlay;

  /// Controller for programmatic zoom/pan control.
  final ZoomController? zoomController;

  /// Whether labels stay fixed on screen while content is zoomed/panned.
  final bool fixedLabels;

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

  void _updateProgress(double screenX, double width) {
    final newProgress = (screenX / width).clamp(0.0, 1.0);
    _progressNotifier.value = newProgress;
    widget.onProgressChanged?.call(newProgress);
  }

  bool _isOnDivider(Offset localPosition, double dividerScreenX) {
    final thumbSize = widget.overlayStyle.thumbSize;
    final dividerWidth = widget.overlayStyle.dividerWidth;
    final hitHalfWidth =
        math.max(thumbSize / 2, math.max(dividerWidth * 2, 12));
    final dx = (localPosition.dx - dividerScreenX).abs();
    return dx <= hitHalfWidth;
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
        leftLabel: widget.beforeLabel ??
            widget.beforeLabelBuilder?.call(context) ??
            BeforeLabel(contentOrder: widget.contentOrder),
        rightLabel: widget.afterLabel ??
            widget.afterLabelBuilder?.call(context) ??
            AfterLabel(contentOrder: widget.contentOrder),
      );
    }

    return (
      leftChild: widget.afterChild,
      rightChild: widget.beforeChild,
      leftLabel: widget.afterLabel ??
          widget.afterLabelBuilder?.call(context) ??
          AfterLabel(contentOrder: widget.contentOrder),
      rightLabel: widget.beforeLabel ??
          widget.beforeLabelBuilder?.call(context) ??
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
            final dividerScreenX = progress * size.width;
            final sideContent = _resolveSideContent(context);

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
                    if (!widget.fixedLabels)
                      Align(
                        alignment: Alignment.topLeft,
                        child: sideContent.leftLabel,
                      ),
                    if (!widget.fixedLabels)
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
                          _screenToContentX(dividerScreenX, size)
                              .clamp(0.0, size.width);
                      return buildZoomableContent(dividerContentX);
                    },
                  )
                : buildZoomableContent(dividerScreenX);

            final overlayPosition = Offset(dividerScreenX, size.height / 2);
            final overlay = widget.overlay?.call(size, overlayPosition) ??
                DefaultOverlay(
                  width: size.width,
                  height: size.height,
                  position: overlayPosition,
                  style: widget.overlayStyle,
                );

            return GestureDetector(
              onScaleStart: _onScaleStart,
              onScaleUpdate: (details) => _onScaleUpdate(details, size),
              onScaleEnd: _onScaleEnd,
              onDoubleTap: widget.enableZoom ? _onDoubleTap : null,
              child: ClipRect(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    zoomableContent,
                    if (widget.fixedLabels)
                      Align(
                        alignment: Alignment.topLeft,
                        child: sideContent.leftLabel,
                      ),
                    if (widget.fixedLabels)
                      Align(
                        alignment: Alignment.topRight,
                        child: sideContent.rightLabel,
                      ),
                    RepaintBoundary(child: overlay),
                  ],
                ),
              ),
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
        final dividerScreenX = _progressNotifier.value * size.width;

        if (_isOnDivider(details.localFocalPoint, dividerScreenX)) {
          _isDragging = true;
          widget.onProgressStart?.call(_progressNotifier.value);
        }
      }
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details, Size size) {
    if (_isDragging) {
      _updateProgress(details.localFocalPoint.dx, size.width);
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
    _lastFocalPoint = null;
    _lastScale = null;
    _lastPointerCount = 0;
  }

  void _onDoubleTap() {
    _zoomController.reset();
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
