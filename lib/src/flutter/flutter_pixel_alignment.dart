import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A widget that works like [Center], except the child's final offset is
/// forced to an integer value, e.g., `(50.4, 30.2)` -> `(50.0, 30.0)`, also
/// the size of the child can optionally be forced to an integer value, too.
///
/// {@template integer_pixel_flakiness}
/// Integer pixel positioning is a strategy to reduce flakiness in golden
/// tests, though it still isn't perfect.
/// {@endtemplate}
class PixelSnapCenter extends SingleChildRenderObjectWidget {
  const PixelSnapCenter({
    super.key,
    this.snapSize = true,
    super.child,
  });

  final bool snapSize;

  @override
  RenderPositionedBoxAtPixel createRenderObject(BuildContext context) {
    return RenderPositionedBoxAtPixel() //
      ..alignment = Alignment.center
      ..snapSize = snapSize;
  }

  @override
  void updateRenderObject(BuildContext context, RenderPositionedBoxAtPixel renderObject) {
    renderObject.snapSize = snapSize;
  }
}

/// A widget that works like [Align], except the child's final offset is
/// forced to an integer value, e.g., `(50.4, 30.2)` -> `(50.0, 30.0)`.
///
/// {@macro integer_pixel_flakiness}
class PixelSnapAlign extends SingleChildRenderObjectWidget {
  const PixelSnapAlign({
    super.key,
    required this.alignment,
    this.snapSize = true,
    super.child,
  });

  final Alignment alignment;
  final bool snapSize;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderPositionedBoxAtPixel() //
      ..alignment = alignment
      ..snapSize = snapSize;
  }

  @override
  void updateRenderObject(BuildContext context, RenderPositionedBoxAtPixel renderObject) {
    renderObject //
      ..alignment = alignment
      ..snapSize = snapSize;
  }
}

/// A [RenderPositionedBox] subclass that ensures each child sits at a whole-pixel (x, y) offset
/// and (optionally) forces children to be sized at integer values.
///
/// {@template render_pixel_snap_performance}
/// This render object works by running the standard layout and then making adjustments
/// after the fact. This isn't great for performance, but this render object is intended
/// for tests where such performance isn't critical.
/// {@endtemplate}
class RenderPositionedBoxAtPixel extends RenderPositionedBox {
  bool _snapSize = true;
  set snapSize(bool newValue) {
    if (newValue == _snapSize) {
      return;
    }

    _snapSize = newValue;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    super.performLayout();

    // Re-position (and maybe resize) child so that it sits on a whole-pixel.
    final child = this.child;
    if (child != null) {
      final parentData = child.parentData as BoxParentData;
      final offset = parentData.offset;
      if (offset.dx != offset.dx.floorToDouble() || offset.dy != offset.dy.floorToDouble()) {
        parentData.offset = Offset(
          offset.dx.floorToDouble(),
          offset.dy.floorToDouble(),
        );
      }

      if (_snapSize && (!child.size.isInteger)) {
        // This child doesn't have an integer width/height - run layout again,
        // forcing an integer size. Prefer to expand, but fallback to shrink.
        _resizeToIntegerSizeStartingWithWidth(constraints, child);
      }
    }
  }
}

/// A [Row] whose children are positioned at whole-pixel offsets, and whose
/// children are forced to layout at whole-pixel widths and heights.
///
/// {@macro integer_pixel_flakiness}
class PixelSnapRow extends Row {
  const PixelSnapRow({
    super.key,
    super.mainAxisAlignment,
    super.mainAxisSize,
    super.crossAxisAlignment,
    super.textDirection,
    super.verticalDirection,
    super.textBaseline, // NO DEFAULT: we don't know what the text's baseline should be
    super.spacing,
    super.children,
  });

  @override
  RenderPixelSnapFlex createRenderObject(BuildContext context) {
    return RenderPixelSnapFlex(
      direction: direction,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      textDirection: getEffectiveTextDirection(context),
      verticalDirection: verticalDirection,
      textBaseline: textBaseline,
      clipBehavior: clipBehavior,
      spacing: spacing,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderPixelSnapFlex renderObject) {
    renderObject
      ..direction = direction
      ..mainAxisAlignment = mainAxisAlignment
      ..mainAxisSize = mainAxisSize
      ..crossAxisAlignment = crossAxisAlignment
      ..textDirection = getEffectiveTextDirection(context)
      ..verticalDirection = verticalDirection
      ..textBaseline = textBaseline
      ..clipBehavior = clipBehavior
      ..spacing = spacing;
  }
}

/// A [Column] whose children are positioned at whole-pixel offsets, and whose
/// children are forced to layout at whole-pixel widths and heights.
///
/// {@macro integer_pixel_flakiness}
class PixelSnapColumn extends Column {
  const PixelSnapColumn({
    super.key,
    super.mainAxisAlignment,
    super.mainAxisSize,
    super.crossAxisAlignment,
    super.textDirection,
    super.verticalDirection,
    super.textBaseline,
    super.spacing,
    super.children,
  });

