import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/flutter_test_goldens.dart';

void main() {
  group("Scene types > gallery > source content >", () {
    testGoldenScene(
      "item from a widget, builder, and pumper",
      (tester) async {
        final itemWidget = ElevatedButton(
          onPressed: () {},
          child: Text("A Gallery Item"),
        );

        await Gallery(
          "Elevated Button",
          directory: Directory("."),
          fileName: "gallery_pumper_builder_widget_creation",
          layout: ColumnSceneLayout(),
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
              id: "3",
              description: "pumper",
              pumper: (tester, scaffold, description) async {
                await tester.pumpWidget(
                  scaffold(tester, itemWidget),
                );
              },
            )
            .run(tester);
      },
    );
  });
}
