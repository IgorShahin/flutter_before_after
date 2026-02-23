## 3.1.0

- Added `SliderOrientation` support (`horizontal` / `vertical`).
- Improved gesture/render performance in slider and zoom paths.
- Improved pinch responsiveness during active scale gesture.
- Optimized showcase rebuild behavior and simplified showcase controls.

## 3.0.0

### Breaking
- `BeforeAfter` now uses grouped options:
  - `interactionOptions`
  - `zoomOptions`
  - `labelsOptions`
  - `overlayOptions`
- Removed legacy top-level params (`enableProgressWithTouch`, `enableZoom`, `overlayStyle`, legacy labels/overlay params, `fixedLabels`).

### Added
- Desktop/web pointer cursor customization.
- `autoViewportAspectRatioFromImage` when `viewportAspectRatio` is not provided.
- Integration tests and drag/zoom benchmark scenarios (`example/integration_test`).

### Fixed
- Slider drag conflict while panning zoomed content.
- Pan bounds clamping to avoid visible blank background.
- Desktop/web pointer zoom consistency.

### Performance
- Reduced gesture/render rebuild pressure on hot paths.
- Optimized image stream reuse for auto viewport ratio flow.

### Migration
- Upgrade notes: see `README.md` (`Migration` section).

## 2.0.0

- BREAKING: removed `BeforeAfterImage` and `BeforeAfterLayout`.
- BREAKING: `BeforeAfter` is now the single public widget API:
  - `BeforeAfter(beforeChild: ..., afterChild: ...)`
- BREAKING: removed direct `beforeLabel` and `afterLabel` params.
  - Use `beforeLabelBuilder` and `afterLabelBuilder`.
- Inlined comparison implementation into `BeforeAfter` and removed extra wrapper/core layers.
- Updated docs and examples for the new API.

## 1.1.0

- Added `beforeLabelBuilder` and `afterLabelBuilder` for custom label widgets.
- Added a new labels demo tab in the example app.
- Improved rendering performance with repaint isolation and progress notifier updates.
- Optimized clipping and zoom/pan update flow for smoother interactions.

## 1.0.1

- Fix version alignment between CHANGELOG and pubspec.

## 0.0.1

- First release
