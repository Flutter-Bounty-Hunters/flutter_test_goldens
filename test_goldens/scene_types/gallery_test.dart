import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/flutter_test_goldens.dart';

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
                    GoldenImageBounds(
                      child: decorator != null //
                          ? decorator.call(tester, itemWidget)
                          : itemWidget,
                    ),
                  ),
                );
              },
            )
            .renderOrCompareGolden();
      },
    );
  });
}
