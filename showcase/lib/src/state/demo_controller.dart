import 'package:before_after_slider/before_after_slider.dart';
import 'package:flutter/foundation.dart';

enum ContainerScalePreset {
  subtle,
  balanced,
  aggressive,
}

class DemoController extends ChangeNotifier {
  final ZoomController zoomController = ZoomController();
  final ValueNotifier<double> progress = ValueNotifier<double>(0.5);

  bool _showLabels = true;
  bool _enableDoubleTapZoom = true;
  bool _enableContainerScale = true;
  double _containerScaleMax = 1.60;
  double _containerScaleZoomRange = 0.55;
  ContainerScalePreset _containerScalePreset = ContainerScalePreset.aggressive;
  SliderDragMode _dragMode = SliderDragMode.fullOverlay;
  LabelBehavior _labelBehavior = LabelBehavior.attachedToContent;
  SliderOrientation _sliderOrientation = SliderOrientation.horizontal;

  bool get showLabels => _showLabels;
  bool get enableDoubleTapZoom => _enableDoubleTapZoom;
  bool get enableContainerScale => _enableContainerScale;
  double get containerScaleMax => _containerScaleMax;
  double get containerScaleZoomRange => _containerScaleZoomRange;
  ContainerScalePreset get containerScalePreset => _containerScalePreset;
  SliderDragMode get dragMode => _dragMode;
  LabelBehavior get labelBehavior => _labelBehavior;
  SliderOrientation get sliderOrientation => _sliderOrientation;

  void setShowLabels(bool value) {
    if (_showLabels == value) return;
    _showLabels = value;
    notifyListeners();
  }

  void setEnableDoubleTapZoom(bool value) {
    if (_enableDoubleTapZoom == value) return;
    _enableDoubleTapZoom = value;
    notifyListeners();
  }

  void setEnableContainerScale(bool value) {
    if (_enableContainerScale == value) return;
    _enableContainerScale = value;
    notifyListeners();
  }

  void setContainerScaleMax(double value) {
    final next = value.clamp(1.0, 1.6);
    if ((_containerScaleMax - next).abs() < 0.001) return;
    _containerScaleMax = next;
    _containerScalePreset = ContainerScalePreset.balanced;
    notifyListeners();
  }

  void setContainerScaleZoomRange(double value) {
    final next = value.clamp(0.2, 2.0);
    if ((_containerScaleZoomRange - next).abs() < 0.001) return;
    _containerScaleZoomRange = next;
    _containerScalePreset = ContainerScalePreset.balanced;
    notifyListeners();
  }

  void applyContainerScalePreset(ContainerScalePreset preset) {
    if (_containerScalePreset == preset &&
        ((preset == ContainerScalePreset.subtle &&
                (_containerScaleMax - 1.15).abs() < 0.001 &&
                (_containerScaleZoomRange - 1.65).abs() < 0.001) ||
            (preset == ContainerScalePreset.balanced &&
                (_containerScaleMax - 1.35).abs() < 0.001 &&
                (_containerScaleZoomRange - 1.05).abs() < 0.001) ||
            (preset == ContainerScalePreset.aggressive &&
                (_containerScaleMax - 1.60).abs() < 0.001 &&
                (_containerScaleZoomRange - 0.55).abs() < 0.001))) {
      return;
    }

    _containerScalePreset = preset;
    if (preset == ContainerScalePreset.subtle) {
      _containerScaleMax = 1.15;
      _containerScaleZoomRange = 1.65;
    } else if (preset == ContainerScalePreset.balanced) {
      _containerScaleMax = 1.35;
      _containerScaleZoomRange = 1.05;
    } else {
      _containerScaleMax = 1.60;
      _containerScaleZoomRange = 0.55;
    }
    notifyListeners();
  }

  void setDragMode(SliderDragMode? value) {
    if (value == null || _dragMode == value) return;
    _dragMode = value;
    notifyListeners();
  }

  void setLabelBehavior(LabelBehavior? value) {
    if (value == null || _labelBehavior == value) return;
    _labelBehavior = value;
    notifyListeners();
  }

  void setSliderOrientation(SliderOrientation value) {
    if (_sliderOrientation == value) return;
    _sliderOrientation = value;
    notifyListeners();
  }

  void resetZoom() {
    zoomController.reset();
  }

  void prepareWebDemo() {
    progress.value = 0.5;
    _showLabels = true;
    _enableDoubleTapZoom = true;
    _enableContainerScale = true;
    _dragMode = SliderDragMode.fullOverlay;
    _labelBehavior = LabelBehavior.attachedToContent;
    _sliderOrientation = SliderOrientation.horizontal;
    applyContainerScalePreset(ContainerScalePreset.aggressive);
    zoomController.reset();
  }

  @override
  void dispose() {
    zoomController.dispose();
    progress.dispose();
    super.dispose();
  }
}
