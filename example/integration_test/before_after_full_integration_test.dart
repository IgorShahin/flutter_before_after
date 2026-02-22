import 'package:before_after_slider/before_after_slider.dart';
import 'package:before_after_slider/src/widgets/default_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('BeforeAfter integration', () {
    testWidgets('renders scene and overlay', (tester) async {
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      expect(find.byType(BeforeAfter), findsOneWidget);
      expect(find.byType(DefaultOverlay), findsOneWidget);
    });

    testWidgets('drag updates progress callback', (tester) async {
      double? callbackValue;
      await tester.pumpWidget(
        _host(
          onProgressChanged: (value) => callbackValue = value,
        ),
      );
      await tester.pumpAndSettle();

      final target = find.byType(BeforeAfter);
      await tester.drag(target, const Offset(120, 0));
      await tester.pumpAndSettle();
      final rightValue = callbackValue;
      expect(rightValue, isNotNull);
      expect(rightValue!, greaterThan(0.5));

      await tester.drag(target, const Offset(-180, 0));
      await tester.pumpAndSettle();
      expect(callbackValue, lessThanOrEqualTo(rightValue));
    });

    testWidgets('interactionOptions.disableProgressWithTouch blocks drag',
        (tester) async {
      double? callbackValue;
      await tester.pumpWidget(
        _host(
          interactionOptions: const BeforeAfterInteractionOptions(
            enableProgressWithTouch: false,
          ),
          onProgressChanged: (value) => callbackValue = value,
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(BeforeAfter), const Offset(140, 0));
      await tester.pumpAndSettle();

      expect(callbackValue, isNull);
    });

    testWidgets('thumbOnly drag mode ignores drag away from thumb',
        (tester) async {
      double? callbackValue;
      await tester.pumpWidget(
        _host(
          interactionOptions: const BeforeAfterInteractionOptions(
            sliderDragMode: SliderDragMode.thumbOnly,
          ),
          onProgressChanged: (value) => callbackValue = value,
        ),
      );
      await tester.pumpAndSettle();

      final target = find.byType(BeforeAfter);
      final rect = tester.getRect(target);
      final start = rect.topLeft + const Offset(12, 12);
      final gesture = await tester.startGesture(start);
      await gesture.moveBy(const Offset(120, 0));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(callbackValue, isNull);
    });

    testWidgets('double tap zooms in when enabled', (tester) async {
      final controller = ZoomController();
      await tester.pumpWidget(
        _host(
          zoomController: controller,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(BeforeAfter));
      await tester.pump(const Duration(milliseconds: 60));
      await tester.tap(find.byType(BeforeAfter));
      await tester.pump(const Duration(milliseconds: 520));

      expect(controller.zoom, greaterThan(1.0));
    });

    testWidgets('double tap zoom stays disabled when configured',
        (tester) async {
      final controller = ZoomController();
      await tester.pumpWidget(
        _host(
          zoomController: controller,
          zoomOptions: const BeforeAfterZoomOptions(
            enableDoubleTapZoom: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(BeforeAfter));
      await tester.pump(const Duration(milliseconds: 60));
      await tester.tap(find.byType(BeforeAfter));
      await tester.pump(const Duration(milliseconds: 520));

      expect(controller.zoom, 1.0);
    });

    testWidgets('zoomOptions.enabled=false disables zoom gestures',
        (tester) async {
      final controller = ZoomController();
      await tester.pumpWidget(
        _host(
          zoomController: controller,
          zoomOptions: const BeforeAfterZoomOptions(enabled: false),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(BeforeAfter));
      await tester.pump(const Duration(milliseconds: 60));
      await tester.tap(find.byType(BeforeAfter));
      await tester.pump(const Duration(milliseconds: 520));

      expect(controller.zoom, 1.0);
    });

    testWidgets('external controller zoom can be changed programmatically',
        (tester) async {
      final controller = ZoomController();
      await tester.pumpWidget(_host(zoomController: controller));
      await tester.pumpAndSettle();

      controller.zoom = 2.0;
      await tester.pump(const Duration(milliseconds: 50));

      expect(controller.zoom, 2.0);
    });

    testWidgets('external controller zoom can be reset to 1x', (tester) async {
      final controller = ZoomController();
      await tester.pumpWidget(_host(zoomController: controller));
      await tester.pumpAndSettle();

      controller.zoom = 2.2;
      await tester.pump(const Duration(milliseconds: 50));
      expect(controller.zoom, 2.2);

      controller.reset();
      await tester.pump(const Duration(milliseconds: 50));
      expect(controller.zoom, 1.0);
    });

    testWidgets('external controller pan can be changed programmatically',
        (tester) async {
      final controller = ZoomController();
      await tester.pumpWidget(_host(zoomController: controller));
      await tester.pumpAndSettle();

      controller.zoom = 2.0;
      await tester.pump(const Duration(milliseconds: 50));

      controller.pan = const Offset(-50, 35);
      await tester.pump(const Duration(milliseconds: 50));

      expect(controller.pan, const Offset(-50, 35));
    });

    testWidgets('labelsOptions.show=false hides custom labels', (tester) async {
      await tester.pumpWidget(
        _host(
          labelsOptions: BeforeAfterLabelsOptions(
            show: false,
            beforeBuilder: (_) => const Text('LBL_B'),
            afterBuilder: (_) => const Text('LBL_A'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('LBL_B'), findsNothing);
      expect(find.text('LBL_A'), findsNothing);
    });

    testWidgets('labels builders render when enabled', (tester) async {
      await tester.pumpWidget(
        _host(
          labelsOptions: BeforeAfterLabelsOptions(
            beforeBuilder: (_) => const Text('Custom Before'),
            afterBuilder: (_) => const Text('Custom After'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Custom Before'), findsOneWidget);
      expect(find.text('Custom After'), findsOneWidget);
    });

    testWidgets('runtime options affect internal controller limits',
        (tester) async {
      await tester.pumpWidget(
        _host(
          zoomOptions: const BeforeAfterZoomOptions(
            runtime: ZoomRuntimeOptions(minZoom: 2.0, maxZoom: 2.0),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final transforms = find.byType(Transform);
      expect(transforms, findsWidgets);
      final transformWidget = tester.widget<Transform>(transforms.first);
      expect(transformWidget.transform.getColumn(0)[0], closeTo(2.0, 0.001));
    });
  });
}

Widget _host({
  BeforeAfterInteractionOptions interactionOptions =
      const BeforeAfterInteractionOptions(),
  BeforeAfterZoomOptions zoomOptions = const BeforeAfterZoomOptions(),
  BeforeAfterLabelsOptions labelsOptions = const BeforeAfterLabelsOptions(),
  ValueChanged<double>? onProgressChanged,
  ZoomController? zoomController,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 420,
          height: 300,
          child: BeforeAfter(
            beforeChild: const ColoredBox(color: Colors.red),
            afterChild: const ColoredBox(color: Colors.blue),
            interactionOptions: interactionOptions,
            zoomOptions: zoomOptions,
            labelsOptions: labelsOptions,
            onProgressChanged: onProgressChanged,
            zoomController: zoomController,
          ),
        ),
      ),
    ),
  );
}
