import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/flutter_test_goldens.dart';
import 'package:flutter_test_goldens/src/scenes/single_shot.dart';

void main() {
  group("Scene types > single-shot >", () {
    testGoldenScene(
      "item from a widget",
      (tester) async {
        await SingleShot.fromWidget(
          fileName: "single_shot_scene",
          description: "A single-shot scene",
          widget: Text("Hello, world!"),
        ).renderOrCompareGolden(tester);
      },
    );
  });
}
