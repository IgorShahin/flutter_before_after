import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:before_after_slider/before_after_slider.dart';
import 'package:before_after_slider/src/default_overlay.dart';

void main() {
  group('ZoomController', () {
    test('initial values are correct', () {
      final controller = ZoomController();
      expect(controller.zoom, 1.0);
      expect(controller.pan, Offset.zero);
      expect(controller.rotation, 0.0);
    });

    test('zoom is clamped to minZoom and maxZoom', () {
      final controller = ZoomController(minZoom: 1.0, maxZoom: 3.0);

      controller.zoom = 0.5;
      expect(controller.zoom, 1.0);

      controller.zoom = 5.0;
      expect(controller.zoom, 3.0);

      controller.zoom = 2.0;
      expect(controller.zoom, 2.0);
    });

    test('updateFromGesture applies zoom correctly', () {
      final controller = ZoomController();
      const size = Size(400, 300);

      // Zoom in by 2x
      controller.updateFromGesture(
        containerSize: size,
        zoomDelta: 2.0,
      );
      expect(controller.zoom, 2.0);

      // Zoom in more (relative)
      controller.updateFromGesture(
        containerSize: size,
        zoomDelta: 1.5,
      );
      expect(controller.zoom, 3.0);
    });

    test('updateFromGesture applies pan correctly without zoom multiplier', () {
      final controller = ZoomController(boundPan: false);
      const size = Size(400, 300);

      // Pan should be applied directly, not multiplied by zoom
      controller.updateFromGesture(
        containerSize: size,
        panDelta: const Offset(10, 20),
      );
      expect(controller.pan, const Offset(10, 20));

      // Even at zoom 2.0, panDelta should be applied 1:1
      controller.zoom = 2.0;
      controller.updateFromGesture(
        containerSize: size,
        panDelta: const Offset(5, 5),
      );
      // Should be 10+5=15, 20+5=25, NOT (10+5*2, 20+5*2)
      expect(controller.pan, const Offset(15, 25));
    });

    test('pan is bounded when boundPan is true', () {
      final controller = ZoomController(boundPan: true);
      const size = Size(400, 300);

      // At zoom 1.0, pan should be bounded to 0
      controller.updateFromGesture(
        containerSize: size,
        panDelta: const Offset(100, 100),
      );
      expect(controller.pan, Offset.zero);

      // At zoom 2.0, max pan is (width * (zoom-1) / 2) = 400 * 1.0 / 2 = 200
      // maxY = 300 * 1.0 / 2 = 150
      controller.zoom = 2.0;
      controller.pan = Offset.zero;
      controller.updateFromGesture(
        containerSize: size,
        panDelta: const Offset(50, 40),
      );
      expect(controller.pan.dx, 50);
      expect(controller.pan.dy, 40);

      // Try to exceed bounds
      controller.updateFromGesture(
        containerSize: size,
        panDelta: const Offset(300, 300),
      );
      // Should be clamped to maxX=200, maxY=150
      expect(controller.pan.dx, 200);
      expect(controller.pan.dy, 150);
    });

    test('reset restores initial values', () {
      final controller = ZoomController();
      const size = Size(400, 300);

      controller.updateFromGesture(
        containerSize: size,
        zoomDelta: 2.0,
        panDelta: const Offset(10, 10),
      );

      controller.reset();
      expect(controller.zoom, 1.0);
      expect(controller.pan, Offset.zero);
      expect(controller.rotation, 0.0);
    });

    test('transformationMatrix is correct', () {
      final controller = ZoomController();
      controller.zoom = 2.0;
      controller.pan = const Offset(10, 20);

      final matrix = controller.transformationMatrix;
      // Matrix should have scale 2.0 and translation (10, 20)
      expect(matrix.getColumn(0)[0], 2.0); // scaleX
      expect(matrix.getColumn(1)[1], 2.0); // scaleY
      expect(matrix.getColumn(3)[0], 10.0); // translateX
      expect(matrix.getColumn(3)[1], 20.0); // translateY
    });

    test('zoom preserves between gesture sequences (simulating pinch)', () {
      final controller = ZoomController();
      const size = Size(400, 300);

      // Simulate first pinch gesture - zoom to 2x
      // When gesture starts, details.scale = 1.0
      // When fingers spread 2x apart, details.scale = 2.0
      // So zoomDelta = 2.0 / 1.0 = 2.0
      controller.updateFromGesture(
        containerSize: size,
        zoomDelta: 2.0,
      );
      expect(controller.zoom, 2.0);

      // Release fingers - gesture ends
      // New gesture starts - details.scale resets to 1.0
      // If we apply zoomDelta = 1.0, zoom should STAY at 2.0
      controller.updateFromGesture(
        containerSize: size,
        zoomDelta: 1.0,
      );
      expect(controller.zoom, 2.0); // Should NOT reset!

      // Continue second gesture - spread fingers 1.5x
      // zoomDelta = 1.5 / 1.0 = 1.5
      // zoom = 2.0 * 1.5 = 3.0
      controller.updateFromGesture(
        containerSize: size,
        zoomDelta: 1.5,
      );
      expect(controller.zoom, 3.0);
    });

    test('notifies listeners on changes', () {
      final controller = ZoomController();
      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.zoom = 2.0;
      expect(notifyCount, 1);

      controller.pan = const Offset(10, 10);
      expect(notifyCount, 2);

      controller.reset();
      expect(notifyCount, 3);
    });
  });

  group('BeforeAfter widget tests', () {
    testWidgets('renders before and after children', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BeforeAfter(
                beforeChild: ColoredBox(color: Colors.red),
                afterChild: ColoredBox(color: Colors.blue),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(BeforeAfter), findsOneWidget);
      expect(find.byType(DefaultOverlay), findsOneWidget);
    });

    testWidgets('external zoom controller works', (tester) async {
      final zoomController = ZoomController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BeforeAfter(
                beforeChild: const ColoredBox(color: Colors.red),
                afterChild: const ColoredBox(color: Colors.blue),
                zoomController: zoomController,
              ),
            ),
          ),
        ),
      );

      // Programmatically change zoom
      zoomController.zoom = 2.5;
      await tester.pump();

      expect(zoomController.zoom, 2.5);
    });

    testWidgets('double tap resets zoom', (tester) async {
      final zoomController = ZoomController();
      zoomController.zoom = 2.0;
      zoomController.pan = const Offset(50, 50);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BeforeAfter(
                beforeChild: const ColoredBox(color: Colors.red),
                afterChild: const ColoredBox(color: Colors.blue),
                zoomController: zoomController,
              ),
            ),
          ),
        ),
      );

      expect(zoomController.zoom, 2.0);

      // Double tap using tester.doubleTap
      await tester.tap(find.byType(BeforeAfter));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byType(BeforeAfter));
      await tester.pumpAndSettle();

      expect(zoomController.zoom, 1.0);
      expect(zoomController.pan, Offset.zero);
    });

    testWidgets(
        'overlay remains screen-fixed while zoom and pan change content',
        (tester) async {
      final zoomController = ZoomController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BeforeAfter(
                beforeChild: const ColoredBox(color: Colors.red),
                afterChild: const ColoredBox(color: Colors.blue),
                zoomController: zoomController,
              ),
            ),
          ),
        ),
      );

      // Get initial overlay position
      var overlay = tester.widget<DefaultOverlay>(find.byType(DefaultOverlay));
      final initialPosition = overlay.position;

      // At progress 0.5 and zoom 1.0, position.dx should be width/2 = 200
      expect(initialPosition.dx, 200);

      // Zoom in
      zoomController.zoom = 2.0;
      await tester.pump();

      // Get updated overlay position
      overlay = tester.widget<DefaultOverlay>(find.byType(DefaultOverlay));
      final zoomedPosition = overlay.position;

      // At zoom 2.0, the divider at content x=200 should appear at screen x=200
      // (center stays center when zooming around center)
      // But with pan, it would move. With pan=0, center stays same
      expect(zoomedPosition.dx, 200);

      // Pan changes only content transform, not the screen-fixed overlay.
      zoomController.pan = const Offset(50, 0);
      await tester.pump();

      overlay = tester.widget<DefaultOverlay>(find.byType(DefaultOverlay));
      final pannedPosition = overlay.position;

      expect(pannedPosition.dx, 200);
    });

    testWidgets('overlay style does not change with zoom', (tester) async {
      final zoomController = ZoomController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BeforeAfter(
                beforeChild: const ColoredBox(color: Colors.red),
                afterChild: const ColoredBox(color: Colors.blue),
                zoomController: zoomController,
                overlayStyle: const OverlayStyle(thumbSize: 40),
              ),
            ),
          ),
        ),
      );

      // Check thumb size before zoom
      var overlay = tester.widget<DefaultOverlay>(find.byType(DefaultOverlay));
      expect(overlay.style.thumbSize, 40);

      // Zoom in
      zoomController.zoom = 3.0;
      await tester.pump();

      // Thumb size should still be 40, not 120
      overlay = tester.widget<DefaultOverlay>(find.byType(DefaultOverlay));
      expect(overlay.style.thumbSize, 40);
    });

    testWidgets('progress can be controlled externally', (tester) async {
      double progress = 0.5;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    Expanded(
                      child: BeforeAfter(
                        beforeChild: const ColoredBox(color: Colors.red),
                        afterChild: const ColoredBox(color: Colors.blue),
                        progress: progress,
                        onProgressChanged: (value) {
                          setState(() => progress = value);
                        },
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => setState(() => progress = 0.8),
                      child: const Text('Set 80%'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      // Initial position at 50%
      var overlay = tester.widget<DefaultOverlay>(find.byType(DefaultOverlay));
      expect(overlay.position.dx,
          closeTo(tester.getSize(find.byType(BeforeAfter)).width * 0.5, 1));

      // Tap button to change progress
      await tester.tap(find.text('Set 80%'));
      await tester.pump();

      // Position should now be at 80%
      overlay = tester.widget<DefaultOverlay>(find.byType(DefaultOverlay));
      expect(overlay.position.dx,
          closeTo(tester.getSize(find.byType(BeforeAfter)).width * 0.8, 1));
    });

    testWidgets('custom label widgets can be provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BeforeAfter(
                beforeChild: const ColoredBox(color: Colors.red),
                afterChild: const ColoredBox(color: Colors.blue),
                beforeLabelBuilder: (_) => const Text('My Before'),
                afterLabelBuilder: (_) => const Text('My After'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('My Before'), findsOneWidget);
      expect(find.text('My After'), findsOneWidget);
    });
  });

  group('Coordinate transformation tests', () {
    test('content to screen transformation is correct', () {
      // Test the math: screenX = (contentX - centerX) * zoom + centerX + panX
      const centerX = 200.0;
      const centerY = 150.0;

      // At zoom 1.0, pan 0: screen = content
      var zoom = 1.0;
      var pan = Offset.zero;
      var contentPoint = const Offset(200, 150);
      var screenPoint = Offset(
        (contentPoint.dx - centerX) * zoom + centerX + pan.dx,
        (contentPoint.dy - centerY) * zoom + centerY + pan.dy,
      );
      expect(screenPoint, contentPoint);

      // At zoom 2.0, pan 0: center stays, edges move
      zoom = 2.0;
      contentPoint = const Offset(100, 75); // Quarter point
      screenPoint = Offset(
        (contentPoint.dx - centerX) * zoom + centerX + pan.dx,
        (contentPoint.dy - centerY) * zoom + centerY + pan.dy,
      );
      // (100 - 200) * 2 + 200 = -200 + 200 = 0
      expect(screenPoint.dx, 0);
      expect(screenPoint.dy, 0);

      // At zoom 2.0, pan (50, 25): everything shifts
      pan = const Offset(50, 25);
      contentPoint = const Offset(200, 150); // Center
      screenPoint = Offset(
        (contentPoint.dx - centerX) * zoom + centerX + pan.dx,
        (contentPoint.dy - centerY) * zoom + centerY + pan.dy,
      );
      expect(screenPoint.dx, 250); // 0 + 200 + 50
      expect(screenPoint.dy, 175); // 0 + 150 + 25
    });

    test('screen to content transformation is correct (inverse)', () {
      const centerX = 200.0;
      const centerY = 150.0;

      // Inverse: contentX = (screenX - centerX - panX) / zoom + centerX
      const zoom = 2.0;
      const pan = Offset(50, 25);
      var screenPoint = const Offset(250, 175); // Where center appears
      var contentPoint = Offset(
        (screenPoint.dx - centerX - pan.dx) / zoom + centerX,
        (screenPoint.dy - centerY - pan.dy) / zoom + centerY,
      );
      expect(contentPoint.dx, 200); // Center
      expect(contentPoint.dy, 150); // Center

      // Touch at screen left edge
      screenPoint = const Offset(0, 0);
      contentPoint = Offset(
        (screenPoint.dx - centerX - pan.dx) / zoom + centerX,
        (screenPoint.dy - centerY - pan.dy) / zoom + centerY,
      );
      // (0 - 200 - 50) / 2 + 200 = -125 + 200 = 75
      expect(contentPoint.dx, 75);
      // (0 - 150 - 25) / 2 + 150 = -87.5 + 150 = 62.5
      expect(contentPoint.dy, 62.5);
    });
  });
}
