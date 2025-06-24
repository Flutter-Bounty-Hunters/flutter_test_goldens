import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/flutter_test_goldens.dart';

void main() {
  group("Scene types > gallery > platforms >", () {
    testGoldenScene(
      "on multiple platforms",
      (tester) async {
        await loadMaterialIconsFont();

        await Gallery(
          "Multiple Platforms",
          directory: Directory("."),
          fileName: "gallery_platform_per_item",
          layout: RowSceneLayout(),
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
            .run(tester);
      },
    );

    testGoldenScene("on all platforms", (tester) async {
      await loadMaterialIconsFont();

      await Gallery(
        "All Platforms",
        directory: Directory("."),
        fileName: "gallery_platform_all_platforms",
        layout: RowSceneLayout(),
      )
          .itemFromBuilder(
            id: "1",
            description: "AppBar",
            forEachPlatform: true,
            // Use a builder so that the Icons.adaptive are resolved when the
            // desired platform is applied.
            builder: _buildAppBar,
          )
          .run(tester);
    });
  });
}

Widget _buildAppBar(BuildContext context) {
  return SizedBox(
    width: 350,
    // FIXME: Figure out why this takes up max height without a specified height.
    height: 100,
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
  );
}
