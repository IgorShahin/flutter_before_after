part of '../before_after.dart';

class _GestureSessionState {
  bool isDragging = false;
  Offset? lastFocalPoint;
  double? lastScale;
  int lastPointerCount = 0;
  double lastTrackpadScale = 1.0;
  Offset? lastDoubleTapFocalPoint;

  void resetAfterScaleEnd() {
    lastFocalPoint = null;
    lastScale = null;
    lastPointerCount = 0;
  }
}
