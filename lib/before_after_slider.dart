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
/// - Double-tap zoom toggle with animation
/// - Customizable overlay (divider line and thumb)
/// - Grouped options for zoom, labels, and interactions
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
export 'src/controllers/zoom_controller.dart';
export 'src/enums/content_order.dart';
export 'src/enums/label_behavior.dart';
export 'src/enums/slider_drag_mode.dart';
export 'src/options/before_after_interaction_options.dart';
export 'src/options/before_after_labels_options.dart';
export 'src/options/before_after_zoom_options.dart';
export 'src/options/desktop_zoom_options.dart';
export 'src/options/overlay_style.dart';
export 'src/options/slider_hit_zone.dart';
