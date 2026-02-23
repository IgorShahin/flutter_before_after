import 'package:before_after_slider/before_after_slider.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'before_after_slider example',
      home: const ExamplePage(),
      theme: ThemeData(useMaterial3: true),
    );
  }
}

class ExamplePage extends StatefulWidget {
  const ExamplePage({super.key});

  @override
  State<ExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends State<ExamplePage> {
  double _progress = 0.5;
  SliderOrientation _orientation = SliderOrientation.horizontal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('before_after_slider example')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: BeforeAfter(
                autoViewportAspectRatioFromImage: true,
                beforeChild:
                    Image.asset('assets/before.jpeg', fit: BoxFit.cover),
                afterChild: Image.asset('assets/after.jpeg', fit: BoxFit.cover),
                progress: _progress,
                onProgressChanged: (value) => setState(() => _progress = value),
                interactionOptions: BeforeAfterInteractionOptions(
                  sliderOrientation: _orientation,
                ),
                zoomOptions: BeforeAfterZoomOptions(
                  enableContainerScaleOnZoom: true,
                  reverseZoomEffectBorderRadius: 16,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<SliderOrientation>(
              segments: const [
                ButtonSegment<SliderOrientation>(
                  value: SliderOrientation.horizontal,
                  label: Text('Horizontal'),
                ),
                ButtonSegment<SliderOrientation>(
                  value: SliderOrientation.vertical,
                  label: Text('Vertical'),
                ),
              ],
              selected: {_orientation},
              onSelectionChanged: (selection) {
                setState(() {
                  _orientation = selection.first;
                });
              },
            ),
            const SizedBox(height: 8),
            Slider(
              value: _progress,
              onChanged: (value) => setState(() => _progress = value),
            ),
          ],
        ),
      ),
    );
  }
}
