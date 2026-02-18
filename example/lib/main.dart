import 'package:before_after_slider/before_after_slider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  bool _isInBeforeAfterZone = false;
  bool _lockPageScroll = false;

  bool _isZoomModifierPressed() {
    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    final isMac = Theme.of(context).platform == TargetPlatform.macOS;
    if (isMac) {
      return pressed.contains(LogicalKeyboardKey.metaLeft) ||
          pressed.contains(LogicalKeyboardKey.metaRight);
    }
    return pressed.contains(LogicalKeyboardKey.controlLeft) ||
        pressed.contains(LogicalKeyboardKey.controlRight);
  }

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: _lockPageScroll
                  ? const NeverScrollableScrollPhysics()
                  : const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AspectRatio(
                      aspectRatio: 4 / 3,
                      child: MouseRegion(
                        onEnter: (_) {
                          _isInBeforeAfterZone = true;
                        },
                        onExit: (_) {
                          _isInBeforeAfterZone = false;
                          if (_lockPageScroll) {
                            setState(() => _lockPageScroll = false);
                          }
                        },
                        child: Listener(
                          onPointerSignal: (event) {
                            if (!_isInBeforeAfterZone) return;
                            // Wheel/Cmd zoom is resolved by BeforeAfter itself.
                            // Keep page scroll lock disabled here.
                            if (event is PointerScrollEvent &&
                                !_isZoomModifierPressed() &&
                                _lockPageScroll) {
                              setState(() => _lockPageScroll = false);
                            }
                          },
                          onPointerPanZoomStart: (_) {
                            if (_isInBeforeAfterZone && !_lockPageScroll) {
                              setState(() => _lockPageScroll = true);
                            }
                          },
                          onPointerPanZoomUpdate: (_) {
                            if (_isInBeforeAfterZone && !_lockPageScroll) {
                              setState(() => _lockPageScroll = true);
                            }
                          },
                          onPointerPanZoomEnd: (_) {
                            if (_lockPageScroll) {
                              setState(() => _lockPageScroll = false);
                            }
                          },
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
                              // gestureZoomSmoothing: 0.45,
                              zoomPanSensitivity: 0.95,
                              desktopZoom: const DesktopZoomOptions(
                                requiresModifier: true,
                                smoothing: 0.4,
                              ),
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
                                  color: Colors.blue.shade700
                                      .withValues(alpha: 0.85),
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
                      'Drag divider, pinch to zoom, Ctrl/Cmd + wheel for desktop zoom, and double-tap to reset.',
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
