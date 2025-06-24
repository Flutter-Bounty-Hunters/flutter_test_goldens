import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/flutter_test_goldens.dart';

void main() {
  group("Scene types > gallery > golden directory >", () {
    testGoldenScene(
      "in ./goldens sub-directory",
      (tester) async {
        final itemWidget = ElevatedButton(
          onPressed: () {},
          child: Text("A Gallery Item"),
        );

        await Gallery(
          "Golden Sub-Directory",
          directory: Directory("goldens"),
          fileName: "gallery_scene",
          layout: ColumnSceneLayout(),
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
            .run(tester);
      },
    );
  });
}
