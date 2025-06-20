import 'dart:io';

import 'package:file/file.dart' show FileSystem;
import 'package:file/local.dart' show LocalFileSystem;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/flutter_test_goldens.dart';
import 'package:path/path.dart';
import 'package:platform/platform.dart';

void main() {
  group("Scene types > gallery >", () {
    testGoldenScene(
      "item from a widget, builder, and pumper",
      (tester) async {
        final itemWidget = ElevatedButton(
          onPressed: () {},
          child: Text("A Gallery Item"),
        );

        await Gallery(
          tester,
          directory: Directory("."),
          fileName: "gallery_item_from_widget",
          sceneDescription: "Elevated Button",
          layout: SceneLayout.column,
          itemDecorator: (tester, child) {
            return Padding(
              padding: EdgeInsets.all(24),
              child: child,
            );
          },
        )
            .itemFromWidget(
              id: "1",
              description: "widget",
              widget: itemWidget,
            )
            .itemFromBuilder(
              id: "2",
              description: "builder",
              builder: (context) {
                return itemWidget;
              },
            )
            .itemFromPumper(
              id: "2",
              description: "pumper",
              pumper: (tester, scaffold, decorator) async {
                await tester.pumpWidget(
                  scaffold(
                    tester,
                    decorator != null //
                        ? decorator.call(tester, itemWidget)
                        : itemWidget,
                  ),
                );
              },
            )
            .renderOrCompareGolden();
      },
    );

    testGoldenScene(
      "can specify per-item size",
      (tester) async {
        final itemWidget = ElevatedButton(
          onPressed: () {},
          child: Text("A Gallery Item"),
        );

        await Gallery(
          tester,
          directory: Directory("."),
          fileName: "gallery_item_sizes",
          sceneDescription: "Item Sizes",
          layout: SceneLayout.column,
          itemDecorator: (tester, child) {
            return Padding(
              padding: EdgeInsets.all(24),
              child: child,
            );
          },
        )
            .itemFromWidget(
              id: "1",
              description: "150x100",
              constraints: BoxConstraints.tightFor(width: 150, height: 100),
              widget: itemWidget,
            )
            .itemFromWidget(
              id: "2",
              description: "200x150",
              constraints: BoxConstraints.tightFor(width: 200, height: 150),
              widget: itemWidget,
            )
            .itemFromWidget(
              id: "3",
              description: "250x200",
              constraints: BoxConstraints.tightFor(width: 250, height: 200),
              widget: itemWidget,
            )
            .renderOrCompareGolden();
      },
    );

    testGoldenScene(
      "on multiple platforms",
      (tester) async {
        await _loadIconFont();

        await Gallery(
          tester,
          directory: Directory("."),
          fileName: "multiple_platforms",
          sceneDescription: "Multiple Platforms",
          layout: SceneLayout.row,
          itemDecorator: (tester, child) {
            return Padding(
              padding: EdgeInsets.all(24),
              child: child,
            );
          },
        )
            .itemFromBuilder(
              id: "1",
              description: "AppBar (Android)",
              platform: TargetPlatform.android,
              // Use a builder so that the Icons.adaptive are resolved when the
              // desired platform is applied.
              builder: _buildAppBar,
            )
            .itemFromBuilder(
              id: "2",
              description: "AppBar (iOS)",
              platform: TargetPlatform.iOS,
              // Use a builder so that the Icons.adaptive are resolved when the
              // desired platform is applied.
              builder: _buildAppBar,
            )
            .renderOrCompareGolden();
      },
    );

    testGoldenScene("on all platforms", (tester) async {
      await _loadIconFont();

      await Gallery(
        tester,
        directory: Directory("."),
        fileName: "all_platforms",
        sceneDescription: "All Platforms",
        layout: SceneLayout.row,
        itemDecorator: (tester, child) {
          return Padding(
            padding: EdgeInsets.all(24),
            child: child,
          );
        },
      )
          .itemFromBuilder(
            id: "1",
            description: "AppBar",
            forEachPlatform: true,
            // Use a builder so that the Icons.adaptive are resolved when the
            // desired platform is applied.
            builder: _buildAppBar,
          )
          .renderOrCompareGolden();
    });

    testGoldenScene(
      "in ./goldens sub-directory",
      (tester) async {
        final itemWidget = ElevatedButton(
          onPressed: () {},
          child: Text("A Gallery Item"),
        );

        await Gallery(
          tester,
          directory: Directory("goldens"),
          fileName: "gallery_scene",
          sceneDescription: "Golden Sub-Directory",
          layout: SceneLayout.column,
          itemDecorator: (tester, child) {
            return Padding(
              padding: EdgeInsets.all(24),
              child: child,
            );
          },
        )
            .itemFromWidget(
              id: "1",
              description: "First",
              widget: itemWidget,
            )
            .itemFromWidget(
              id: "2",
              description: "Second",
              widget: itemWidget,
            )
            .itemFromWidget(
              id: "3",
              description: "Third",
              widget: itemWidget,
            )
            .renderOrCompareGolden();
      },
    );
  });
}

Widget _buildAppBar(BuildContext context) {
  return SizedBox(
    width: 350,
    // FIXME: Figure out why this takes max height without a specified height.
    height: 100,
    child: ColoredBox(
      color: Colors.red,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Title"),
          leading: Icon(Icons.adaptive.arrow_back),
          actions: [
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.adaptive.more),
            ),
          ],
          backgroundColor: Colors.blue,
        ),
        body: SizedBox.fromSize(size: Size.zero),
      ),
    ),
  );
}

Future<void> _loadIconFont() async {
  const FileSystem fs = LocalFileSystem();
  const Platform platform = LocalPlatform();
  final Directory flutterRoot = fs.directory(platform.environment['FLUTTER_ROOT']);

  final File iconFont = flutterRoot.childFile(
    fs.path.join(
      'bin',
      'cache',
      'artifacts',
      'material_fonts',
      'MaterialIcons-Regular.otf',
    ),
  );

  final Future<ByteData> bytes = Future<ByteData>.value(iconFont.readAsBytesSync().buffer.asByteData());

  await (FontLoader('MaterialIcons')..addFont(bytes)).load();
}

extension on Directory {
  File childFile(String basename) => File("$path$separator$basename");
}
