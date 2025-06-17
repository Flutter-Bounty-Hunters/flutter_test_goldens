import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/flutter_test_goldens.dart';

void main() {
  group("Theming > brightness >", () {
    testGoldenScene("light", (tester) async {
      testGoldenScene("group scope", (tester) async {
        await SingleShot.fromWidget(
          fileName: "scoped-theme_group-scope",
          description: "Light Theme",
          widget: Text("Hello, World!"),
        ).renderOrCompareGolden(tester);
      });
    });

    testGoldenScene("dark", (tester) async {
      await SingleShot.fromWidget(
        fileName: "scoped-theme_group-scope",
        description: "Dark Theme",
        widget: Text("Hello, World!"),
      ).renderOrCompareGolden(tester);
    });
  });
}
