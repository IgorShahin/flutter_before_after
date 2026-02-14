# flutter_before_after

Before/after comparison widget for Flutter with a draggable divider, zoom, pan,
custom overlays, and label behavior control.

Perfect for image editing previews, map/style comparisons, redesign demos, and
any side-by-side state comparison UI.

## Features

- Compare two images with `BeforeAfterImage`
- Compare any two widgets with `BeforeAfterLayout`
- Smooth drag gesture and full divider-line hit area
- Pinch-to-zoom and pan gestures
- Double-tap to reset zoom
- Custom overlay style (`OverlayStyle`) or fully custom overlay builder
- Custom labels (`beforeLabel`, `afterLabel`)
- `fixedLabels` mode to keep labels static during zoom/pan
- External `ZoomController` for programmatic control
- Controlled/uncontrolled progress modes

## Platform Support

| Android | iOS | Web | macOS | Windows | Linux |
| --- | --- | --- | --- | --- | --- |
| ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

## Installation

```yaml
dependencies:
  flutter_before_after: ^1.0.0
```

```bash
flutter pub get
```

## Quick Start

```dart
import 'package:flutter_before_after/flutter_before_after.dart';

BeforeAfterImage(
  beforeImage: const AssetImage('assets/before.jpg'),
  afterImage: const AssetImage('assets/after.jpg'),
)
```

## Usage

### Image Comparison

```dart
BeforeAfterImage(
  beforeImage: const AssetImage('assets/before.jpg'),
  afterImage: const AssetImage('assets/after.jpg'),
  progress: 0.5,
  enableZoom: true,
  fixedLabels: true,
  overlayStyle: const OverlayStyle(
    dividerWidth: 2,
    thumbSize: 40,
  ),
  onProgressChanged: (value) {
    // 0.0 .. 1.0
  },
)
```

### Widget Comparison

```dart
BeforeAfterLayout(
  beforeChild: Container(color: const Color(0xFFDCEBFF)),
  afterChild: Container(color: const Color(0xFFFFECD8)),
  enableZoom: true,
  fixedLabels: true,
)
```

### Zoom Controller

```dart
final controller = ZoomController();

BeforeAfterImage(
  beforeImage: const AssetImage('assets/before.jpg'),
  afterImage: const AssetImage('assets/after.jpg'),
  zoomController: controller,
);

// Programmatic reset:
controller.reset();
```

## API At A Glance

### Core Widgets

`BeforeAfterImage` and `BeforeAfterLayout` support:

- `progress` (controlled mode)
- `onProgressChanged`, `onProgressStart`, `onProgressEnd`
- `enableProgressWithTouch`
- `enableZoom`
- `fixedLabels`
- `contentOrder`
- `overlayStyle`
- `beforeLabel`, `afterLabel`
- `overlay` (custom builder)
- `zoomController`

### `fixedLabels` Behavior

- `fixedLabels: true` (default)  
  Labels stay in static screen positions while content zooms/pans.
- `fixedLabels: false`  
  Labels transform together with compared content.

## Example App

Interactive demo app is included in:

`example/lib/main.dart`

## Contributing

Issues and pull requests are welcome:

- Repository: <https://github.com/IgorShahin/flutter_before_after>
- Issues: <https://github.com/IgorShahin/flutter_before_after/issues>

## License

See `LICENSE`.
