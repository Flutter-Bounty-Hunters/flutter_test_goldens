import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/flutter_test_goldens.dart';
import 'package:flutter_test_goldens/src/scenes/single_shot.dart';

void main() {
  group("Scene types > gallery >", () {
    testGoldenScene(
      "item from a widget, builder, and pumper",
      (tester) async {
        await SingleShot.fromWidget(
          tester,
          directory: Directory("."),
          fileName: "single_shot_scene",
          description: "A single-shot scene",
          itemDecorator: (context, child) => Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(width: 5, color: Colors.red),
            ),
            child: child,
          ),
          widget: Text("Hello, world!"),
        ).renderOrCompareGolden();
      },
    );
  });
}
