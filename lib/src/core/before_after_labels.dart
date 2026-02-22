part of '../before_after.dart';

extension _BeforeAfterLabelsX on _BeforeAfterState {
  LabelBehavior get _effectiveLabelBehavior => widget.labelsOptions.behavior;

  _SideContent _resolveSideContent(BuildContext context) {
    if (widget.contentOrder == ContentOrder.beforeAfter) {
      return _SideContent(
        leftChild: widget.beforeChild,
        rightChild: widget.afterChild,
        leftLabel: widget.labelsOptions.beforeBuilder?.call(context) ??
            BeforeLabel(contentOrder: widget.contentOrder),
        rightLabel: widget.labelsOptions.afterBuilder?.call(context) ??
            AfterLabel(contentOrder: widget.contentOrder),
      );
    }

    return _SideContent(
      leftChild: widget.afterChild,
      rightChild: widget.beforeChild,
      leftLabel: widget.labelsOptions.afterBuilder?.call(context) ??
          AfterLabel(contentOrder: widget.contentOrder),
      rightLabel: widget.labelsOptions.beforeBuilder?.call(context) ??
          BeforeLabel(contentOrder: widget.contentOrder),
    );
  }
}
