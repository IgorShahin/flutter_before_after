import 'package:flutter/material.dart';

import '../enums/content_order.dart';

/// A label widget for the "Before" image.
///
/// Automatically positions itself based on [contentOrder].
class BeforeLabel extends StatelessWidget {
  /// Creates a before label.
  const BeforeLabel({
    super.key,
    this.text = 'Before',
    this.style,
    this.padding = const EdgeInsets.all(8.0),
    this.contentOrder = ContentOrder.beforeAfter,
  });

  /// The text to display.
  final String text;

  /// The text style. If null, uses white bold text.
  final TextStyle? style;

  /// Padding around the label.
  final EdgeInsetsGeometry padding;

  /// The content order, used to determine label position.
  final ContentOrder contentOrder;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style ??
        const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
          shadows: [
            Shadow(
              offset: Offset(1, 1),
              blurRadius: 2,
              color: Colors.black54,
            ),
          ],
        );

    return Padding(
      padding: padding,
      child: Text(text, style: effectiveStyle),
    );
  }

  /// Returns the alignment for this label based on content order.
  Alignment get alignment {
    return contentOrder == ContentOrder.beforeAfter ? Alignment.topLeft : Alignment.topRight;
  }
}

/// A label widget for the "After" image.
///
/// Automatically positions itself based on [contentOrder].
class AfterLabel extends StatelessWidget {
  /// Creates an after label.
  const AfterLabel({
    super.key,
    this.text = 'After',
    this.style,
    this.padding = const EdgeInsets.all(8.0),
    this.contentOrder = ContentOrder.beforeAfter,
  });

  /// The text to display.
  final String text;

  /// The text style. If null, uses white bold text.
  final TextStyle? style;

  /// Padding around the label.
  final EdgeInsetsGeometry padding;

  /// The content order, used to determine label position.
  final ContentOrder contentOrder;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style ??
        const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
          shadows: [
            Shadow(
              offset: Offset(1, 1),
              blurRadius: 2,
              color: Colors.black54,
            ),
          ],
        );

    return Padding(
      padding: padding,
      child: Text(text, style: effectiveStyle),
    );
  }

  /// Returns the alignment for this label based on content order.
  Alignment get alignment {
    return contentOrder == ContentOrder.beforeAfter ? Alignment.topRight : Alignment.topLeft;
  }
}
