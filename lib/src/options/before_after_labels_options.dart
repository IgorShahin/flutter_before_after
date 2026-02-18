import 'package:flutter/widgets.dart';

import '../enums/label_behavior.dart';

/// Grouped labels configuration for [BeforeAfter].
@immutable
class BeforeAfterLabelsOptions {
  const BeforeAfterLabelsOptions({
    this.show = true,
    this.behavior = LabelBehavior.staticOverlaySafe,
    this.beforeBuilder,
    this.afterBuilder,
  });

  final bool show;
  final LabelBehavior behavior;
  final WidgetBuilder? beforeBuilder;
  final WidgetBuilder? afterBuilder;
}
