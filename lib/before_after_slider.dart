/// A Flutter package for creating interactive before/after image comparison widgets.
///
/// This package provides widgets for comparing two images or any widgets
/// with an interactive slider, zoom, and pan gestures.
///
/// ## Features
///
/// - Compare images with drag-to-reveal interaction
/// - Compare any widgets using [BeforeAfter]
/// - Pinch-to-zoom and pan support
/// - Double-tap to reset zoom
/// - Customizable overlay (divider line and thumb)
/// - Customizable labels
/// - Support for different content orders (before/after or after/before)
///
/// ## Usage
///
/// ```dart
/// import 'package:before_after_slider/before_after_slider.dart';
///
/// // Compare two images
/// BeforeAfter(
///   beforeChild: Image(image: AssetImage('assets/before.jpg')),
///   afterChild: Image(image: AssetImage('assets/after.jpg')),
/// )
///
/// // Compare any widgets
/// BeforeAfter(
///   beforeChild: Container(color: Colors.red),
///   afterChild: Container(color: Colors.blue),
/// )
/// ```
library;

export 'src/before_after.dart';
export 'src/content_order.dart';
export 'src/desktop_zoom_options.dart';
export 'src/label_behavior.dart';
export 'src/overlay_style.dart';
export 'src/slider_drag_mode.dart';
export 'src/zoom_controller.dart';
