part of '../before_after.dart';

extension _BeforeAfterConfigX on _BeforeAfterState {
  double? get _effectiveViewportAspectRatio =>
      widget.viewportAspectRatio ?? _autoViewportAspectRatio;

  bool get _isDoubleTapZoomEnabled => widget.zoomOptions.enableDoubleTapZoom;

  bool get _isZoomEnabled => widget.zoomOptions.enabled;

  double get _effectiveGestureZoomSmoothing =>
      widget.zoomOptions.gestureZoomSmoothing;

  double get _effectiveZoomPanSensitivity =>
      widget.zoomOptions.zoomPanSensitivity;

  bool get _effectiveShowPointerCursor => widget.zoomOptions.showPointerCursor;

  MouseCursor get _effectiveIdleCursor => widget.zoomOptions.idleCursor;

  MouseCursor get _effectiveZoomedCursor => widget.zoomOptions.zoomedCursor;

  MouseCursor get _effectiveZoomedDraggingCursor =>
      widget.zoomOptions.zoomedDraggingCursor;

  PointerZoomOptions get _effectivePointerZoom => widget.zoomOptions.pointer;

  double get _effectiveDoubleTapZoomScale =>
      widget.zoomOptions.doubleTapZoomScale;

  Duration get _effectiveDoubleTapZoomDuration =>
      widget.zoomOptions.doubleTapZoomDuration;

  Curve get _effectiveDoubleTapZoomCurve =>
      widget.zoomOptions.doubleTapZoomCurve;

  bool get _effectiveEnableContainerScaleOnZoom =>
      widget.zoomOptions.enableContainerScaleOnZoom;

  double get _effectiveContainerScaleMax =>
      widget.zoomOptions.containerScaleMax;

  double get _effectiveContainerScaleZoomRange =>
      widget.zoomOptions.containerScaleZoomRange;

  bool get _hasContainerVisualScaleEffect =>
      _effectiveEnableReverseZoomVisualEffect ||
      _effectiveEnableContainerScaleOnZoom;

  bool get _effectiveEnableReverseZoomVisualEffect =>
      widget.zoomOptions.enableReverseZoomVisualEffect;

  double get _effectiveReverseZoomMinScale =>
      widget.zoomOptions.reverseZoomMinScale;

  double get _effectiveReverseZoomMaxShrink =>
      widget.zoomOptions.reverseZoomMaxShrink;

  double get _effectiveReverseZoomEffectBorderRadius =>
      widget.zoomOptions.reverseZoomEffectBorderRadius;

  double get _minContainerVisualScale => _effectiveEnableReverseZoomVisualEffect
      ? _effectiveReverseZoomMinScale
      : 1.0;

  double get _maxContainerVisualScale =>
      _effectiveEnableContainerScaleOnZoom ? _effectiveContainerScaleMax : 1.0;

  bool get _effectiveEnableProgressWithTouch =>
      widget.interactionOptions.enableProgressWithTouch;

  SliderDragMode get _effectiveSliderDragMode =>
      widget.interactionOptions.sliderDragMode;

  SliderOrientation get _effectiveSliderOrientation =>
      widget.interactionOptions.sliderOrientation;

  SliderHitZone get _effectiveSliderHitZone =>
      widget.interactionOptions.sliderHitZone;

  bool get _effectiveShowLabels => widget.labelsOptions.show;
}
