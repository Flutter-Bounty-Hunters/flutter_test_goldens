import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/flutter_test_goldens.dart';

void main() {
  group("Scene types > gallery >", () {
    testGoldenScene(
      "grid",
      (tester) async {
        await Gallery(
          "Grid Layout",
          directory: Directory("."),
          fileName: "gallery_grid_layout",
          layout: GridGoldenSceneLayout(),
        )
            .itemFromWidget(
              description: "Red",
              widget: _buildItem(Colors.red),
            )
            .itemFromWidget(
              description: "Orange",
              widget: _buildItem(Colors.orange),
            )
            .itemFromWidget(
              description: "Yellow",
              widget: _buildItem(Colors.yellow),
            )
            .itemFromWidget(
              description: "Green",
              widget: _buildItem(Colors.green),
            )
            .itemFromWidget(
              description: "Blue",
              widget: _buildItem(Colors.blue),
            )
            .itemFromWidget(
              description: "Indigo",
              widget: _buildItem(Colors.indigo),
            )
            .itemFromWidget(
              description: "Violet",
              widget: _buildItem(Colors.purple),
            )
            .run(tester);
      },
    );
  });
}

Widget _buildItem(Color color) {
  return SizedBox(
    width: 100,
    height: 100,
    child: PixelSnapCenter(
      child: Container(
        width: 50,
        height: 50,
        color: color,
      ),
    ),
  );
}
