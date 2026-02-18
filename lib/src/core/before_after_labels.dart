part of '../before_after.dart';

extension _BeforeAfterLabelsX on _BeforeAfterState {
  LabelBehavior get _effectiveLabelBehavior {
    final optionBehavior = widget.labelsOptions?.behavior;
    if (optionBehavior != null) return optionBehavior;
    final configured = widget.labelBehavior;
    if (configured != null) return configured;
    // ignore: deprecated_member_use_from_same_package
    return widget.fixedLabels
        ? LabelBehavior.staticOverlaySafe
        : LabelBehavior.attachedToContent;
  }

  _SideContent _resolveSideContent(BuildContext context) {
    if (widget.contentOrder == ContentOrder.beforeAfter) {
      return _SideContent(
        leftChild: widget.beforeChild,
        rightChild: widget.afterChild,
        leftLabel: widget.labelsOptions?.beforeBuilder?.call(context) ??
            widget.beforeLabelBuilder?.call(context) ??
            BeforeLabel(contentOrder: widget.contentOrder),
        rightLabel: widget.labelsOptions?.afterBuilder?.call(context) ??
            widget.afterLabelBuilder?.call(context) ??
            AfterLabel(contentOrder: widget.contentOrder),
      );
    }

    return _SideContent(
      leftChild: widget.afterChild,
      rightChild: widget.beforeChild,
      leftLabel: widget.labelsOptions?.afterBuilder?.call(context) ??
          widget.afterLabelBuilder?.call(context) ??
          AfterLabel(contentOrder: widget.contentOrder),
      rightLabel: widget.labelsOptions?.beforeBuilder?.call(context) ??
          widget.beforeLabelBuilder?.call(context) ??
          BeforeLabel(contentOrder: widget.contentOrder),
    );
  }
}
