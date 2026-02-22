import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'controllers/zoom_controller.dart';
import 'enums/content_order.dart';
import 'enums/label_behavior.dart';
import 'enums/slider_drag_mode.dart';
import 'options/before_after_interaction_options.dart';
import 'options/before_after_labels_options.dart';
import 'options/before_after_zoom_options.dart';
import 'options/overlay_style.dart';
import 'options/pointer_zoom_options.dart';
import 'options/slider_hit_zone.dart';
import 'widgets/default_overlay.dart';
import 'widgets/labels.dart';

part 'core/before_after_config.dart';

part 'core/before_after_gesture_state.dart';

part 'core/before_after_gestures.dart';

part 'core/before_after_labels.dart';

part 'core/before_after_models.dart';

part 'core/before_after_scene.dart';

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
    this.interactionOptions = const BeforeAfterInteractionOptions(),
    this.zoomOptions = const BeforeAfterZoomOptions(),
    this.viewportAspectRatio,
    this.contentOrder = ContentOrder.beforeAfter,
    this.overlayStyle = const OverlayStyle(),
    this.labelsOptions = const BeforeAfterLabelsOptions(),
    this.overlay,
    this.zoomController,
  }) : assert(
          viewportAspectRatio == null || viewportAspectRatio > 0.0,
          'viewportAspectRatio must be > 0.0',
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

  /// Grouped interaction options.
  final BeforeAfterInteractionOptions interactionOptions;

  /// Grouped zoom options.
  final BeforeAfterZoomOptions zoomOptions;

  /// Optional target aspect ratio for the visible scene (width / height).
  ///
  /// When set, content starts fitted inside available bounds using this ratio.
  /// With container-scale-on-zoom enabled, scene can smoothly grow toward
  /// full available size while zooming.
  final double? viewportAspectRatio;

  /// The order in which before and after content is displayed.
  final ContentOrder contentOrder;

  /// Style configuration for the overlay (divider and thumb).
  final OverlayStyle overlayStyle;

  /// Grouped labels options.
  final BeforeAfterLabelsOptions labelsOptions;

  /// Custom overlay widget builder. If null, uses [DefaultOverlay].
  final Widget Function(Size size, Offset position)? overlay;

  /// Controller for programmatic zoom/pan control.
  final ZoomController? zoomController;

  @override
  State<BeforeAfter> createState() => _BeforeAfterState();
}

class _BeforeAfterState extends State<BeforeAfter> {
  late final ValueNotifier<double> _progressNotifier;
  late final ValueNotifier<double> _containerVisualScaleTargetNotifier;
  late final ValueNotifier<bool> _isPrimaryPointerDownNotifier;
  late Listenable _cursorListenable;

  late ZoomController _zoomController;
  bool _ownsZoomController = false;

  final _gesture = _GestureSessionState();
  bool _hasScheduledProgressCallback = false;
  double? _pendingProgressCallback;

  @override
  void initState() {
    super.initState();
    _progressNotifier = ValueNotifier<double>(widget.progress ?? 0.5);
    _containerVisualScaleTargetNotifier = ValueNotifier<double>(1.0);
    _isPrimaryPointerDownNotifier = ValueNotifier<bool>(false);
    _initZoomController();
    _rebuildCursorListenable();
    _zoomController.addListener(_onZoomControllerChanged);
  }

  @override
  void didUpdateWidget(BeforeAfter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progress != null && widget.progress != _progressNotifier.value) {
      _progressNotifier.value = widget.progress!;
    }
    final zoomControllerChanged = widget.zoomController != oldWidget.zoomController;
    final runtimeChangedForInternalController = widget.zoomController == null &&
        oldWidget.zoomController == null &&
        widget.zoomOptions.runtime != oldWidget.zoomOptions.runtime;

