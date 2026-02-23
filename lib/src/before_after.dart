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
import 'enums/slider_orientation.dart';
import 'options/before_after_interaction_options.dart';
import 'options/before_after_labels_options.dart';
import 'options/before_after_overlay_options.dart';
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
    this.autoViewportAspectRatioFromImage = false,
    this.contentOrder = ContentOrder.beforeAfter,
    this.overlayOptions = const BeforeAfterOverlayOptions(),
    this.labelsOptions = const BeforeAfterLabelsOptions(),
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

  /// When true and [viewportAspectRatio] is null, tries to derive the viewport
  /// aspect ratio from direct [Image] children.
  final bool autoViewportAspectRatioFromImage;

  /// The order in which before and after content is displayed.
  final ContentOrder contentOrder;

  /// Grouped overlay options.
  final BeforeAfterOverlayOptions overlayOptions;

  /// Grouped labels options.
  final BeforeAfterLabelsOptions labelsOptions;

  /// Controller for programmatic zoom/pan control.
  final ZoomController? zoomController;

  @override
  State<BeforeAfter> createState() => _BeforeAfterState();
}

class _BeforeAfterState extends State<BeforeAfter> {
  late final ValueNotifier<double> _progressNotifier;
  late final ValueNotifier<double> _containerVisualScaleTargetNotifier;
  late final ValueNotifier<bool> _isPrimaryPointerDownNotifier;
  late final ValueNotifier<bool> _isScaleGestureActiveNotifier;
  late Listenable _cursorListenable;

  late ZoomController _zoomController;
  bool _ownsZoomController = false;
  double? _autoViewportAspectRatio;
  ImageStream? _autoAspectImageStream;
  ImageStreamListener? _autoAspectImageStreamListener;
  ImageProvider<Object>? _autoAspectImageProvider;
  ImageConfiguration? _autoAspectImageConfiguration;

  final _gesture = _GestureSessionState();
  bool _hasScheduledProgressCallback = false;
  double? _pendingProgressCallback;
  bool _labelsCacheDirty = true;
  Widget? _cachedLeftLabel;
  Widget? _cachedRightLabel;
  Size? _visualGeometryCacheSize;
  double? _visualGeometryCacheScale;
  _VisualGeometry? _visualGeometryCache;

  @override
  void initState() {
    super.initState();
    _progressNotifier = ValueNotifier<double>(widget.progress ?? 0.5);
    _containerVisualScaleTargetNotifier = ValueNotifier<double>(1.0);
    _isPrimaryPointerDownNotifier = ValueNotifier<bool>(false);
    _isScaleGestureActiveNotifier = ValueNotifier<bool>(false);
    _initZoomController();
    _rebuildCursorListenable();
    _zoomController.addListener(_onZoomControllerChanged);
  }

