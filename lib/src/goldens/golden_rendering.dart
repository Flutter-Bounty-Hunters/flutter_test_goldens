import 'package:flutter/cupertino.dart';

/// A widget that represents the boundary within a widget tree where a golden scene
/// is displayed.
///
/// A golden scene can contain multiple golden images.
///
/// This widget has two primary functions:
///
///  1. Provide a widget type that can be used in `Finder`s to locate the
///     desired bounds for a golden scene.
///
///  2. Inject a [RepaintBoundary] so that we're sure that we can take a screenshot
///     at this point in the widget tree.
///
/// This widget is similar to [GoldenImageBounds] except this widget represents the boundary
/// of an entire golden scene, rather than an individual golden image.
class GoldenSceneBounds extends StatelessWidget {
  const GoldenSceneBounds({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: child,
    );
  }
}

/// A widget that represents the boundary within a widget tree where a golden image
/// is displayed.
///
/// This widget has two primary functions:
///
///  1. Provide a widget type that can be used in `Finder`s to locate the
///     desired bounds for a golden image.
///
///  2. Inject a [RepaintBoundary] so that we're sure that we can take a screenshot
///     at this point in the widget tree.
///
/// This widget is similar to [GoldenSceneBounds] except this widget represents the boundary
/// of a single golden image, rather than a whole scene.
class GoldenImageBounds extends StatelessWidget {
  const GoldenImageBounds({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: child,
    );
  }
}
