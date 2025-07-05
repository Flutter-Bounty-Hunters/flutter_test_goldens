import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
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
    Map<GoldenSceneScreenshot, GlobalKey<State<StatefulWidget>>> goldens,
  ) {
    return GridGoldenScene(
      background: background,
      spacing: spacing,
      itemDecorator: itemDecorator,
      goldens: goldens,
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
    final entries = goldens.entries.toList();

    final rows = <TableRow>[];
    for (int row = 0; row < goldens.length / 3; row += 1) {
      final items = <Widget>[];
      for (int col = 0; col < 3; col += 1) {
        final index = row * 3 + col;
        if (index >= entries.length) {
          items.add(const SizedBox());
          continue;
        }

        items.add(
          Padding(
            padding: EdgeInsets.only(
              top: row > 0 ? defaultGridSpacing.between : 0,
              left: col > 0 ? defaultGridSpacing.between : 0,
            ),
            child: _buildItem(
              context,
              entries[index].key.metadata,
              Image.memory(
                key: entries[index].value,
                entries[index].key.pngBytes,
                width: entries[index].key.size.width,
                height: entries[index].key.size.height,
              ),
            ),
          ),
        );
      }

      rows.add(
        TableRow(
          children: items,
        ),
      );
    }

    return DefaultTextStyle(
      style: GoldenSceneTheme.current.defaultTextStyle,
      child: GoldenSceneBounds(
        child: ColoredBox(
          color: Colors.white,
          child: Padding(
            padding: spacing.around,
            child: Table(
              defaultColumnWidth: IntrinsicColumnWidth(),
              children: rows,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, GoldenScreenshotMetadata metadata, Widget content) {
    if (itemDecorator == null) {
      return content;
    }

    return itemDecorator!(context, metadata, content);
  }
}
