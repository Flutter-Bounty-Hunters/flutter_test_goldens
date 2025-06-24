import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/src/goldens/golden_collections.dart';

/// Builder that returns a widget for a Golden Scene that lays out all the [goldens].
abstract interface class SceneLayout {
  Widget build(
    WidgetTester tester,
    BuildContext context,
    // TODO: We need a data structure that represents all incoming info:
    //       - description of scene
    //       - each screenshot
    //         - pixels
    //         - description
    //         - WidgetTester simulated timestamp (for animation durations)
    //         - layers
    //         - GlobalKey
    //
    // Pretty much everything from GoldenSceneMetadata, minus the final bounds,
    // plus GlobalKeys for reach screenshot.
    //
    // This way the scene can show the scene description, each golden description,
    // the timestamp of each golden, log out the number of layers, etc.
    Map<GoldenSceneScreenshot, GlobalKey> goldens,
  );
}

const defaultGridSpacing = GridSpacing(around: EdgeInsets.all(48), between: 48);

class GridSpacing {
  const GridSpacing({
    required this.around,
    required this.between,
  });

  final EdgeInsets around;
  final double between;
}
