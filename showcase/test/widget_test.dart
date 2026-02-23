// ignore_for_file: avoid_relative_lib_imports

import 'package:flutter_test/flutter_test.dart';

import '../lib/src/app.dart';

void main() {
  testWidgets('renders showcase app', (tester) async {
    await tester.pumpWidget(const DemoApp());

    expect(find.text('Before/After Showcase'), findsOneWidget);
  });
}
