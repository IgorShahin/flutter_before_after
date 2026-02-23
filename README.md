# before_after_slider

<p align="center">
  <a href="https://pub.dev/packages/before_after_slider"><img src="https://img.shields.io/pub/v/before_after_slider.svg" alt="pub version"></a>
  <a href="https://pub.dev/packages/before_after_slider/score"><img src="https://img.shields.io/pub/likes/before_after_slider" alt="likes"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue" alt="license"></a>
</p>

<p align="center">
  <a href="https://igorshahin.github.io/before_after_slider/"><img src="https://img.shields.io/badge/Live%20Demo-Open%20Web%20Demo-1f6feb?style=for-the-badge" alt="Live Demo"></a>
  <a href="https://github.com/IgorShahin/before_after_slider/tree/main/showcase/lib/main.dart"><img src="https://img.shields.io/badge/Showcase-View%20Source-2ea44f?style=for-the-badge" alt="Showcase Source"></a>
  <a href="https://github.com/IgorShahin/before_after_slider/issues"><img src="https://img.shields.io/badge/Support-Issues-orange?style=for-the-badge" alt="Issues"></a>
</p>

A production-ready Flutter widget for before/after comparison with smooth divider drag, zoom/pan gestures, and customizable labels and overlay.

## Features

- Single universal widget: `BeforeAfter(beforeChild, afterChild)`
- Works with images and arbitrary widgets
- Controlled and uncontrolled progress modes
- Pinch zoom + pan on mobile
- Cmd/Ctrl + wheel zoom on desktop and web
- Optional double-tap zoom
- Grouped options API (`interaction`, `zoom`, `labels`, `overlay`)
- External `ZoomController` support
- Platform-adaptive demo app (web/desktop/mobile)

## Get Started

### Installation

```yaml
dependencies:
  before_after_slider: ^3.0.0
```

```bash
flutter pub get
```

### Quick Start

```dart
import 'package:before_after_slider/before_after_slider.dart';

BeforeAfter(
  beforeChild: const Image(
    image: AssetImage('assets/before.jpg'),
    fit: BoxFit.cover,
  ),
  afterChild: const Image(
    image: AssetImage('assets/after.jpg'),
    fit: BoxFit.cover,
  ),
)
```

## API Design

`BeforeAfter` keeps top-level usage clean and groups behavior into dedicated options:

- `interactionOptions` for dragging and hit zones
- `zoomOptions` for zoom/pan/pointer settings
- `labelsOptions` for label visibility and rendering
- `overlayOptions` for style or custom overlay builder

## Usage Recipes

### Controlled slider

```dart
class _MyPageState extends State<MyPage> {
  double progress = 0.5;

  @override
  Widget build(BuildContext context) {
    return BeforeAfter(
      beforeChild: const Image(image: AssetImage('assets/before.jpg'), fit: BoxFit.cover),
      afterChild: const Image(image: AssetImage('assets/after.jpg'), fit: BoxFit.cover),
      progress: progress,
      onProgressChanged: (value) => setState(() => progress = value),
    );
  }
}
```

### Full interactive setup

```dart
BeforeAfter(
  beforeChild: const Image(image: AssetImage('assets/before.jpg'), fit: BoxFit.cover),
  afterChild: const Image(image: AssetImage('assets/after.jpg'), fit: BoxFit.cover),

  interactionOptions: const BeforeAfterInteractionOptions(
    sliderOrientation: SliderOrientation.horizontal,
    sliderDragMode: SliderDragMode.fullOverlay,
    sliderHitZone: SliderHitZone(
      minLineHalfWidth: 18,
      minThumbRadius: 30,
    ),
  ),

  zoomOptions: const BeforeAfterZoomOptions(
    enabled: true,
    pointer: PointerZoomOptions(
      requiresModifier: true,
      smoothing: 0.4,
    ),
    enableDoubleTapZoom: true,
    doubleTapZoomScale: 3.0,
  ),

  labelsOptions: BeforeAfterLabelsOptions(
    behavior: LabelBehavior.attachedToContent,
    beforeBuilder: (_) => const Text('Before'),
    afterBuilder: (_) => const Text('After'),
  ),

  overlayOptions: const BeforeAfterOverlayOptions(
    style: OverlayStyle(
      dividerWidth: 2,
      thumbSize: 40,
    ),
  ),
)
```

### Vertical slider orientation

```dart
BeforeAfter(
  beforeChild: ...,
  afterChild: ...,
  interactionOptions: const BeforeAfterInteractionOptions(
    sliderOrientation: SliderOrientation.vertical,
  ),
)
```

### Custom overlay

```dart
BeforeAfter(
  beforeChild: ...,
  afterChild: ...,
  overlayOptions: BeforeAfterOverlayOptions(
    builder: (size, position) {
      return Stack(
        children: [
          Positioned(
            left: position.dx,
            top: 0,
            bottom: 0,
            child: const VerticalDivider(width: 2, color: Colors.white),
          ),
        ],
      );
    },
  ),
)
```

### Auto viewport ratio from image

```dart
BeforeAfter(
  autoViewportAspectRatioFromImage: true,
  beforeChild: const Image(image: AssetImage('assets/before.jpg')),
  afterChild: const Image(image: AssetImage('assets/after.jpg')),
)
```

Notes:
- `viewportAspectRatio` has higher priority than auto mode.
- Auto mode currently reads ratio from direct `Image` children.

### Programmatic zoom control

```dart
final zoomController = ZoomController();

BeforeAfter(
  beforeChild: ...,
  afterChild: ...,
  zoomController: zoomController,
)

zoomController.reset();
```

## Desktop and Web Controls

If `PointerZoomOptions.requiresModifier = true`:

- macOS: hold `Cmd` and use wheel/scroll
- Windows/Linux/Web: hold `Ctrl` and use wheel/scroll

## Migration

### 2.x -> 3.x

`3.x` finalized grouped options in `BeforeAfter`.

Before:

```dart
BeforeAfter(
  beforeChild: ...,
  afterChild: ...,
  overlayStyle: const OverlayStyle(...),
  enableProgressWithTouch: true,
  enableZoom: true,
)
```

After:

```dart
BeforeAfter(
  beforeChild: ...,
  afterChild: ...,
  interactionOptions: const BeforeAfterInteractionOptions(
    enableProgressWithTouch: true,
  ),
  zoomOptions: const BeforeAfterZoomOptions(
    enabled: true,
  ),
  overlayOptions: const BeforeAfterOverlayOptions(
    style: OverlayStyle(...),
  ),
)
```

### 1.x -> 2.x

- Removed `BeforeAfterImage`
- Removed `BeforeAfterLayout`
- Unified API in `BeforeAfter`
