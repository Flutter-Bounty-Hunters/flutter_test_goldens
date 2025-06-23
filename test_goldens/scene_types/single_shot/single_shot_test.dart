import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/flutter_test_goldens.dart';

void main() {
  group("Scene types > single-shot >", () {
    testGoldenScene("all defaults", (tester) async {
      await SingleShot(
        "A single-shot scene",
        fileName: "single_shot_scene",
      ) //
          .fromWidget(_content)
          .run(tester);
    });

    testGoldenScene("only scaffolded", (tester) async {
      await SingleShot(
        "A single-shot scene",
        fileName: "single_shot_scene",
      ) //
          .fromWidget(_content)
          .inScaffold(defaultGoldenSceneItemScaffold)
          .run(tester);
    });

    testGoldenScene("only bounds finder", (tester) async {
      await SingleShot(
        "A single-shot scene",
        fileName: "single_shot_scene",
      ) //
          .fromWidget(_content)
          .findBounds(find.byType(GoldenImageBounds))
          .run(tester);
    });

    testGoldenScene("only setup", (tester) async {
      await SingleShot(
        "A single-shot scene",
        fileName: "single_shot_scene",
      ) //
          .fromWidget(_content)
          .withSetup((tester) async {
        // no-op
      }).run(tester);
    });

    testGoldenScene("fully specified", (tester) async {
      await SingleShot(
        "A single-shot scene",
        fileName: "single_shot_scene",
      ) //
          .fromWidget(_content)
          .inScaffold(defaultGoldenSceneItemScaffold)
          .withSetup((tester) async {
            // no-op
          })
          .findBounds(find.byType(GoldenImageBounds))
          .run(tester);
    });

    testGoldenScene("in ./goldens sub-directory", (tester) async {
      await SingleShot(
        "A single-shot scene",
        directory: Directory("goldens"),
        fileName: "single_shot_scene",
      ) //
          .fromWidget(_content)
          .run(tester);
    });
  });
}

const _content = Padding(
  padding: EdgeInsets.all(24),
  child: Text("Hello, World!"),
);
