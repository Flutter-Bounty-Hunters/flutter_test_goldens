import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/flutter_test_goldens.dart';

void main() {
  group("Theming > brightness >", () {
    testGoldenScene("light", (tester) async {
      testGoldenScene("group scope", (tester) async {
        await SingleShot("Light Theme", fileName: "scoped-theme_group-scope")
            .fromWidget(
              Text("Hello, World!"),
            )
            .run(tester);
      });
    });

    testGoldenScene("dark", (tester) async {
      await SingleShot("Dark Theme", fileName: "scoped-theme_group-scope")
          .fromWidget(
            Text("Hello, World!"),
          )
          .run(tester);
    });
  });
}
