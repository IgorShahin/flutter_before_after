part of '../before_after.dart';

class _BeforeAfterScene extends StatelessWidget {
  const _BeforeAfterScene({
    required this.fullSize,
    required this.visual,
    required this.progress,
    required this.sideContent,
    required this.enableZoom,
    required this.showLabels,
    required this.labelBehavior,
    required this.reverseZoomEffectBorderRadius,
    required this.overlayBuilder,
    required this.overlayStyle,
    required this.zoomController,
    required this.orientation,
  });

  final Size fullSize;
  final _VisualGeometry visual;
  final double progress;
  final _SideContent sideContent;
  final bool enableZoom;
  final bool showLabels;
  final LabelBehavior labelBehavior;
  final double reverseZoomEffectBorderRadius;
  final Widget Function(Size size, Offset position)? overlayBuilder;
  final OverlayStyle overlayStyle;
  final ZoomController zoomController;
  final SliderOrientation orientation;

  @override
  Widget build(BuildContext context) {
    final isHorizontal = orientation == SliderOrientation.horizontal;
    final dividerScreenX = visual.offsetX + progress * visual.width;
    final dividerScreenY = visual.offsetY + progress * visual.height;
    final dividerLocalX =
        (dividerScreenX - visual.offsetX).clamp(0.0, visual.width);
    final dividerLocalY =
        (dividerScreenY - visual.offsetY).clamp(0.0, visual.height);
    final centerX = visual.width / 2;
    final centerY = visual.height / 2;
    final isAttachedLabels = labelBehavior == LabelBehavior.attachedToContent;
    final isStaticLabels = labelBehavior == LabelBehavior.staticOverlaySafe;

    Widget buildZoomableContent({
      required double dividerContentX,
      required double dividerContentY,
    }) {
      final contentClipper = isHorizontal
          ? _LeftRectClipper(dividerContentX)
          : _TopRectClipper(dividerContentY);
      Widget content = RepaintBoundary(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(child: sideContent.rightChild),
            Positioned.fill(
              child: ClipRect(
                clipper: contentClipper,
                child: sideContent.leftChild,
              ),
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
              final dividerContentX =
                  ((dividerLocalX - centerX - zoomController.pan.dx) /
                              zoomController.effectiveZoom +
                          centerX)
                      .clamp(0.0, visual.width);
              final dividerContentY =
                  ((dividerLocalY - centerY - zoomController.pan.dy) /
                              zoomController.effectiveZoom +
                          centerY)
                      .clamp(0.0, visual.height);
              return buildZoomableContent(
                dividerContentX: dividerContentX,
                dividerContentY: dividerContentY,
              );
            },
          )
        : buildZoomableContent(
            dividerContentX: dividerLocalX,
            dividerContentY: dividerLocalY,
          );

    final thumbPosition = isHorizontal
        ? Offset(dividerLocalX, visual.height / 2)
        : Offset(visual.width / 2, dividerLocalY);

    final overlay = overlayBuilder?.call(
          Size(visual.width, visual.height),
          thumbPosition,
        ) ??
        DefaultOverlay(
          width: visual.width,
          height: visual.height,
          position: thumbPosition,
          orientation: orientation,
          style: overlayStyle,
        );

    final radius = reverseZoomEffectBorderRadius;

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        Center(
          child: SizedBox(
            width: visual.width,
            height: visual.height,
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(radius),
                      child: zoomableContent,
                    ),
                    if (showLabels && isAttachedLabels)
                      Positioned.fill(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRect(
                              clipper: isHorizontal
                                  ? _LeftRectClipper(dividerLocalX)
                                  : _TopRectClipper(dividerLocalY),
                              child: Align(
                                alignment: Alignment.topLeft,
                                child: RepaintBoundary(
                                  child: sideContent.leftLabel,
                                ),
                              ),
                            ),
                            ClipRect(
                              clipper: isHorizontal
                                  ? _RightRectClipper(dividerLocalX)
                                  : _BottomRectClipper(dividerLocalY),
                              child: Align(
                                alignment: isHorizontal
                                    ? Alignment.topRight
                                    : Alignment.bottomRight,
                                child: RepaintBoundary(
                                  child: sideContent.rightLabel,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                RepaintBoundary(
                  child: overlay,
                ),
                if (showLabels && isStaticLabels)
                  Align(
                    alignment: Alignment.topLeft,
                    child: RepaintBoundary(
                      child: sideContent.leftLabel,
                    ),
                  ),
                if (showLabels && isStaticLabels)
                  Align(
                    alignment: isHorizontal
                        ? Alignment.topRight
                        : Alignment.bottomRight,
                    child: RepaintBoundary(
                      child: sideContent.rightLabel,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
