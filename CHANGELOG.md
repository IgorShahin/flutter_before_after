## 2.0.0

- BREAKING: removed `BeforeAfterImage` and `BeforeAfterLayout`.
- BREAKING: `BeforeAfter` is now the single public widget API:
  - `BeforeAfter(beforeChild: ..., afterChild: ...)`
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
