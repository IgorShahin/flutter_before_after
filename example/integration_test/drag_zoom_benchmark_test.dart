import 'dart:ui' show FrameTiming, lerpDouble;

import 'package:before_after_slider/before_after_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('before_after drag + zoom benchmark', (tester) async {
    await tester.pumpWidget(const _BenchmarkApp());
    await tester.pumpAndSettle();

    final target = find.byType(BeforeAfter);
    expect(target, findsOneWidget);

    await _runScenario(tester, target, iterations: 3);

    final summary = await _collectPerformanceSummary(
      binding: binding,
      action: () async => _runScenario(tester, target, iterations: 10),
      reportKey: 'before_after_drag_zoom',
    );

    debugPrint('before_after_drag_zoom summary:');
    debugPrint(
      '  avg_build_ms=${summary['average_frame_build_time_millis']} '
      'p90_build_ms=${summary['90th_percentile_frame_build_time_millis']} '
      'worst_build_ms=${summary['worst_frame_build_time_millis']}',
    );
    debugPrint(
      '  avg_raster_ms=${summary['average_frame_rasterizer_time_millis']} '
      'p90_raster_ms=${summary['90th_percentile_frame_rasterizer_time_millis']} '
      'worst_raster_ms=${summary['worst_frame_rasterizer_time_millis']}',
    );
    debugPrint(
      '  missed_build_budget=${summary['missed_frame_build_budget_count']} '
      'missed_raster_budget=${summary['missed_frame_rasterizer_budget_count']}',
    );
    debugPrint('  frame_count=${summary['frame_count']}');

    final frameCount = (summary['frame_count'] as num?)?.toInt() ?? 0;
    expect(frameCount, greaterThan(30));
  });
}

Future<Map<String, dynamic>> _collectPerformanceSummary({
  required IntegrationTestWidgetsFlutterBinding binding,
  required Future<void> Function() action,
  required String reportKey,
}) async {
  try {
    await binding.watchPerformance(action, reportKey: reportKey);
    final raw = binding.reportData?[reportKey];
    if (raw is Map<String, dynamic>) {
      return raw;
    }
  } catch (error) {
    debugPrint(
      'watchPerformance unavailable, falling back to FrameTiming summary: $error',
    );
  }

  final frameTimings = <FrameTiming>[];
  void onTimings(List<FrameTiming> timings) => frameTimings.addAll(timings);

  WidgetsBinding.instance.addTimingsCallback(onTimings);
  try {
    await action();
    await Future<void>.delayed(const Duration(milliseconds: 800));
  } finally {
    WidgetsBinding.instance.removeTimingsCallback(onTimings);
  }

  final summary = _summarizeFrameTimings(frameTimings);
  binding.reportData ??= <String, dynamic>{};
  binding.reportData![reportKey] = summary;
  return summary;
}

Map<String, dynamic> _summarizeFrameTimings(List<FrameTiming> timings) {
  if (timings.isEmpty) {
    return <String, dynamic>{
      'frame_count': 0,
      'average_frame_build_time_millis': 0.0,
      '90th_percentile_frame_build_time_millis': 0.0,
      'worst_frame_build_time_millis': 0.0,
      'average_frame_rasterizer_time_millis': 0.0,
      '90th_percentile_frame_rasterizer_time_millis': 0.0,
      'worst_frame_rasterizer_time_millis': 0.0,
      'missed_frame_build_budget_count': 0,
      'missed_frame_rasterizer_budget_count': 0,
    };
  }

  final buildMicros = timings
      .map((t) => t.buildDuration.inMicroseconds)
      .toList(growable: false)
    ..sort();
  final rasterMicros = timings
      .map((t) => t.rasterDuration.inMicroseconds)
      .toList(growable: false)
    ..sort();

  double toMillis(num micros) => micros / 1000.0;

  num average(List<int> values) =>
      values.reduce((a, b) => a + b) / values.length;

  int percentile(List<int> values, double p) {
    final index = ((values.length - 1) * p).round().clamp(0, values.length - 1);
    return values[index];
  }

  const frameBudgetMicros = 16666;
  final missedBuild = buildMicros.where((v) => v > frameBudgetMicros).length;
  final missedRaster = rasterMicros.where((v) => v > frameBudgetMicros).length;

  return <String, dynamic>{
    'frame_count': timings.length,
    'average_frame_build_time_millis': toMillis(average(buildMicros)),
    '90th_percentile_frame_build_time_millis':
        toMillis(percentile(buildMicros, 0.9)),
    'worst_frame_build_time_millis': toMillis(buildMicros.last),
    'average_frame_rasterizer_time_millis': toMillis(average(rasterMicros)),
    '90th_percentile_frame_rasterizer_time_millis':
        toMillis(percentile(rasterMicros, 0.9)),
    'worst_frame_rasterizer_time_millis': toMillis(rasterMicros.last),
    'missed_frame_build_budget_count': missedBuild,
    'missed_frame_rasterizer_budget_count': missedRaster,
  };
}

Future<void> _runScenario(
  WidgetTester tester,
  Finder target, {
  required int iterations,
}) async {
  for (var i = 0; i < iterations; i++) {
    await _dragDivider(tester, target, const Offset(120, 0));
    await _dragDivider(tester, target, const Offset(-180, 0));
    await _pinchOnTarget(tester, target, scale: 1.28);
    await _panZoomedContent(tester, target, const Offset(-40, 20));
    await _pinchOnTarget(tester, target, scale: 0.86);
    await tester.pump(const Duration(milliseconds: 12));
  }
  await tester.pumpAndSettle();
}

Future<void> _dragDivider(
  WidgetTester tester,
  Finder target,
  Offset delta,
) async {
  await tester.drag(target, delta);
  await tester.pump(const Duration(milliseconds: 16));
}

Future<void> _panZoomedContent(
  WidgetTester tester,
  Finder target,
  Offset delta,
) async {
  await tester.drag(target, delta);
  await tester.pump(const Duration(milliseconds: 16));
}

Future<void> _pinchOnTarget(
  WidgetTester tester,
  Finder target, {
  required double scale,
}) async {
  final rect = tester.getRect(target);
  final center = rect.center;
  final startDistance = rect.shortestSide * 0.12;
  final endDistance = startDistance * scale;

  final g1 = await tester.startGesture(
    center + Offset(-startDistance, 0),
    pointer: 1,
  );
  final g2 = await tester.startGesture(
    center + Offset(startDistance, 0),
    pointer: 2,
  );

  const steps = 10;
  for (var i = 1; i <= steps; i++) {
    final t = i / steps;
    final d = lerpDouble(startDistance, endDistance, t)!;
    await g1.moveTo(center + Offset(-d, 0));
    await g2.moveTo(center + Offset(d, 0));
    await tester.pump(const Duration(milliseconds: 16));
  }

  await g1.up();
  await g2.up();
  await tester.pump(const Duration(milliseconds: 16));
}

class _BenchmarkApp extends StatelessWidget {
  const _BenchmarkApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 380,
            height: 260,
            child: BeforeAfter(
              beforeChild: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF263238), Color(0xFF455A64)],
                  ),
                ),
              ),
              afterChild: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
                  ),
                ),
              ),
              zoomOptions: BeforeAfterZoomOptions(
                enabled: true,
                zoomPanSensitivity: 1.0,
                enableContainerScaleOnZoom: true,
                containerScaleMax: 1.3,
                containerScaleZoomRange: 1.2,
              ),
              interactionOptions: BeforeAfterInteractionOptions(
                sliderDragMode: SliderDragMode.fullOverlay,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
