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
          .fromWidget(Text("Hello, world!"))
          .run(tester);
    });

    testGoldenScene("only decorated", (tester) async {
      await SingleShot(
        "A single-shot scene",
        fileName: "single_shot_scene",
      ) //
          .fromWidget(Text("Hello, world!"))
          .withDecoration(defaultGoldenSceneItemDecorator)
          .run(tester);
    });

    testGoldenScene("only scaffolded", (tester) async {
      await SingleShot(
        "A single-shot scene",
        fileName: "single_shot_scene",
      ) //
          .fromWidget(Text("Hello, world!"))
          .inScaffold(defaultGoldenSceneItemScaffold)
          .run(tester);
    });

    testGoldenScene("only bounds finder", (tester) async {
      await SingleShot(
        "A single-shot scene",
        fileName: "single_shot_scene",
      ) //
          .fromWidget(Text("Hello, world!"))
          .findBounds(find.byType(GoldenImageBounds))
          .run(tester);
    });

    testGoldenScene("only setup", (tester) async {
      await SingleShot(
        "A single-shot scene",
        fileName: "single_shot_scene",
      ) //
          .fromWidget(Text("Hello, world!"))
          .withSetup((tester) async {
        // no-op
      }).run(tester);
    });

    testGoldenScene("fully specified", (tester) async {
      await SingleShot(
        "A single-shot scene",
        fileName: "single_shot_scene",
      ) //
          .fromWidget(Text("Hello, world!"))
          .withDecoration(defaultGoldenSceneItemDecorator)
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
          .fromWidget(Text("Hello, world!"))
          .run(tester);
    });

    testGoldenScene(
      "with a red border",
      (tester) async {
        await SingleShot(
          "With a red border",
          fileName: "single_shot_scene_with_red_border",
        )
            .fromWidget(
              Text("Hello, world!"),
            )
            .withDecoration(
              (context, description, child) => Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border.all(width: 5, color: Colors.red),
                ),
                child: child,
              ),
            )
            .run(tester);
      },
    );
  });
}
