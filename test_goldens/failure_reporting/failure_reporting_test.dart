import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test_goldens/flutter_test_goldens.dart';
import 'package:flutter_test_goldens/golden_bricks.dart';

void main() {
  testGoldenScene('reports multiple failures', (tester) async {
    await Gallery(
      tester,
      directory: Directory("./goldens"),
      fileName: "multiple_failures",
      sceneDescription: "Example with multiple failures",
      layout: SceneLayout.column,
    )
        .itemFromWidget(
          id: '1',
          description: 'Red Rectangle',
          // Use _buildGoldenRectangle to build the original golden rectangle.
          widget: _buildMismatchRectangle(),
        )
        .itemFromWidget(
          id: '2',
          description: 'A golden that passes',
          widget: Container(
            width: 150,
            height: 100,
            color: Colors.green,
          ),
        )
        .itemFromWidget(
          id: '3',
          description: 'A text',
          // Use _buildGoldenText to build the original golden text.
          widget: _buildMismatchText(),
        )
        // The following item is present in the golden file.
        // .itemFromWidget(
        //   id: '4',
        //   description: 'Another Red Rectangle',
        //   widget: _buildGoldenRectangle(),
        // )
        // The following item is not present in the golden file.
        .itemFromWidget(
          id: '5',
          description: 'An unexpected Rectangle',
          widget: _buildGoldenRectangle(),
        )
        .renderOrCompareGolden();
  });
}

/// The widget used to build the original golden rectangle.
Widget _buildGoldenRectangle() {
  return Container(
    width: 150,
    height: 100,
    color: Colors.red,
  );
}

/// The widget used to build the mismatch rectangle.
///
/// It has the same same size as the golden rectangle but a different color.
Widget _buildMismatchRectangle() {
  return Container(
    width: 150,
    height: 100,
    color: Colors.green,
  );
}

/// The widget used to build the original golden text.
// ignore: unused_element
Widget _buildGoldenText() {
  return Text(
    'A text widget',
    style: TextStyle(
      fontFamily: goldenBricks,
    ),
  );
}

/// The widget used to build the mismatch golden text.
///
/// It has the same text but all uppercase.
Widget _buildMismatchText() {
  return Text(
    'A TEXT WIDGET',
    style: TextStyle(
      fontFamily: goldenBricks,
    ),
  );
}
