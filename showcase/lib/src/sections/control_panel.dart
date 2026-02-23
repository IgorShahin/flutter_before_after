import 'package:before_after_slider/before_after_slider.dart';
import 'package:flutter/material.dart';

import '../platform/demo_platform_profile.dart';
import '../state/demo_controller.dart';

class ControlPanel extends StatelessWidget {
  const ControlPanel({
    super.key,
    required this.profile,
    required this.progress,
    required this.onResetZoom,
    required this.showLabels,
    required this.onShowLabelsChanged,
    required this.enableDoubleTapZoom,
    required this.onEnableDoubleTapZoomChanged,
    required this.enableContainerScale,
    required this.onEnableContainerScaleChanged,
    required this.containerScalePreset,
    required this.onContainerScalePresetChanged,
    required this.dragMode,
    required this.onDragModeChanged,
    required this.sliderOrientation,
    required this.onSliderOrientationChanged,
    required this.labelBehavior,
    required this.onLabelBehaviorChanged,
  });

  final DemoPlatformProfile profile;
  final ValueNotifier<double> progress;
  final VoidCallback onResetZoom;
  final bool showLabels;
  final ValueChanged<bool> onShowLabelsChanged;
  final bool enableDoubleTapZoom;
  final ValueChanged<bool> onEnableDoubleTapZoomChanged;
  final bool enableContainerScale;
  final ValueChanged<bool> onEnableContainerScaleChanged;
  final ContainerScalePreset containerScalePreset;
  final ValueChanged<ContainerScalePreset> onContainerScalePresetChanged;
  final SliderDragMode dragMode;
  final ValueChanged<SliderDragMode?> onDragModeChanged;
  final SliderOrientation sliderOrientation;
  final ValueChanged<SliderOrientation> onSliderOrientationChanged;
  final LabelBehavior labelBehavior;
  final ValueChanged<LabelBehavior?> onLabelBehaviorChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF7FAFF)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD8E4FA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140A2A56),
            blurRadius: 26,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Playground',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tune only essentials: slider axis, drag behavior, labels, and zoom.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF5B6473),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          ValueListenableBuilder<double>(
            valueListenable: progress,
            builder: (context, value, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Progress ${(value * 100).round()}%',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Slider(
                    value: value,
                    onChanged: (next) => progress.value = next,
                  ),
                ],
              );
            },
          ),
          FilledButton.tonal(
            onPressed: onResetZoom,
            child: const Text('Reset zoom'),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Text(
            'Slider orientation',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<SliderOrientation>(
            segments: const [
              ButtonSegment<SliderOrientation>(
                value: SliderOrientation.horizontal,
                icon: Icon(Icons.swap_horiz),
                label: Text('Horizontal'),
              ),
              ButtonSegment<SliderOrientation>(
                value: SliderOrientation.vertical,
                icon: Icon(Icons.swap_vert),
                label: Text('Vertical'),
              ),
            ],
            selected: <SliderOrientation>{sliderOrientation},
            onSelectionChanged: (selection) =>
                onSliderOrientationChanged(selection.first),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<SliderDragMode>(
            initialValue: dragMode,
            decoration: const InputDecoration(
              labelText: 'Slider drag mode',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: SliderDragMode.fullOverlay,
                child: Text('fullOverlay'),
              ),
              DropdownMenuItem(
                value: SliderDragMode.thumbOnly,
                child: Text('thumbOnly'),
              ),
            ],
            onChanged: onDragModeChanged,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<LabelBehavior>(
            initialValue: labelBehavior,
            decoration: const InputDecoration(
              labelText: 'Label behavior',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: LabelBehavior.staticOverlaySafe,
                child: Text('staticOverlaySafe'),
              ),
              DropdownMenuItem(
                value: LabelBehavior.attachedToContent,
                child: Text('attachedToContent'),
              ),
            ],
            onChanged: onLabelBehaviorChanged,
          ),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Show labels'),
            value: showLabels,
            onChanged: onShowLabelsChanged,
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Enable double-tap zoom'),
            value: enableDoubleTapZoom,
            onChanged: onEnableDoubleTapZoomChanged,
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Container scale on zoom'),
            value: enableContainerScale,
            onChanged: onEnableContainerScaleChanged,
          ),
          if (enableContainerScale) ...[
            const SizedBox(height: 4),
            Text(
              'Container scale preset',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Subtle'),
                  selected: containerScalePreset == ContainerScalePreset.subtle,
                  onSelected: (_) => onContainerScalePresetChanged(
                      ContainerScalePreset.subtle),
                ),
                ChoiceChip(
                  label: const Text('Balanced'),
                  selected:
                      containerScalePreset == ContainerScalePreset.balanced,
                  onSelected: (_) => onContainerScalePresetChanged(
                    ContainerScalePreset.balanced,
                  ),
                ),
                ChoiceChip(
                  label: const Text('Aggressive'),
                  selected:
                      containerScalePreset == ContainerScalePreset.aggressive,
                  onSelected: (_) => onContainerScalePresetChanged(
                    ContainerScalePreset.aggressive,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          _hintCard(profile: profile),
        ],
      ),
    );
  }

  Widget _hintCard({required DemoPlatformProfile profile}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF5FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD1E2FF)),
      ),
      child: Text(
        profile.interactionHint,
        style: const TextStyle(
          color: Color(0xFF2C405E),
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
      ),
    );
  }
}