  @override
  RenderPixelSnapFlex createRenderObject(BuildContext context) {
    return RenderPixelSnapFlex(
      direction: direction,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      textDirection: getEffectiveTextDirection(context),
      verticalDirection: verticalDirection,
      textBaseline: textBaseline,
      clipBehavior: clipBehavior,
      spacing: spacing,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderPixelSnapFlex renderObject) {
    renderObject
      ..direction = direction
      ..mainAxisAlignment = mainAxisAlignment
      ..mainAxisSize = mainAxisSize
      ..crossAxisAlignment = crossAxisAlignment
      ..textDirection = getEffectiveTextDirection(context)
      ..verticalDirection = verticalDirection
      ..textBaseline = textBaseline
      ..clipBehavior = clipBehavior
      ..spacing = spacing;
  }
}

/// A [Flex] whose children are positioned at whole-pixel offsets, and whose
/// children are forced to layout at whole-pixel widths and heights.
///
/// {@macro integer_pixel_flakiness}
class PixelSnapFlex extends Flex {
  const PixelSnapFlex({
    super.key,
    required super.direction,
    super.mainAxisAlignment,
    super.mainAxisSize,
    super.crossAxisAlignment,
    super.textDirection,
    super.verticalDirection,
    super.textBaseline,
    super.spacing,
    super.children,
  });

  @override
  RenderPixelSnapFlex createRenderObject(BuildContext context) {
    return RenderPixelSnapFlex(
      direction: direction,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      textDirection: getEffectiveTextDirection(context),
      verticalDirection: verticalDirection,
      textBaseline: textBaseline,
      clipBehavior: clipBehavior,
      spacing: spacing,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderPixelSnapFlex renderObject) {
    renderObject
      ..direction = direction
      ..mainAxisAlignment = mainAxisAlignment
      ..mainAxisSize = mainAxisSize
      ..crossAxisAlignment = crossAxisAlignment
      ..textDirection = getEffectiveTextDirection(context)
      ..verticalDirection = verticalDirection
      ..textBaseline = textBaseline
      ..clipBehavior = clipBehavior
      ..spacing = spacing;
  }
}

/// A [RenderFlex] subclass that ensures each child sits at a whole-pixel (x, y) offset
/// and (optionally) forces children to be sized at integer values.
///
/// {@macro render_pixel_snap_performance}
class RenderPixelSnapFlex extends RenderFlex {
  RenderPixelSnapFlex({
    required super.direction,
    super.mainAxisSize = MainAxisSize.max,
    super.mainAxisAlignment = MainAxisAlignment.start,
    super.crossAxisAlignment = CrossAxisAlignment.center,
    super.textDirection,
    super.verticalDirection = VerticalDirection.down,
    super.textBaseline,
    super.clipBehavior = Clip.none,
    super.spacing = 0.0,
    super.children,
  });

