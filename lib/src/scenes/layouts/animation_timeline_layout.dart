import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/src/fonts/fonts.dart';
import 'package:flutter_test_goldens/src/goldens/golden_collections.dart';
import 'package:flutter_test_goldens/src/goldens/golden_rendering.dart';
import 'package:flutter_test_goldens/src/scenes/golden_scene.dart';
import 'package:flutter_test_goldens/src/scenes/scene_layout.dart';

class AnimationTimelineSceneLayout implements SceneLayout {
  const AnimationTimelineSceneLayout({
    this.background = const GoldenSceneBackground.color(Color(0xff020817)),
    this.spacing = defaultGridSpacing,
    this.itemDecorator,
    this.rowBreakPolicy,
  });

  final GoldenSceneBackground? background;

  final GridSpacing spacing;

  /// A decoration built around each screenshot in the final scene.
  ///
  /// This decorator has no impact when building new screenshot widget trees, it
  /// only impacts the final painted scene, after the screenshots have been taken.
  final GoldenSceneItemDecorator? itemDecorator;

  /// An optional policy for where to break rows in the layout, or `null` to use a single row.
  final AnimationTimelineRowBreak? rowBreakPolicy;

  @override
  Widget build(
    WidgetTester tester,
    BuildContext context,
    SceneLayoutContent content,
  ) {
    return AnimationTimelineGoldenScene(
      background: background,
      spacing: spacing,
      itemDecorator: itemDecorator,
      content: content,
      rowBreakPolicy: rowBreakPolicy,
    );
  }
}

/// Policy for where to break rows in an [AnimationTimeline].
class AnimationTimelineRowBreak {
  /// Breaks rows after a maximum number of columns of items.
  const AnimationTimelineRowBreak.afterMaxColumnCount(this.maxColumnCount)
      : beforeItemDescription = null,
        afterItemDescription = null;

  /// Breaks rows before each item with the given description.
  const AnimationTimelineRowBreak.beforeItemDescription(this.beforeItemDescription)
      : maxColumnCount = null,
        afterItemDescription = null;

  /// Breaks rows after each item with the given description.
  const AnimationTimelineRowBreak.afterItemDescription(this.afterItemDescription)
      : beforeItemDescription = null,
        maxColumnCount = null;

  final int? maxColumnCount;
  final String? beforeItemDescription;
  final String? afterItemDescription;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnimationTimelineRowBreak &&
          runtimeType == other.runtimeType &&
          maxColumnCount == other.maxColumnCount &&
          beforeItemDescription == other.beforeItemDescription &&
          afterItemDescription == other.afterItemDescription;

  @override
  int get hashCode => maxColumnCount.hashCode ^ beforeItemDescription.hashCode ^ afterItemDescription.hashCode;
}

class AnimationTimelineGoldenScene extends StatelessWidget {
  const AnimationTimelineGoldenScene({
    super.key,
    this.background,
    this.spacing = defaultGridSpacing,
    this.itemDecorator,
    required this.content,
    this.rowBreakPolicy,
  });

  final GridSpacing spacing;

  final GoldenSceneBackground? background;

  /// A decoration built around each screenshot in the final scene.
  ///
  /// This decorator has no impact when building new screenshot widget trees, it
  /// only impacts the final painted scene, after the screenshots have been taken.
  final GoldenSceneItemDecorator? itemDecorator;

  final SceneLayoutContent content;

  final AnimationTimelineRowBreak? rowBreakPolicy;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: GoldenSceneTheme.current.defaultTextStyle.copyWith(
        color: _accentColor,
      ),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "ANIMATION TIMELINE",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
            ),
          ),
          if (content.description != null && content.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              content.description!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                letterSpacing: 2,
              ),
            ),
          ],
          const SizedBox(height: 24),
          _buildRows(),
        ],
      ),
    );
  }

  Widget _buildRows() {
    final itemRows = _breakDownRows();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: spacing.between,
      children: [
        for (final row in itemRows) //
          _buildRow(row),
      ],
    );
  }

  List<List<MapEntry<GoldenSceneScreenshot, GlobalKey>>> _breakDownRows() {
    final rowBreakPolicy = this.rowBreakPolicy;
    if (rowBreakPolicy == null) {
      return [content.goldens.entries.toList()];
    }

    var allItems = content.goldens.entries.toList(growable: true);
    final itemRows = <List<MapEntry<GoldenSceneScreenshot, GlobalKey>>>[];

    if (rowBreakPolicy.maxColumnCount != null) {
      // Break after a max column count.
      while (allItems.isNotEmpty) {
        final end = min(rowBreakPolicy.maxColumnCount!, allItems.length);
        itemRows.add(
          allItems.sublist(0, end),
        );
        if (end < allItems.length) {
          allItems = allItems.sublist(end);
        } else {
          allItems = [];
        }
      }
      return itemRows;
    }

    final beforeItemDescription = rowBreakPolicy.beforeItemDescription;
    if (beforeItemDescription != null) {
      var row = <MapEntry<GoldenSceneScreenshot, GlobalKey>>[];
      for (int i = 0; i < allItems.length; i += 1) {
        final screenshot = allItems[i].key;
        if (screenshot.metadata.description == beforeItemDescription && row.isNotEmpty) {
          itemRows.add(row);
          row = <MapEntry<GoldenSceneScreenshot, GlobalKey>>[];
        }
        row.add(allItems[i]);
      }
      if (row.isNotEmpty) {
        // Add the final row to the list of rows.
        itemRows.add(row);
      }

      return itemRows;
    }

    final afterItemDescription = rowBreakPolicy.afterItemDescription;
    if (afterItemDescription != null) {
      var row = <MapEntry<GoldenSceneScreenshot, GlobalKey>>[];
      for (int i = 0; i < allItems.length; i += 1) {
        row.add(allItems[i]);

        final screenshot = allItems[i].key;
        if (screenshot.metadata.description == afterItemDescription && row.isNotEmpty) {
          itemRows.add(row);
          row = <MapEntry<GoldenSceneScreenshot, GlobalKey>>[];
        }
      }
      if (row.isNotEmpty) {
        // Add the final row to the list of rows.
        itemRows.add(row);
      }

      return itemRows;
    }

    throw Exception("Unhandled row break policy: $rowBreakPolicy");
  }

  Widget _buildRow(List<MapEntry<GoldenSceneScreenshot, GlobalKey>> items) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          spacing: spacing.between,
          children: [
            for (final entry in items) //
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  Center(
                    child: Container(
                      width: 2,
                      height: 20,
                      color: _accentColor,
                    ),
                  ),
                ],
              ),
          ],
        ),
        Divider(height: 2, thickness: 2, color: _accentColor),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              "Start >",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Spacer(),
            Text(
              "> End",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _decorator(BuildContext context, GoldenScreenshotMetadata metadata, Widget child) {
    // TODO: bring back configurable item decorator
    final itemDecorator = _itemDecorator; // this.itemDecorator ?? GoldenSceneTheme.current.itemDecorator;
    return itemDecorator(context, metadata, child);
  }

  Widget _buildBackground(BuildContext context) {
    return (background ?? GoldenSceneTheme.current.background).build(context);
  }
}

const _accentColor = Color(0xff1e293b);

Widget _itemDecorator(
  BuildContext context,
  GoldenScreenshotMetadata metadata,
  Widget content,
) {
  return ColoredBox(
    color: const Color(0xff020817),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        content,
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            metadata.description,
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: TestFonts.openSans, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}
