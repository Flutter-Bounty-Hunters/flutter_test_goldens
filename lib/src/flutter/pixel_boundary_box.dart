import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';

/// A widget that sizes itself and its [child] such that the child occupies an integer
/// value width and height.
///
/// When laying out a [PixelBoundaryBox], the incoming constraints are pushed to the nearest
/// integer boundary. The minimum width/height are made larger, to the nearest integer. The
/// maximum width/height are made smaller, to the nearest integer. Then, the [child] is laid
/// out within these integer bounds.
///
/// If the [child] reports a size that also has an integer width and height then that size
/// is honored and layout finishes. However, the [child] chooses a size that include a fractional
/// width and/or height, then the [child] is laid out a second time, with tight constraints, which
/// are set to the nearest larger integer for the [child]'s originally reported width and height.
class PixelBoundaryBox extends SingleChildRenderObjectWidget {
  const PixelBoundaryBox({
    super.key,
    required super.child,
  });

  @override
  RenderPixelBoundaryBox createRenderObject(BuildContext context) {
    return RenderPixelBoundaryBox();
  }
}

class RenderPixelBoundaryBox extends RenderProxyBox {
  @override
  void performLayout() {
    if (child == null) {
      size = Size.zero;
      return;
    }

    final integerConstraints = constraints.copyWith(
      minWidth: constraints.minWidth.ceilToDouble(),
      maxWidth: constraints.maxWidth < double.infinity ? constraints.maxWidth.floorToDouble() : double.infinity,
      minHeight: constraints.minHeight.ceilToDouble(),
      maxHeight: constraints.maxHeight < double.infinity ? constraints.maxHeight.floorToDouble() : double.infinity,
    );

    // Let child choose its size within our parent's integer bounded constraints.
    child!.layout(integerConstraints, parentUsesSize: true);

    // Check if the child chose a non-integer size. If it did, re-run layout, forcing it
    // to the nearest larger integer size.
    final childSize = child!.size;
    if (childSize.width != childSize.width.round() || childSize.height != childSize.height.round()) {
      child!.layout(
        BoxConstraints.tight(Size(childSize.width.ceilToDouble(), childSize.height.ceilToDouble())),
        parentUsesSize: true,
      );
    }

    size = child!.size;
  }
}