  @override
  void performLayout() {
    super.performLayout();

    // Re-position children so that they sit on a whole-pixel.
    final children = getChildrenAsList();
    for (final child in children) {
      final parentData = child.parentData as BoxParentData;
      final offset = parentData.offset;
      if (offset.dx != offset.dx.floorToDouble() || offset.dy != offset.dy.floorToDouble()) {
        // This child doesn't have an integer x/y offset - change the offset to
        // be the nearest lesser integer offset.
        parentData.offset = Offset(
          offset.dx.floorToDouble(),
          offset.dy.floorToDouble(),
        );
      }

      if (!child.size.isInteger) {
        // This child doesn't have an integer width/height - run layout again,
        // forcing either slightly bigger or slightly smaller.
        //
        // There are a couple details that are sometimes important when changing
        // the size to an integer value.
        //
        // First, we must always be mindful of text with intrinsic sizing. Any
        // reduction in bounds to intrinsically sized text will force a relayout with
        // some kind of wrapping, because the text reported exactly the bounds for
        // its current layout. Thus, we want to prefer expanding size rather than
        // contracting size. But we need to do our best to handle size contraction,
        // too, in case we're dealing with a hard width or height constraint.
        //
        // Second, Columns and Rows are often intrinsically sized, too, in both
        // dimensions. That said, Columns are often given space to expand/contract
        // vertically, and Rows are often given space to expand/contract horizontally.
        // For this reason, we treat Columns and Rows differently for re-sizing - we
        // try to fit the cross-axis first, and then the main-axis second.
        if (direction == Axis.vertical) {
          _resizeToIntegerSizeStartingWithWidth(constraints, child);
        } else {
          _resizeToIntegerSizeStartingWithHeight(constraints, child);
        }
      }
    }
  }
}

void _resizeToIntegerSizeStartingWithWidth(BoxConstraints constraints, RenderBox child) {
  if (child.size.isInteger) {
    return;
  }

  // Start with width.
  final widest = constraints.biggest.width;
  late final int newWidth;
  late final bool didShrinkWidth;
  if (!child.size.widthIsInteger) {
    if (child.size.width <= widest) {
      // We prefer to increase size rather than decrease size, because text
      // wrapping becomes a problem when shrinking intrinsic size. We can fit
      // a bigger width, so use that.
      newWidth = child.size.width.ceil();
      didShrinkWidth = false;
    } else {
      // We prefer wider over narrower, but we can't fit any wider. Shrink instead.
      newWidth = child.size.width.floor();
      didShrinkWidth = true;
    }
  } else {
    newWidth = child.size.width.toInt();
    didShrinkWidth = false;
  }

  if (didShrinkWidth) {
    // Shrinking the width has a non-trivial chance of significantly impacting the
    // height, so run layout again with the new width and then deal with the height.
    child.layout(BoxConstraints.tightFor(width: newWidth.toDouble()), parentUsesSize: true);
  }

  // Now do the main-axis.
  final tallest = constraints.biggest.height;
  late final int newHeight;
  if (!child.size.heightIsInteger) {
    if (child.size.height <= tallest) {
      newHeight = child.size.height.ceil();
    } else {
      newHeight = child.size.height.floor();
    }
  } else {
    newHeight = child.size.height.toInt();
  }

  // Note: This layout process can fail if a situation arises in which both the
  // width and height need to contract, or if contracting the width produces a
  // much taller height that violates constraints. If this happens to you, please
  // file an issue on GitHub for flutter_test_goldens and provide us with the exact
  // situation that's breaking for you.
  child.layout(
    BoxConstraints.tightFor(
      width: newWidth.toDouble(),
      height: newHeight.toDouble(),
    ),
  );
}

void _resizeToIntegerSizeStartingWithHeight(BoxConstraints constraints, RenderBox child) {
  if (child.size.isInteger) {
    return;
  }

  // Start with the height.
  final tallest = constraints.biggest.height;
  late final int newHeight;
  late final bool didShrinkHeight;
  if (!child.size.heightIsInteger) {
    if (child.size.height <= tallest) {
      // We prefer to increase size rather than decrease size, because text
      // wrapping (and other layouts) becomes a problem when shrinking intrinsic
      // size. We can fit a bigger height, so use that.
      newHeight = child.size.height.ceil();
      didShrinkHeight = false;
    } else {
      // We prefer taller over shorter, but we can't fit any taller. Shrink instead.
      newHeight = child.size.height.floor();
      didShrinkHeight = true;
    }
  } else {
    newHeight = child.size.height.toInt();
    didShrinkHeight = false;
  }

  if (didShrinkHeight) {
    // Shrinking the height has a non-trivial chance of significantly impacting the
    // width, so run layout again with the new height and then deal with the width.
    child.layout(BoxConstraints.tightFor(height: newHeight.toDouble()), parentUsesSize: true);
  }

  // Now do the main-axis.
  final widest = constraints.biggest.width;
  late final int newWidth;
  if (!child.size.widthIsInteger) {
    if (child.size.width <= widest) {
      newWidth = child.size.width.ceil();
    } else {
      newWidth = child.size.width.floor();
    }
  } else {
    newWidth = child.size.width.toInt();
  }

  // Note: This layout process can fail if a situation arises in which both the
  // width and height need to contract, or if contracting the width produces a
  // much taller height that violates constraints. If this happens to you, please
  // file an issue on GitHub for flutter_test_goldens and provide us with the exact
  // situation that's breaking for you.
  child.layout(
    BoxConstraints.tightFor(
      width: newWidth.toDouble(),
      height: newHeight.toDouble(),
    ),
  );
}

extension on Size {
  bool get isInteger => widthIsInteger && heightIsInteger;

  bool get widthIsInteger => width == width.floorToDouble();

  bool get heightIsInteger => height == height.floorToDouble();
}
