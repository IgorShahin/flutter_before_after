part of '../before_after.dart';

extension _BeforeAfterConfigX on _BeforeAfterState {
  bool get _isDoubleTapZoomEnabled => widget.zoomOptions.enableDoubleTapZoom;

  bool get _isZoomEnabled => widget.zoomOptions.enabled;

  double get _effectiveGestureZoomSmoothing =>
      widget.zoomOptions.gestureZoomSmoothing;

  double get _effectiveZoomPanSensitivity =>
      widget.zoomOptions.zoomPanSensitivity;

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
      widget.enableReverseZoomVisualEffect ||
      _effectiveEnableContainerScaleOnZoom;

  double get _minContainerVisualScale =>
      widget.enableReverseZoomVisualEffect ? widget.reverseZoomMinScale : 1.0;

  double get _maxContainerVisualScale =>
      _effectiveEnableContainerScaleOnZoom ? _effectiveContainerScaleMax : 1.0;

  bool get _effectiveEnableProgressWithTouch =>
      widget.interactionOptions.enableProgressWithTouch;

  SliderDragMode get _effectiveSliderDragMode =>
      widget.interactionOptions.sliderDragMode;

  SliderHitZone get _effectiveSliderHitZone =>
      widget.interactionOptions.sliderHitZone;

  bool get _effectiveShowLabels => widget.labelsOptions.show;
}
