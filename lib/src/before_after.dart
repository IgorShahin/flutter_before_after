import 'dart:math' as math;

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
import 'options/desktop_zoom_options.dart';
import 'options/overlay_style.dart';
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
    this.interactionOptions,
    this.enableProgressWithTouch = true,
    this.zoomOptions,
    this.enableZoom = true,
    this.enableDoubleTapZoom,
    @Deprecated('Use enableDoubleTapZoom instead.')
    this.enableDoubleTapZoomToggle,
    this.doubleTapZoomScale = 3.0,
    this.doubleTapZoomDuration = const Duration(milliseconds: 420),
    this.doubleTapZoomCurve = Curves.easeInOutCubic,
    this.gestureZoomSmoothing = 1.0,
    this.zoomPanSensitivity = 1.0,
    this.contentOrder = ContentOrder.beforeAfter,
    this.overlayStyle = const OverlayStyle(),
    this.labelsOptions,
    this.beforeLabelBuilder,
    this.afterLabelBuilder,
    this.overlay,
    this.zoomController,
    this.sliderDragMode = SliderDragMode.fullOverlay,
    this.sliderHitZone = const SliderHitZone(),
    this.showLabels = true,
    this.labelBehavior,
    @Deprecated('Use labelBehavior instead.') this.fixedLabels = true,
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
        ),
        assert(
          doubleTapZoomScale >= 1.0,
          'doubleTapZoomScale must be >= 1.0',
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

  /// Grouped interaction options (optional).
  final BeforeAfterInteractionOptions? interactionOptions;

  /// Whether the user can change the progress by dragging.
  final bool enableProgressWithTouch;

  /// Grouped zoom options (optional).
  final BeforeAfterZoomOptions? zoomOptions;

  /// Whether pinch-to-zoom is enabled.
  final bool enableZoom;

  /// Enables zoom toggle behavior on double tap.
  final bool? enableDoubleTapZoom;

  /// Enables double-tap zoom toggle animation.
  @Deprecated('Use enableDoubleTapZoom instead.')
  final bool? enableDoubleTapZoomToggle;

  /// Target zoom used on double-tap from base zoom.
  final double doubleTapZoomScale;

  /// Animation duration for double-tap zoom toggle.
  final Duration doubleTapZoomDuration;

  /// Animation curve for double-tap zoom toggle.
  final Curve doubleTapZoomCurve;

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

  /// Grouped labels options (optional).
  final BeforeAfterLabelsOptions? labelsOptions;

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

  /// Hit/capture zone settings for slider interactions.
  final SliderHitZone sliderHitZone;

  /// Whether the "before/after" labels are shown.
  final bool showLabels;

  /// Defines how labels are rendered relative to the slider/content.
  ///
  /// If null, behavior is inferred from deprecated `fixedLabels`.
  final LabelBehavior? labelBehavior;

  /// Whether labels stay fixed on screen while content is zoomed/panned.
  @Deprecated('Use labelBehavior instead.')
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
  late final ValueNotifier<double> _containerVisualScaleTargetNotifier;

  late ZoomController _zoomController;
  bool _ownsZoomController = false;

  final _gesture = _GestureSessionState();
  bool _hasScheduledVisualScaleUpdate = false;
  double? _pendingVisualScaleTarget;
  bool _hasScheduledProgressCallback = false;
  double? _pendingProgressCallback;

  @override
  void initState() {
    super.initState();
    _progressNotifier = ValueNotifier<double>(widget.progress ?? 0.5);
    _containerVisualScaleTargetNotifier = ValueNotifier<double>(1.0);
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
    _containerVisualScaleTargetNotifier.dispose();
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

  double get _containerVisualScaleTarget =>
      _containerVisualScaleTargetNotifier.value;

  void _setContainerVisualScaleTarget(double value) {
    final clamped = value.clamp(0.0, 1.0);
    if ((_containerVisualScaleTargetNotifier.value - clamped).abs() > 0.0005) {
      _containerVisualScaleTargetNotifier.value = clamped;
    }
  }

  void _queueContainerVisualScaleTarget(double value) {
    _pendingVisualScaleTarget = value;
    if (_hasScheduledVisualScaleUpdate) return;
    _hasScheduledVisualScaleUpdate = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _hasScheduledVisualScaleUpdate = false;
      final pending = _pendingVisualScaleTarget;
      _pendingVisualScaleTarget = null;
      if (pending == null || !mounted) return;
      _setContainerVisualScaleTarget(pending);
    });
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

  @override
  Widget build(BuildContext context) {
    final sideContent = _resolveSideContent(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final fullSize = Size(constraints.maxWidth, constraints.maxHeight);

        return ValueListenableBuilder<double>(
          valueListenable: _progressNotifier,
          builder: (context, progress, _) {
            return ValueListenableBuilder<double>(
              valueListenable: _containerVisualScaleTargetNotifier,
              builder: (context, visualScaleTarget, _) {
                return TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: 1.0,
                    end: widget.enableReverseZoomVisualEffect
                        ? visualScaleTarget
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
                      enableZoom: _isZoomEnabled,
                      showLabels: _effectiveShowLabels,
                      labelBehavior: _effectiveLabelBehavior,
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
                      onScaleUpdate: (details) =>
                          _onScaleUpdate(details, fullSize),
                      onScaleEnd: _onScaleEnd,
                      onDoubleTapDown: _isZoomEnabled && _isDoubleTapZoomEnabled
                          ? _onDoubleTapDown
                          : null,
                      onDoubleTap: _isZoomEnabled && _isDoubleTapZoomEnabled
                          ? () => _onDoubleTap(fullSize)
                          : null,
                      child: Listener(
                        onPointerDown: _onPointerDown,
                        onPointerUp: _onPointerUp,
                        onPointerCancel: _onPointerCancel,
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
      },
    );
  }
}
