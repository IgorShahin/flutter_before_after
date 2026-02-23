import 'package:before_after_slider/before_after_slider.dart';
import 'package:flutter/material.dart';

import '../platform/demo_platform_profile.dart';
import '../widgets/stat_pill.dart';

class DemoCard extends StatelessWidget {
  const DemoCard({
    super.key,
    required this.profile,
    required this.progress,
    required this.zoomController,
    required this.showLabels,
    required this.labelBehavior,
    required this.dragMode,
    required this.sliderOrientation,
    required this.enableDoubleTapZoom,
    required this.enableContainerScale,
    required this.containerScaleMax,
    required this.containerScaleZoomRange,
  });

  final DemoPlatformProfile profile;
  final ValueNotifier<double> progress;
  final ZoomController zoomController;
  final bool showLabels;
  final LabelBehavior labelBehavior;
  final SliderDragMode dragMode;
  final SliderOrientation sliderOrientation;
  final bool enableDoubleTapZoom;
  final bool enableContainerScale;
  final double containerScaleMax;
  final double containerScaleZoomRange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF9FBFF)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD8E4FA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140C254A),
            blurRadius: 26,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Interactive Preview',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (!profile.isMobile) const StatPill(text: 'Desktop + Mobile'),
              StatPill(text: enableContainerScale ? 'Scale: ON' : 'Scale: OFF'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            profile.interactionHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF4B5563),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: zoomController,
            builder: (context, _) {
              final info = _containerScaleInfo(
                zoom: zoomController.effectiveZoom,
                enabled: enableContainerScale,
                maxScale: containerScaleMax,
                zoomRange: containerScaleZoomRange,
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Live: zoom ${zoomController.effectiveZoom.toStringAsFixed(2)}x · '
                    'container ${info.scale.toStringAsFixed(2)}x · '
                    'expansion ${info.progressPercent.toStringAsFixed(0)}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF4B5563),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      value: info.progressPercent / 100,
                      backgroundColor: const Color(0xFFE6ECF8),
                      color: const Color(0xFF3169D9),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: profile.previewHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  border: Border.all(color: const Color(0xFF263850)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: ValueListenableBuilder<double>(
                  valueListenable: progress,
                  builder: (context, value, _) {
                    return BeforeAfter(
                      viewportAspectRatio: 3 / 4,
                      beforeChild: Image.asset(
                        'assets/before.jpeg',
                        fit: BoxFit.cover,
                      ),
                      afterChild: Image.asset(
                        'assets/after.jpeg',
                        fit: BoxFit.cover,
                      ),
                      progress: value,
                      onProgressChanged: (next) => progress.value = next,
                      labelsOptions: BeforeAfterLabelsOptions(
                        show: showLabels,
                        behavior: labelBehavior,
                        beforeBuilder: (_) => _label(
                          text: 'Before',
                          color: Colors.black.withValues(alpha: 0.78),
                        ),
                        afterBuilder: (_) => _label(
                          text: 'After',
                          color:
                              const Color(0xFF1E6FA8).withValues(alpha: 0.90),
                        ),
                      ),
                      interactionOptions: BeforeAfterInteractionOptions(
                        sliderOrientation: sliderOrientation,
                        sliderDragMode: dragMode,
                        sliderHitZone: const SliderHitZone(
                          minLineHalfWidth: 18,
                          minThumbRadius: 30,
                        ),
                      ),
                      zoomOptions: BeforeAfterZoomOptions(
                        zoomPanSensitivity: 0.95,
                        showPointerCursor: true,
                        enableDoubleTapZoom: enableDoubleTapZoom,
                        enableContainerScaleOnZoom: enableContainerScale,
                        containerScaleMax: containerScaleMax,
                        containerScaleZoomRange: containerScaleZoomRange,
                        reverseZoomEffectBorderRadius: 12,
                        pointer: const PointerZoomOptions(
                          requiresModifier: true,
                          smoothing: 0.4,
                        ),
                      ),
                      zoomController: zoomController,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _label({required String text, required Color color}) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static _ContainerScaleInfo _containerScaleInfo({
    required double zoom,
    required bool enabled,
    required double maxScale,
    required double zoomRange,
  }) {
    if (!enabled || zoom <= 1.0) {
      return const _ContainerScaleInfo(scale: 1.0, progressPercent: 0.0);
    }
    const responseFactor = 1.9;
    final progress = ((zoom - 1.0) / (zoomRange * responseFactor))
        .clamp(0.0, 1.0)
        .toDouble();
    final eased = Curves.easeOutCubic.transform(progress);
    final scale = 1.0 + (maxScale - 1.0) * eased;
    return _ContainerScaleInfo(
      scale: scale,
      progressPercent: progress * 100,
    );
  }
}

class _ContainerScaleInfo {
  const _ContainerScaleInfo({
    required this.scale,
    required this.progressPercent,
  });

  final double scale;
  final double progressPercent;
}
