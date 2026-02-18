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
    required this.enableReverseZoomVisualEffect,
    required this.reverseZoomEffectBorderRadius,
    required this.overlayBuilder,
    required this.overlayStyle,
    required this.zoomController,
  });

  final Size fullSize;
  final _VisualGeometry visual;
  final double progress;
  final _SideContent sideContent;
  final bool enableZoom;
  final bool showLabels;
  final LabelBehavior labelBehavior;
  final bool enableReverseZoomVisualEffect;
  final double reverseZoomEffectBorderRadius;
  final Widget Function(Size size, Offset position)? overlayBuilder;
  final OverlayStyle overlayStyle;
  final ZoomController zoomController;

  @override
  Widget build(BuildContext context) {
    final dividerScreenX = progress * visual.width;
    final overlayPosition = Offset(dividerScreenX, visual.height / 2);
    final isAttachedLabels = labelBehavior == LabelBehavior.attachedToContent;
    final isStaticLabels = labelBehavior == LabelBehavior.staticOverlaySafe;

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
              final centerX = visual.width / 2;
              final dividerContentX =
                  ((dividerScreenX - centerX - zoomController.pan.dx) /
                              zoomController.effectiveZoom +
                          centerX)
                      .clamp(0.0, visual.width);
              return buildZoomableContent(dividerContentX);
            },
          )
        : buildZoomableContent(dividerScreenX);

    final overlay = overlayBuilder?.call(
          Size(visual.width, visual.height),
          overlayPosition,
        ) ??
        DefaultOverlay(
          width: visual.width,
          height: visual.height,
          position: overlayPosition,
          style: overlayStyle,
        );

    final shrinkStrength =
        (1.0 - visual.width / fullSize.width).clamp(0.0, 1.0);
    final shadowAlpha = enableReverseZoomVisualEffect
        ? (0.05 + shrinkStrength * 0.18).clamp(0.0, 0.3)
        : 0.0;
    final radius = reverseZoomEffectBorderRadius;

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        Center(
          child: SizedBox(
            width: visual.width,
            height: visual.height,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: shadowAlpha),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(radius),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        zoomableContent,
                        if (showLabels && isAttachedLabels)
                          Positioned.fill(
                            child: ClipRect(
                              clipper: _LeftRectClipper(dividerScreenX),
                              child: Align(
                                alignment: Alignment.topLeft,
                                child: RepaintBoundary(
                                  child: sideContent.leftLabel,
                                ),
                              ),
                            ),
                          ),
                        if (showLabels && isAttachedLabels)
                          Positioned.fill(
                            child: ClipRect(
                              clipper: _RightRectClipper(dividerScreenX),
                              child: Align(
                                alignment: Alignment.topRight,
                                child: RepaintBoundary(
                                  child: sideContent.rightLabel,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  RepaintBoundary(child: overlay),
                  if (showLabels && isStaticLabels)
                    Align(
                      alignment: Alignment.topLeft,
                      child: RepaintBoundary(
                        child: sideContent.leftLabel,
                      ),
                    ),
                  if (showLabels && isStaticLabels)
                    Align(
                      alignment: Alignment.topRight,
                      child: RepaintBoundary(
                        child: sideContent.rightLabel,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
