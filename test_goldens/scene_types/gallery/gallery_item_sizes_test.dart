import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/flutter_test_goldens.dart';

void main() {
  group("Scene types > gallery >", () {
    testGoldenScene(
      "can specify per-item size",
      (tester) async {
        final itemWidget = ElevatedButton(
          onPressed: () {},
          child: Text("A Gallery Item"),
        );

        await Gallery(
          "Item Sizes",
          directory: Directory("."),
          fileName: "gallery_item_sizes",
          layout: ColumnSceneLayout(),
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
            .run(tester);
      },
    );
  });
}
