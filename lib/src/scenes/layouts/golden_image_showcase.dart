import 'package:flutter/widgets.dart';

class GoldenImageShowcase extends SlottedMultiChildRenderObjectWidget {
  static const _slotGolden = "golden";
  static const _slotLabel = "label";

  const GoldenImageShowcase({
    super.key,
    required this.golden,
    required this.label,
    this.description,
  });

  final Widget golden;
  final Widget label;

  final String? description;

  @override
  Iterable get slots => [_slotGolden, _slotLabel];

  @override
  Widget? childForSlot(slot) {
    switch (slot) {
      case _slotGolden:
        return golden;
      case _slotLabel:
        return label;
      default:
        return null;
    }
  }

  @override
  RenderGoldenShowcase createRenderObject(BuildContext context) {
    return RenderGoldenShowcase()..description = description;
  }

  @override
  void updateRenderObject(BuildContext context, RenderGoldenShowcase renderObject) {
    renderObject.description = description;
  }
}

class RenderGoldenShowcase extends RenderBox with SlottedContainerRenderObjectMixin {
  String? description;

  @override
  void performLayout() {
    print("------- performLayout -------");
    print("Laying out $description - constraints: $constraints");
    final renderGolden = childForSlot(GoldenImageShowcase._slotGolden)! as RenderBox;
    renderGolden.layout(constraints.copyWith(minHeight: 0), parentUsesSize: true);
    print(
        " - golden, intrinsic width: ${renderGolden.computeMinIntrinsicWidth(double.infinity)}, wants to be: ${renderGolden.size} ($renderGolden)");

    final renderLabel = childForSlot(GoldenImageShowcase._slotLabel)! as RenderBox;
    renderLabel.layout(constraints.copyWith(minHeight: 0), parentUsesSize: true);
    print(
        " - label intrinsic width: ${renderLabel.computeMaxIntrinsicWidth(double.infinity)}, wants to be: ${renderLabel.size} ($renderLabel)");

    late final double width;
    if (renderGolden.size.width >= renderLabel.size.width) {
      print("Golden is setting the reference width");
      width = renderGolden.size.width;
      print(" - golden width: $width");

      final goldenHeight = renderGolden.computeMinIntrinsicHeight(width);
      print(" - golden min intrinsic height: $goldenHeight");
      renderGolden.layout(BoxConstraints.tightFor(width: width, height: goldenHeight), parentUsesSize: true);
      print(" - final golden size: ${renderGolden.size}");

      print(" - label min intrinsic height: ${renderLabel.computeMinIntrinsicHeight(width)}");
      renderLabel.layout(BoxConstraints.tightFor(width: width), parentUsesSize: true);
      print(" - final label size: ${renderLabel.size}");
    } else {
      print("Label is setting the reference width");
      width = renderLabel.size.width;
      print(" - label width: $width");
      print(" - label min intrinsic height: ${renderLabel.computeMinIntrinsicHeight(width)}");

      final goldenHeight = renderGolden.computeMinIntrinsicHeight(width);
      print(" - golden min intrinsic height: $goldenHeight");
      renderGolden.layout(BoxConstraints.tightFor(width: width, height: goldenHeight), parentUsesSize: true);
      print(" - final golden size: ${renderGolden.size}");
    }

    final desiredSize = Size(width, renderGolden.size.height + renderLabel.size.height);
    print("Description: $description, desired size: $desiredSize, max allowable size: ${constraints.biggest}");

    size = Size(width, renderGolden.size.height + renderLabel.size.height);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final renderGolden = childForSlot(GoldenImageShowcase._slotGolden)! as RenderBox;
    final renderLabel = childForSlot(GoldenImageShowcase._slotLabel)! as RenderBox;

    context.paintChild(renderGolden, offset + Offset.zero);
    context.paintChild(renderLabel, offset + Offset(0, renderGolden.size.height.ceilToDouble()));
  }
}
