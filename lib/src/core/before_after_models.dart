part of '../before_after.dart';

class _VisualGeometry {
  const _VisualGeometry({
    required this.width,
    required this.height,
    required this.offsetX,
    required this.offsetY,
    required this.containerScale,
  });

  final double width;
  final double height;
  final double offsetX;
  final double offsetY;
  final double containerScale;
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

class _TopRectClipper extends CustomClipper<Rect> {
  _TopRectClipper(this.dividerY);

  final double dividerY;

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, size.width, dividerY);
  }

  @override
  bool shouldReclip(_TopRectClipper oldClipper) {
    return dividerY != oldClipper.dividerY;
  }
}

class _BottomRectClipper extends CustomClipper<Rect> {
  _BottomRectClipper(this.dividerY);

  final double dividerY;

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, dividerY, size.width, size.height);
  }

  @override
  bool shouldReclip(_BottomRectClipper oldClipper) {
    return dividerY != oldClipper.dividerY;
  }
}
