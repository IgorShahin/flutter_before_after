// Utility functions for scaling and interpolation.

/// Linearly interpolates between two values.
double lerp(double start, double end, double amount) {
  return (1 - amount) * start + amount * end;
}

/// Calculates the fraction of [pos] between [start] and [end].
///
/// Returns a value between 0.0 and 1.0.
double calculateFraction(double start, double end, double pos) {
  if (end - start == 0) return 0.0;
  return ((pos - start) / (end - start)).clamp(0.0, 1.0);
}

/// Scales a value from one range to another.
///
/// Maps [pos] from the range [start1, end1] to the range [start2, end2].
double scale(
  double start1,
  double end1,
  double pos,
  double start2,
  double end2,
) {
  return lerp(start2, end2, calculateFraction(start1, end1, pos));
}