import 'package:before_after_slider/before_after_slider.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const DemoApp());
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'before_after_slider demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const DemoPage(),
    );
  }
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  final ZoomController _zoomController = ZoomController();
  double _progress = 0.5;

  @override
  void dispose() {
    _zoomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Before/After Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BeforeAfter(
                  beforeChild: Image.asset(
                    'assets/before.jpeg',
                    fit: BoxFit.cover,
                  ),
                  afterChild: Image.asset(
                    'assets/after.jpeg',
                    fit: BoxFit.cover,
                  ),
                  progress: _progress,
                  // showLabels: false,
                  sliderDragMode: SliderDragMode.thumbOnly,
                  onProgressChanged: (value) {
                    setState(() {
                      _progress = value;
                    });
                  },
                  beforeLabelBuilder: (_) => Container(
                    margin: const EdgeInsets.all(10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'Before',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  afterLabelBuilder: (_) => Container(
                    margin: const EdgeInsets.all(10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade700.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'After',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  zoomController: _zoomController,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Progress: ${(_progress * 100).round()}%'),
            Slider(
              value: _progress,
              onChanged: (value) {
                setState(() {
                  _progress = value;
                });
              },
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: _zoomController.reset,
              child: const Text('Reset Zoom'),
            ),
            const SizedBox(height: 12),
            const Text(
              'Drag the divider, pinch to zoom, and double-tap to reset.',
            ),
          ],
        ),
      ),
    );
  }
}
