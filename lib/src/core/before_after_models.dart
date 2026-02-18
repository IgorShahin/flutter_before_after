part of '../before_after.dart';

class _VisualGeometry {
  const _VisualGeometry({
    required this.width,
    required this.height,
    required this.offsetX,
    required this.offsetY,
  });

  final double width;
  final double height;
  final double offsetX;
  final double offsetY;
}

class _SideContent {
  const _SideContent({
    required this.leftChild,
    required this.rightChild,
    required this.leftLabel,
    required this.rightLabel,
  });

  final Widget leftChild;
  final Widget rightChild;
  final Widget leftLabel;
  final Widget rightLabel;
}

class _LeftRectClipper extends CustomClipper<Rect> {
  _LeftRectClipper(this.dividerX);

  final double dividerX;

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, dividerX, size.height);
  }

  @override
  bool shouldReclip(_LeftRectClipper oldClipper) {
    return dividerX != oldClipper.dividerX;
  }
}

class _RightRectClipper extends CustomClipper<Rect> {
  _RightRectClipper(this.dividerX);

  final double dividerX;

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(dividerX, 0, size.width, size.height);
  }

  @override
  bool shouldReclip(_RightRectClipper oldClipper) {
    return dividerX != oldClipper.dividerX;
  }
}
