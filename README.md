# before_after_slider

Before/after comparison widget for Flutter with a draggable divider, zoom, pan,
custom overlays, and label behavior control.

Perfect for image editing previews, map/style comparisons, redesign demos, and
any side-by-side state comparison UI.

## Features

- Compare two images with `BeforeAfter`
- Compare any two widgets with `BeforeAfter`
- Smooth drag gesture and full divider-line hit area
- Pinch-to-zoom and pan gestures
- Desktop zoom with Ctrl/Cmd + wheel at cursor position
- Double-tap zoom toggle with smooth animation
- Custom overlay style (`OverlayStyle`) or fully custom overlay builder
- Grouped options API (`BeforeAfterZoomOptions`, `BeforeAfterLabelsOptions`, `BeforeAfterInteractionOptions`)
- Toggle labels visibility with `showLabels`
- Label behavior control with `LabelBehavior`
- Select drag area with `sliderDragMode`
- External `ZoomController` for programmatic control
- Controlled/uncontrolled progress modes

## Platform Support

| Android | iOS | Web | macOS | Windows | Linux |
| --- | --- | --- | --- | --- | --- |
| ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

## Installation

```yaml
dependencies:
  before_after_slider: ^2.0.0
```

```bash
flutter pub get
```

## Quick Start

```dart
import 'package:before_after_slider/before_after_slider.dart';

BeforeAfter(
  beforeChild: const Image(image: AssetImage('assets/before.jpg')),
  afterChild: const Image(image: AssetImage('assets/after.jpg')),
)
```

## Usage

### Image Comparison

```dart
BeforeAfter(
  beforeChild: const Image(
    image: AssetImage('assets/before.jpg'),
    fit: BoxFit.contain,
    alignment: Alignment.center,
  ),
  afterChild: const Image(
    image: AssetImage('assets/after.jpg'),
    fit: BoxFit.contain,
    alignment: Alignment.center,
  ),
  progress: 0.5,
  zoomOptions: const BeforeAfterZoomOptions(
    enabled: true,
    doubleTapZoomScale: 3.0,
  ),
  labelsOptions: const BeforeAfterLabelsOptions(
    behavior: LabelBehavior.staticOverlaySafe,
  ),
  interactionOptions: const BeforeAfterInteractionOptions(
    sliderDragMode: SliderDragMode.fullOverlay,
  ),
  overlayOptions: const BeforeAfterOverlayOptions(
    style: OverlayStyle(
      dividerWidth: 2,
      thumbSize: 40,
    ),
  ),
  onProgressChanged: (value) {
    // 0.0 .. 1.0
  },
)
```

### Widget Comparison

```dart
BeforeAfter(
  beforeChild: Container(color: const Color(0xFFDCEBFF)),
  afterChild: Container(color: const Color(0xFFFFECD8)),
  zoomOptions: const BeforeAfterZoomOptions(enabled: true),
  labelsOptions: const BeforeAfterLabelsOptions(
    behavior: LabelBehavior.staticOverlaySafe,
  ),
)
```

### Zoom Controller

```dart
final controller = ZoomController();

BeforeAfter(
  beforeChild: const Image(image: AssetImage('assets/before.jpg')),
  afterChild: const Image(image: AssetImage('assets/after.jpg')),
  zoomController: controller,
);

// Programmatic reset:
controller.reset();
```

## API At A Glance

### Core Widgets

`BeforeAfter` supports:

- `progress` (controlled mode)
- `onProgressChanged`, `onProgressStart`, `onProgressEnd`
- `interactionOptions` (`BeforeAfterInteractionOptions`)
- `zoomOptions` (`BeforeAfterZoomOptions`)
- `labelsOptions` (`BeforeAfterLabelsOptions`)
- `contentOrder`
- `overlayOptions` (`BeforeAfterOverlayOptions`)
- `zoomController`

`zoomOptions.desktop.requiresModifier` uses platform-specific keys by default:
- macOS: `Cmd`
- Windows/Linux: `Ctrl`

Example:
```dart
BeforeAfter(
  beforeChild: ...,
  afterChild: ...,
  zoomOptions: const BeforeAfterZoomOptions(
    desktop: DesktopZoomOptions(
      requiresModifier: true,
      smoothing: 0.4,
    ),
  ),
)
```

### Slider Drag Mode

- `SliderDragMode.fullOverlay` (default)  
  Drag starts from divider line or thumb.
- `SliderDragMode.thumbOnly`  
  Drag starts only from thumb/icon area.

### Label Behavior

- `LabelBehavior.staticOverlaySafe` (default)  
  Labels stay static and render above the slider overlay.
- `LabelBehavior.attachedToContent`  
  Labels attach to each side and are clipped by the divider.

`fixedLabels` is still supported for backward compatibility but deprecated.

## Migration From 1.x

`2.0.0` contains a breaking API change.

- Removed: `BeforeAfterImage`
- Removed: `BeforeAfterLayout`
- Use: `BeforeAfter(beforeChild: ..., afterChild: ...)`

### Before (1.x)

```dart
BeforeAfterImage(
  beforeImage: const AssetImage('assets/before.jpg'),
  afterImage: const AssetImage('assets/after.jpg'),
)

BeforeAfterLayout(
  beforeChild: Container(color: Colors.red),
  afterChild: Container(color: Colors.blue),
)
```

### After (2.x)

```dart
BeforeAfter(
  beforeChild: const Image(image: AssetImage('assets/before.jpg')),
  afterChild: const Image(image: AssetImage('assets/after.jpg')),
)

BeforeAfter(
  beforeChild: Container(color: Colors.red),
  afterChild: Container(color: Colors.blue),
)
```

## Example App

Interactive demo app is included in:

`example/lib/main.dart`

## Contributing

Issues and pull requests are welcome:

- Repository: <https://github.com/IgorShahin/before_after_slider>
- Issues: <https://github.com/IgorShahin/before_after_slider/issues>

## License

See `LICENSE`.
