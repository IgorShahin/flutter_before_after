/// A Flutter package for creating interactive before/after image comparison widgets.
///
/// This package provides widgets for comparing two images or any widgets
/// with an interactive slider, zoom, and pan gestures.
///
/// ## Features
///
/// - Compare images with drag-to-reveal interaction
/// - Compare any widgets using [BeforeAfterLayout]
/// - Pinch-to-zoom and pan support
/// - Double-tap to reset zoom
/// - Customizable overlay (divider line and thumb)
/// - Customizable labels
/// - Support for different content orders (before/after or after/before)
///
/// ## Usage
///
/// ```dart
/// import 'package:flutter_before_after/flutter_before_after.dart';
///
/// // Compare two images
/// BeforeAfterImage(
///   beforeImage: AssetImage('assets/before.jpg'),
///   afterImage: AssetImage('assets/after.jpg'),
/// )
///
/// // Compare any widgets
/// BeforeAfterLayout(
///   beforeChild: Container(color: Colors.red),
///   afterChild: Container(color: Colors.blue),
/// )
/// ```
library;

export 'src/before_after_image.dart';
export 'src/before_after_layout.dart';
export 'src/content_order.dart';
export 'src/default_overlay.dart';
export 'src/labels.dart';
export 'src/overlay_style.dart';
export 'src/zoom_controller.dart';