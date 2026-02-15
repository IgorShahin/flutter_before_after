import 'package:flutter/material.dart';
import 'package:before_after_slider/before_after_slider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Before/After Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Before/After Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          BeforeAfterImageDemo(),
          BeforeAfterLayoutDemo(),
          LabelBuilderDemo(),
          CustomOverlayDemo(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.image),
            label: 'Image',
          ),
          NavigationDestination(
            icon: Icon(Icons.layers),
            label: 'Layout',
          ),
          NavigationDestination(
            icon: Icon(Icons.brush),
            label: 'Labels',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_fix_high),
            label: 'Custom',
          ),
        ],
      ),
    );
  }
}

/// Demo for BeforeAfterImage widget.
class BeforeAfterImageDemo extends StatefulWidget {
  const BeforeAfterImageDemo({super.key});

  @override
  State<BeforeAfterImageDemo> createState() => _BeforeAfterImageDemoState();
}

class _BeforeAfterImageDemoState extends State<BeforeAfterImageDemo> {
  double _progress = 0.5;
  ContentOrder _contentOrder = ContentOrder.beforeAfter;
  BoxFit _fit = BoxFit.contain;
  final ZoomController _zoomController = ZoomController();

  @override
  void initState() {
    super.initState();
    _zoomController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _zoomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Before/After Image widget
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: BeforeAfter(
                beforeChild: Image(
                  image: AssetImage('assets/before.png'),
                  fit: _fit,
                ),
                afterChild: Image(
                  image: AssetImage('assets/after.png'),
                  fit: _fit,
                ),
                progress: _progress,
                onProgressChanged: (value) {
                  setState(() {
                    _progress = value;
                  });
                },
                contentOrder: _contentOrder,
                zoomController: _zoomController,
                overlayStyle: const OverlayStyle(
                  dividerColor: Colors.white,
                  dividerWidth: 2,
                  thumbSize: 40,
                  thumbElevation: 4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Progress slider
          Text('Progress: ${(_progress * 100).toStringAsFixed(0)}%'),
          Slider(
            value: _progress,
            onChanged: (value) {
              setState(() {
                _progress = value;
              });
            },
          ),
          const SizedBox(height: 16),

          // Content order toggle
          Row(
            children: [
              const Text('Content Order:'),
              const SizedBox(width: 16),
              ChoiceChip(
                label: const Text('Before/After'),
                selected: _contentOrder == ContentOrder.beforeAfter,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _contentOrder = ContentOrder.beforeAfter;
                    });
                  }
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('After/Before'),
                selected: _contentOrder == ContentOrder.afterBefore,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _contentOrder = ContentOrder.afterBefore;
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // BoxFit selector
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              const Text('Fit: '),
              for (final fit in [
                BoxFit.contain,
                BoxFit.cover,
                BoxFit.fill,
                BoxFit.fitWidth,
                BoxFit.fitHeight,
              ])
                ChoiceChip(
                  label: Text(fit.name),
                  selected: _fit == fit,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _fit = fit;
                      });
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 24),

          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Debug Info',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Zoom: ${_zoomController.zoom.toStringAsFixed(2)}x'),
                  Text(
                      'Pan: (${_zoomController.pan.dx.toStringAsFixed(1)}, ${_zoomController.pan.dy.toStringAsFixed(1)})'),
                  Text('Progress: ${(_progress * 100).toStringAsFixed(1)}%'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Instructions',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('• Drag the thumb to change progress'),
                  Text('• Pinch to zoom'),
                  Text('• Double-tap to reset zoom'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Demo for BeforeAfterLayout widget.
class BeforeAfterLayoutDemo extends StatelessWidget {
  const BeforeAfterLayoutDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Compare any widgets',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: BeforeAfter(
                beforeChild: Container(
                  color: Colors.blue.shade100,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.looks_one, size: 64, color: Colors.blue),
                        SizedBox(height: 16),
                        Text(
                          'Material Design 2',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text('Classic Flutter widgets'),
                      ],
                    ),
                  ),
                ),
                afterChild: Container(
                  color: Colors.purple.shade100,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.looks_two, size: 64, color: Colors.purple),
                        SizedBox(height: 16),
                        Text(
                          'Material Design 3',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text('Modern Flutter widgets'),
                      ],
                    ),
                  ),
                ),
                overlayStyle: const OverlayStyle(
                  dividerColor: Colors.deepPurple,
                  dividerWidth: 3,
                  thumbBackgroundColor: Colors.deepPurple,
                  thumbIconColor: Colors.white,
                  thumbSize: 48,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Demo for custom label builders.
class LabelBuilderDemo extends StatefulWidget {
  const LabelBuilderDemo({super.key});

  @override
  State<LabelBuilderDemo> createState() => _LabelBuilderDemoState();
}

class _LabelBuilderDemoState extends State<LabelBuilderDemo> {
  double _progress = 0.5;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Custom Label Builders',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: BeforeAfter(
                beforeChild: const Image(
                  image: AssetImage('assets/before.png'),
                ),
                afterChild: const Image(
                  image: AssetImage('assets/after.png'),
                ),
                progress: _progress,
                onProgressChanged: (value) => setState(() => _progress = value),
                beforeLabelBuilder: (_) => Container(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 16, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'Before',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                afterLabelBuilder: (_) => Container(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade600,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'After',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'This demo uses beforeLabelBuilder and afterLabelBuilder to render fully custom widgets.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Demo for custom overlay.
class CustomOverlayDemo extends StatefulWidget {
  const CustomOverlayDemo({super.key});

  @override
  State<CustomOverlayDemo> createState() => _CustomOverlayDemoState();
}

class _CustomOverlayDemoState extends State<CustomOverlayDemo> {
  double _progress = 0.5;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Custom Overlay',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: BeforeAfter(
                beforeChild: const Image(
                  image: AssetImage('assets/before_alt.png'),
                ),
                afterChild: const Image(
                  image: AssetImage('assets/after_alt.png'),
                ),
                progress: _progress,
                onProgressChanged: (value) {
                  setState(() {
                    _progress = value;
                  });
                },
                beforeLabel: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Blurred',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                afterLabel: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Original',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                overlay: (size, position) {
                  return CustomPaint(
                    size: size,
                    painter: _GradientDividerPainter(
                      position: position.dx,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'This demo shows a custom gradient overlay instead of the default divider.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter that draws a gradient divider.
class _GradientDividerPainter extends CustomPainter {
  _GradientDividerPainter({required this.position});

  final double position;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.purple,
          Colors.blue,
          Colors.cyan,
        ],
      ).createShader(Rect.fromLTWH(position - 2, 0, 4, size.height))
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(position, 0),
      Offset(position, size.height),
      paint,
    );

    // Draw thumb
    final thumbPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.purple, Colors.blue],
      ).createShader(
        Rect.fromCircle(center: Offset(position, size.height / 2), radius: 20),
      );

    canvas.drawCircle(
      Offset(position, size.height / 2),
      20,
      thumbPaint,
    );

    // Draw arrows
    final arrowPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final centerY = size.height / 2;

    // Left arrow
    canvas.drawLine(
      Offset(position - 8, centerY),
      Offset(position - 4, centerY - 5),
      arrowPaint,
    );
    canvas.drawLine(
      Offset(position - 8, centerY),
      Offset(position - 4, centerY + 5),
      arrowPaint,
    );

    // Right arrow
    canvas.drawLine(
      Offset(position + 8, centerY),
      Offset(position + 4, centerY - 5),
      arrowPaint,
    );
    canvas.drawLine(
      Offset(position + 8, centerY),
      Offset(position + 4, centerY + 5),
      arrowPaint,
    );
  }

  @override
  bool shouldRepaint(_GradientDividerPainter oldDelegate) {
    return position != oldDelegate.position;
  }
}
