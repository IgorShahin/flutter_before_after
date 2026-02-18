/// Defines how before/after labels behave relative to slider and content.
enum LabelBehavior {
  /// Labels stay static in the container and are always above the overlay.
  staticOverlaySafe,

  /// Labels are attached to their content sides and clipped by the divider.
  attachedToContent,
}
