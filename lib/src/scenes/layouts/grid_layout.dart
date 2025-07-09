import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/flutter_test_goldens.dart';

class GridGoldenSceneLayout implements SceneLayout {
  const GridGoldenSceneLayout({
    this.background,
    this.spacing = defaultGridSpacing,
    this.itemDecorator,
  });

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
    return GridGoldenScene(
      background: background,
      spacing: spacing,
      itemDecorator: itemDecorator,
      goldens: content.goldens,
    );
  }
}

class GridGoldenScene extends StatelessWidget {
  const GridGoldenScene({
    super.key,
    this.background,
    this.spacing = defaultGridSpacing,
    this.itemDecorator,
    required this.goldens,
  });

  final GoldenSceneBackground? background;

  final GridSpacing spacing;

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
        child: Stack(
          children: [
            Positioned.fill(
              child: _buildBackground(context),
            ),
            Padding(
              padding: spacing.around,
              child: _buildGoldens(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoldens() {
    final entries = goldens.entries.toList();

    final rows = <Widget>[];
    for (int row = 0; row < goldens.length / 3; row += 1) {
      final items = <Widget>[];
      for (int col = 0; col < 3; col += 1) {
        final index = row * 3 + col;
        if (index >= entries.length) {
          continue;
        }

        items.add(
          Padding(
            padding: EdgeInsets.only(
              top: row > 0 ? defaultGridSpacing.between : 0,
            ),
            child: Builder(builder: (context) {
              return _decorator(
                context,
                entries[index].key.metadata,
                Image.memory(
                  key: entries[index].value,
                  entries[index].key.pngBytes,
                  width: entries[index].key.size.width,
                  height: entries[index].key.size.height,
                ),
              );
            }),
          ),
        );
      }

      rows.add(
        PixelSnapRow(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          spacing: spacing.between,
          children: items,
        ),
      );
    }

    return PixelSnapColumn(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
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
