import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/src/flutter/flutter_pixel_alignment.dart';
import 'package:flutter_test_goldens/src/goldens/golden_collections.dart';
import 'package:flutter_test_goldens/src/goldens/golden_rendering.dart';
import 'package:flutter_test_goldens/src/scenes/golden_scene.dart';
import 'package:flutter_test_goldens/src/scenes/scene_layout.dart';

class RowSceneLayout extends FlexSceneLayout {
  const RowSceneLayout({
    super.background,
    super.spacing = defaultGridSpacing,
    super.itemDecorator,
  }) : super(direction: Axis.horizontal);
}

class ColumnSceneLayout extends FlexSceneLayout {
  const ColumnSceneLayout({
    super.background,
    super.spacing = defaultGridSpacing,
    super.itemDecorator,
  }) : super(direction: Axis.vertical);
}

class FlexSceneLayout implements SceneLayout {
  const FlexSceneLayout.row({
    this.background,
    this.spacing = defaultGridSpacing,
    this.itemDecorator,
  }) : direction = Axis.horizontal;

  const FlexSceneLayout.column({
    this.background,
    this.spacing = defaultGridSpacing,
    this.itemDecorator,
  }) : direction = Axis.vertical;

  const FlexSceneLayout({
    required this.direction,
    this.background,
    this.spacing = defaultGridSpacing,
    this.itemDecorator,
  });

  final Axis direction;

  final GoldenSceneBackground? background;

  final GridSpacing spacing;

  /// A decoration built around each screenshot in the final scene.
  ///
  /// This decorator has no impact when building new screenshot widget trees, it
  /// only impacts the final painted scene, after the screenshots have been taken.
  final GoldenSceneItemDecorator? itemDecorator;

  @override
  Widget build(
    WidgetTester tester,
    BuildContext context,
    SceneLayoutContent content,
  ) {
    return FlexGoldenScene(
      direction: direction,
      background: background,
      spacing: spacing,
      itemDecorator: itemDecorator,
      goldens: content.goldens,
    );
  }
}

/// A Golden Scene layout that can orient as either a row or a column.
class FlexGoldenScene extends StatelessWidget {
  const FlexGoldenScene({
    super.key,
    required this.direction,
    this.background,
    this.spacing = defaultGridSpacing,
    this.itemDecorator,
    required this.goldens,
  });

  final Axis direction;

  final GridSpacing spacing;

  final GoldenSceneBackground? background;

  /// A decoration built around each screenshot in the final scene.
  ///
  /// This decorator has no impact when building new screenshot widget trees, it
  /// only impacts the final painted scene, after the screenshots have been taken.
  final GoldenSceneItemDecorator? itemDecorator;

  final Map<GoldenSceneScreenshot, GlobalKey> goldens;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: GoldenSceneTheme.current.defaultTextStyle,
      child: GoldenSceneBounds(
        child: IntrinsicWidth(
          child: IntrinsicHeight(
            child: Stack(
              children: [
                Positioned.fill(
                  child: _buildBackground(context),
                ),
                _buildGoldens(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoldens() {
    return Padding(
      padding: spacing.around,
      child: PixelSnapFlex(
        direction: direction,
        mainAxisSize: MainAxisSize.min,
        spacing: spacing.between,
        children: [
          for (final entry in goldens.entries) //
            IntrinsicWidth(
              // ^ Intrinsic width is needed in case the following decorator has a `Column`, to not blow up
              //   when the `Flex` above is a row.
              child: Builder(builder: (context) {
                return _decorator(
                  context,
                  entry.key.metadata,
                  Image.memory(
                    key: entry.value,
                    entry.key.pngBytes,
                    width: entry.key.size.width.toDouble(),
                    height: entry.key.size.height.toDouble(),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }

  Widget _decorator(BuildContext context, GoldenScreenshotMetadata metadata, Widget child) {
    final itemDecorator = this.itemDecorator ?? GoldenSceneTheme.current.itemDecorator;
    return itemDecorator(context, metadata, child);
  }

  Widget _buildBackground(BuildContext context) {
    return (background ?? GoldenSceneTheme.current.background).build(context);
  }
}
