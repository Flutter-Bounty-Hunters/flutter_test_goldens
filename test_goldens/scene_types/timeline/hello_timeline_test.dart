import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/flutter_test_goldens.dart';

void main() {
  group("Timeline >", () {
    testGoldenScene("hello world", (tester) async {
      await Timeline(
        "Hello, Timeline!",
        fileName: "hello_timeline",
        layout: ColumnSceneLayout(),
      )
          .setupWithWidget(
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed: () {},
                child: Text("Click Me!"),
              ),
            ),
          )
          .takePhoto("Idle")
          .hoverOver(find.byType(ElevatedButton))
          .takePhoto("Hovering")
          .pressHover()
          .takePhoto("Pressed")
          .run(tester);
    });
  });
}
