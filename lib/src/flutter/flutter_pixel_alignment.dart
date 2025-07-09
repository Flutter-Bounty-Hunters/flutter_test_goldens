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

      if (_snapSize &&
          (child.size.width != child.size.width.floorToDouble() ||
              child.size.height != child.size.height.floorToDouble())) {
        // This child doesn't have an integer width/height - run layout again,
        // forcing the nearest smaller size.
        child.layout(
          BoxConstraints.tightFor(
            width: child.size.width.floorToDouble(),
            height: child.size.height.floorToDouble(),
          ),
        );
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

      if (child.size.width != child.size.width.floorToDouble() ||
          child.size.height != child.size.height.floorToDouble()) {
        // This child doesn't have an integer width/height - run layout again,
        // forcing the nearest smaller size.
        child.layout(
          BoxConstraints.tightFor(
            width: child.size.width.floorToDouble(),
            height: child.size.height.floorToDouble(),
          ),
        );
      }
    }
  }
}
