import 'package:flutter/material.dart';

import 'platform/demo_platform_profile.dart';
import 'sections/control_panel.dart';
import 'sections/demo_card.dart';
import 'sections/header_section.dart';
import 'sections/info_section.dart';
import 'state/demo_controller.dart';

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  final DemoController _controller = DemoController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final profile = DemoPlatformProfile.from(
              context,
              constraints.maxWidth,
            );
            final isWide = profile.isWideLayout;

            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      HeaderSection(profile: profile, isWide: isWide),
                      const SizedBox(height: 18),
                      _DemoScene(
                        controller: _controller,
                        profile: profile,
                        isWide: isWide,
                      ),
                      const SizedBox(height: 18),
                      InfoSection(profile: profile),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DemoScene extends StatelessWidget {
  const _DemoScene({
    required this.controller,
    required this.profile,
    required this.isWide,
  });

  final DemoController controller;
  final DemoPlatformProfile profile;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final card = ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return DemoCard(
          profile: profile,
          progress: controller.progress,
          zoomController: controller.zoomController,
          showLabels: controller.showLabels,
          labelBehavior: controller.labelBehavior,
          dragMode: controller.dragMode,
          enableDoubleTapZoom: controller.enableDoubleTapZoom,
          enableContainerScale: controller.enableContainerScale,
          containerScaleMax: controller.containerScaleMax,
          containerScaleZoomRange: controller.containerScaleZoomRange,
        );
      },
    );

    final panel = ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return ControlPanel(
          profile: profile,
          progress: controller.progress,
          onResetZoom: controller.resetZoom,
          onPrepareWebDemo: controller.prepareWebDemo,
          showLabels: controller.showLabels,
          onShowLabelsChanged: controller.setShowLabels,
          enableDoubleTapZoom: controller.enableDoubleTapZoom,
          onEnableDoubleTapZoomChanged: controller.setEnableDoubleTapZoom,
          enableContainerScale: controller.enableContainerScale,
          onEnableContainerScaleChanged: controller.setEnableContainerScale,
          containerScaleMax: controller.containerScaleMax,
          onContainerScaleMaxChanged: controller.setContainerScaleMax,
          containerScaleZoomRange: controller.containerScaleZoomRange,
          onContainerScaleZoomRangeChanged:
              controller.setContainerScaleZoomRange,
          containerScalePreset: controller.containerScalePreset,
          onContainerScalePresetChanged: controller.applyContainerScalePreset,
          dragMode: controller.dragMode,
          onDragModeChanged: controller.setDragMode,
          labelBehavior: controller.labelBehavior,
          onLabelBehaviorChanged: controller.setLabelBehavior,
        );
      },
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 7, child: card),
          const SizedBox(width: 16),
          Expanded(flex: 4, child: panel),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        card,
        const SizedBox(height: 16),
        panel,
      ],
    );
  }
}
