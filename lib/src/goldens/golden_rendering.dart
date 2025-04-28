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
