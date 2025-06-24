import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test_goldens/flutter_test_goldens.dart';
import 'package:flutter_test_goldens/golden_bricks.dart';

void main() {
  testGoldenScene('reports multiple failures', (tester) async {
    await Gallery(
      "Example with multiple failures",
      directory: Directory("./goldens"),
      fileName: "multiple_failures",
      layout: ColumnSceneLayout(),
    )
        .itemFromWidget(
          id: '1',
          description: 'Android caret',
          // Use _buildGoldenRectangle to build the original golden rectangle.
          // widget: _buildGoldenRectangle(),
          widget: _buildMismatchRectangle(),
        )
        .itemFromWidget(
          id: '2',
          description: 'Android drag handles',
          widget: Container(
            width: 150,
            height: 100,
            color: Colors.green,
          ),
        )
        .itemFromWidget(
          id: '3',
          description: 'Hint text',
          // Use _buildGoldenText to build the original golden text.
          // widget: _buildGoldenRectangle(),
          widget: _buildMismatchText(),
        )
        // Comment this out when comparing goldens.
        // .itemFromWidget(
        //   id: '4',
        //   description: 'iOS caret',
        //   widget: _buildGoldenRectangle(),
        // )
        // Comment this out when generating goldens.
        .itemFromWidget(
          id: '5',
          description: 'iOS drag handles',
          widget: _buildGoldenRectangle(),
        )
        .run(tester);
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