  @override
  void didUpdateWidget(BeforeAfter oldWidget) {
    super.didUpdateWidget(oldWidget);
    _clearVisualGeometryCache();

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

    if (widget.viewportAspectRatio != oldWidget.viewportAspectRatio ||
        widget.autoViewportAspectRatioFromImage != oldWidget.autoViewportAspectRatioFromImage ||
        widget.beforeChild != oldWidget.beforeChild ||
        widget.afterChild != oldWidget.afterChild) {
      _resolveAutoViewportAspectRatio();
    }

    if (widget.labelsOptions != oldWidget.labelsOptions || widget.contentOrder != oldWidget.contentOrder) {
      _markLabelsCacheDirty();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _clearVisualGeometryCache();
    _markLabelsCacheDirty();
    _resolveAutoViewportAspectRatio();
  }

  @override
  void dispose() {
    _stopAutoAspectRatioListener();
    _progressNotifier.dispose();
    _containerVisualScaleTargetNotifier.dispose();
    _isPrimaryPointerDownNotifier.dispose();
    _isScaleGestureActiveNotifier.dispose();
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

  ImageProvider<Object>? _extractImageProvider(Widget child) {
    if (child is Image) return child.image;
    return null;
  }

  void _stopAutoAspectRatioListener() {
    final stream = _autoAspectImageStream;
    final listener = _autoAspectImageStreamListener;
    if (stream != null && listener != null) {
      stream.removeListener(listener);
    }
    _autoAspectImageStream = null;
    _autoAspectImageStreamListener = null;
    _autoAspectImageProvider = null;
    _autoAspectImageConfiguration = null;
  }

  void _setAutoViewportAspectRatio(double? value) {
    final current = _autoViewportAspectRatio;
    if (current == null && value == null) return;
    if (current != null && value != null && (current - value).abs() < 0.0001) {
      return;
    }
    if (!mounted) return;
    _clearVisualGeometryCache();
    setState(() {
      _autoViewportAspectRatio = value;
    });
  }

  void _clearVisualGeometryCache() {
    _visualGeometryCache = null;
    _visualGeometryCacheSize = null;
    _visualGeometryCacheScale = null;
  }

  void _markLabelsCacheDirty() {
    _labelsCacheDirty = true;
  }

  void _ensureCachedLabels(BuildContext context) {
    if (!_labelsCacheDirty && _cachedLeftLabel != null && _cachedRightLabel != null) {
      return;
    }

    final beforeLabel =
        widget.labelsOptions.beforeBuilder?.call(context) ?? BeforeLabel(contentOrder: widget.contentOrder);
    final afterLabel =
        widget.labelsOptions.afterBuilder?.call(context) ?? AfterLabel(contentOrder: widget.contentOrder);

    if (widget.contentOrder == ContentOrder.beforeAfter) {
      _cachedLeftLabel = beforeLabel;
      _cachedRightLabel = afterLabel;
    } else {
      _cachedLeftLabel = afterLabel;
      _cachedRightLabel = beforeLabel;
    }

    _labelsCacheDirty = false;
  }

  void _resolveAutoViewportAspectRatio() {
    if (!widget.autoViewportAspectRatioFromImage || widget.viewportAspectRatio != null) {
      _stopAutoAspectRatioListener();
      _setAutoViewportAspectRatio(null);
      return;
    }

    final provider = _extractImageProvider(widget.beforeChild) ?? _extractImageProvider(widget.afterChild);
    if (provider == null) {
      _stopAutoAspectRatioListener();
      _setAutoViewportAspectRatio(null);
      return;
    }

    final configuration = createLocalImageConfiguration(context);
    final providerUnchanged = _autoAspectImageProvider == provider;
    final configurationUnchanged = _autoAspectImageConfiguration == configuration;
    if (providerUnchanged &&
        configurationUnchanged &&
        _autoAspectImageStream != null &&
        _autoAspectImageStreamListener != null) {
      return;
    }

    _stopAutoAspectRatioListener();
    final stream = provider.resolve(configuration);
    final listener = ImageStreamListener((imageInfo, _) {
      final width = imageInfo.image.width;
      final height = imageInfo.image.height;
      if (width <= 0 || height <= 0) return;
      _setAutoViewportAspectRatio(width / height);
    });
    _autoAspectImageStream = stream;
    _autoAspectImageStreamListener = listener;
    _autoAspectImageProvider = provider;
    _autoAspectImageConfiguration = configuration;
    stream.addListener(listener);
  }

  void _rebuildCursorListenable() {
    _cursorListenable = Listenable.merge(
      [_zoomController, _isPrimaryPointerDownNotifier],
    );
  }

  double get _containerVisualScaleTarget => _containerVisualScaleTargetNotifier.value;

  bool get _isScaleGestureActive => _isScaleGestureActiveNotifier.value;

  void _setScaleGestureActive(bool value) {
    if (_isScaleGestureActiveNotifier.value != value) {
      _isScaleGestureActiveNotifier.value = value;
    }
  }

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

        Widget buildSceneWithScale({
          required double progress,
          required double visualScale,
        }) {
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
            reverseZoomEffectBorderRadius: _effectiveReverseZoomEffectBorderRadius,
            overlayBuilder: widget.overlayOptions.builder,
            overlayStyle: widget.overlayOptions.style,
            zoomController: _zoomController,
            orientation: _effectiveSliderOrientation,
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

        final rebuildListenable = Listenable.merge([
          _progressNotifier,
          _containerVisualScaleTargetNotifier,
          _isScaleGestureActiveNotifier,
        ]);

        return AnimatedBuilder(
          animation: rebuildListenable,
          builder: (context, _) {
            final progress = _progressNotifier.value;

            if (!_hasContainerVisualScaleEffect) {
              return buildSceneWithScale(progress: progress, visualScale: 1.0);
            }

            if (_effectiveEnableContainerScaleOnZoom) {
              return buildSceneWithScale(
                progress: progress,
                visualScale: _containerVisualScaleTarget,
              );
            }

            return TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: 1.0,
                end: _containerVisualScaleTarget,
              ),
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeInOutCubic,
              builder: (context, visualScale, _) {
                return buildSceneWithScale(
                  progress: progress,
                  visualScale: _isScaleGestureActive ? _containerVisualScaleTarget : visualScale,
                );
              },
            );
          },
        );
      },
    );
  }
}