    if (zoomControllerChanged || runtimeChangedForInternalController) {
      final prevZoom = _zoomController.zoom;
      final prevPan = _zoomController.pan;
      final prevRotation = _zoomController.rotation;

      _zoomController.removeListener(_onZoomControllerChanged);
      if (_ownsZoomController) {
        _zoomController.dispose();
      }
      if (widget.zoomController != null) {
        _zoomController = widget.zoomController!;
        _ownsZoomController = false;
      } else {
        _zoomController = widget.zoomOptions.runtime.createController(
          initialZoom: prevZoom,
          initialPan: prevPan,
          initialRotation: prevRotation,
        );
        _ownsZoomController = true;
      }
      _rebuildCursorListenable();
      _zoomController.addListener(_onZoomControllerChanged);
    }
  }

  @override
  void dispose() {
    _progressNotifier.dispose();
    _containerVisualScaleTargetNotifier.dispose();
    _isPrimaryPointerDownNotifier.dispose();
    _zoomController.removeListener(_onZoomControllerChanged);
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
      final runtime = widget.zoomOptions.runtime;
      _zoomController = runtime.createController();
      _ownsZoomController = true;
    }
  }

  void _rebuildCursorListenable() {
    _cursorListenable = Listenable.merge(
      [_zoomController, _isPrimaryPointerDownNotifier],
    );
  }

  double get _containerVisualScaleTarget => _containerVisualScaleTargetNotifier.value;

  void _setContainerVisualScaleTarget(double value) {
    final clamped = value.clamp(_minContainerVisualScale, _maxContainerVisualScale);
    if ((_containerVisualScaleTargetNotifier.value - clamped).abs() > 0.0005) {
      _containerVisualScaleTargetNotifier.value = clamped;
    }
  }

  void _queueProgressChangedCallback(double value) {
    _pendingProgressCallback = value;
    if (_hasScheduledProgressCallback) return;
    _hasScheduledProgressCallback = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _hasScheduledProgressCallback = false;
      final pending = _pendingProgressCallback;
      _pendingProgressCallback = null;
      if (pending == null || !mounted) return;
      widget.onProgressChanged?.call(pending);
    });
  }

  void _onZoomControllerChanged() {
    if (!mounted) return;
    _updateContainerScaleFromZoom();
  }

  @override
  Widget build(BuildContext context) {
    final sideContent = _resolveSideContent(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        var baseWidth = constraints.maxWidth;
        if (!baseWidth.isFinite || baseWidth <= 0) {
          baseWidth = constraints.minWidth;
        }
        if (!baseWidth.isFinite || baseWidth <= 0) {
          baseWidth = MediaQuery.sizeOf(context).width;
        }

        var baseHeight = constraints.maxHeight;
        if (!baseHeight.isFinite || baseHeight <= 0) {
          baseHeight = constraints.minHeight;
        }
        if (!baseHeight.isFinite || baseHeight <= 0) {
          baseHeight = baseWidth * 0.75;
        }

        final baseSize = Size(baseWidth, baseHeight);

        return ValueListenableBuilder<double>(
          valueListenable: _progressNotifier,
          builder: (context, progress, _) {
            Widget buildSceneWithScale(double visualScale) {
              final sceneSize = baseSize;
              final visual = _visualGeometry(sceneSize, visualScale);

              final scene = _BeforeAfterScene(
                fullSize: sceneSize,
                visual: visual,
                progress: progress,
                sideContent: sideContent,
                enableZoom: _isZoomEnabled,
                showLabels: _effectiveShowLabels,
                labelBehavior: _effectiveLabelBehavior,
                reverseZoomEffectBorderRadius:
                    _effectiveReverseZoomEffectBorderRadius,
                overlayBuilder: widget.overlay,
                overlayStyle: widget.overlayStyle,
                zoomController: _zoomController,
              );

              final pointerLayer = Listener(
                onPointerDown: _onPointerDown,
                onPointerUp: _onPointerUp,
                onPointerCancel: _onPointerCancel,
                onPointerSignal: (event) => _onPointerSignal(event, sceneSize),
                onPointerPanZoomStart: _onPointerPanZoomStart,
                onPointerPanZoomUpdate: (event) => _onPointerPanZoomUpdate(event, sceneSize),
                onPointerPanZoomEnd: _onPointerPanZoomEnd,
                child: scene,
              );

              final sceneWithCursor = _isDesktopLike && _effectiveShowPointerCursor
                  ? AnimatedBuilder(
                      animation: _cursorListenable,
                      child: pointerLayer,
                      builder: (context, child) {
                        final canPanZoomedContent = _isZoomEnabled && _zoomController.effectiveZoom > 1.001;
                        final cursor = canPanZoomedContent
                            ? (_isPrimaryPointerDownNotifier.value
                                ? _effectiveZoomedDraggingCursor
                                : _effectiveZoomedCursor)
                            : _effectiveIdleCursor;
                        return MouseRegion(
                          cursor: cursor,
                          child: child!,
                        );
                      },
                    )
                  : pointerLayer;

              final gestureLayer = GestureDetector(
                onScaleStart: _onScaleStart,
                onScaleUpdate: (details) => _onScaleUpdate(details, sceneSize),
                onScaleEnd: _onScaleEnd,
                onDoubleTapDown: _isZoomEnabled && _isDoubleTapZoomEnabled ? _onDoubleTapDown : null,
                onDoubleTap: _isZoomEnabled && _isDoubleTapZoomEnabled ? () => _onDoubleTap(sceneSize) : null,
                child: sceneWithCursor,
              );

              return Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: sceneSize.width,
                  height: sceneSize.height,
                  child: gestureLayer,
                ),
              );
            }

            if (_effectiveEnableContainerScaleOnZoom) {
              return ValueListenableBuilder<double>(
                valueListenable: _containerVisualScaleTargetNotifier,
                builder: (context, visualScale, _) {
                  return buildSceneWithScale(visualScale);
                },
              );
            }

            return ValueListenableBuilder<double>(
              valueListenable: _containerVisualScaleTargetNotifier,
              builder: (context, visualScaleTarget, _) {
                return TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: 1.0,
                    end: _hasContainerVisualScaleEffect ? visualScaleTarget : 1.0,
                  ),
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeInOutCubic,
                  builder: (context, visualScale, _) {
                    return buildSceneWithScale(visualScale);
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
