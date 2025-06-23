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
          _buildItem(
            context,
            entries[index].key.metadata,
            Image.memory(
              key: entries[index].value,
              entries[index].key.pngBytes,
              width: entries[index].key.size.width,
              height: entries[index].key.size.height,
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
          child: Table(
            defaultColumnWidth: IntrinsicColumnWidth(),
            children: rows,
          ),
          // child: ConstrainedBox(
          //   constraints: BoxConstraints(maxWidth: maxWidth),
          //   // ^ We have to constrain the width due to the vertical scrolling viewport in the
          //   //   the GridView.
          //   // TODO: Use some other grid implementation that doesn't include scrolling.
          //   child: GridView(
          //     gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          //       mainAxisSpacing: 0,
          //       crossAxisCount: 3,
          //       crossAxisSpacing: 0,
          //     ),
          //     shrinkWrap: true,
          //     padding: const EdgeInsets.all(0),
          //     children: [
          //       for (final entry in goldens.entries)
          //         ColoredBox(
          //           color: Colors.green,
          //           child: Image.memory(
          //             key: entry.value,
          //             entry.key.pngBytes,
          //             width: entry.key.size.width,
          //             height: entry.key.size.height,
          //           ),
          //         ),
          //     ],
          //   ),
          // ),
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
