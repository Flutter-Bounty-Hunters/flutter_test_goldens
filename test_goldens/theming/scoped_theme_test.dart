import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/flutter_test_goldens.dart';
import 'package:golden_bricks/golden_bricks.dart';

void main() {
  group("Theming > theme scopes >", () {
    GoldenSceneTheme.useForGroup(GoldenSceneTheme.current.copyWith(
      itemScaffold: yellowItemScaffold,
      itemDecorator: yellowItemDecorator,
    ));

    testGoldenScene("group scope", (tester) async {
      // This theme should be yellow.
      await SingleShot.fromWidget(
        fileName: "scoped-theme_group-scope",
        description: "Group Scope",
        widget: Text("Hello, World!"),
      ).renderOrCompareGolden(tester);
    });

    testGoldenScene("test scope", (tester) async {
      GoldenSceneTheme.useForTest(GoldenSceneTheme.current.copyWith(
        itemScaffold: redItemScaffold,
        itemDecorator: redItemDecorator,
      ));

      // This theme should be red.
      await SingleShot.fromWidget(
        fileName: "scoped-theme_test-scope",
        description: "Test Scope",
        widget: Text("Hello, World!"),
      ).renderOrCompareGolden(tester);
    });
  });
}

Widget yellowItemScaffold(WidgetTester tester, Widget content) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(builder: (context) {
        return DefaultTextStyle(
          style: DefaultTextStyle.of(context).style.copyWith(
                fontFamily: goldenBricks,
              ),
          child: Center(
            child: GoldenImageBounds(
              child: Container(
                padding: const EdgeInsets.all(24),
                color: Colors.yellow,
                child: content,
              ),
            ),
          ),
        );
      }),
    ),
    debugShowCheckedModeBanner: false,
  );
}

Widget yellowItemDecorator(WidgetTester tester, String description, Widget content) {
  return ColoredBox(
    color: Colors.yellowAccent,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: content,
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            description,
            style: TextStyle(
              color: Colors.black,
              fontFamily: "packages/flutter_test_goldens/OpenSans",
            ),
          ),
        ),
      ],
    ),
  );
}

Widget redItemScaffold(WidgetTester tester, Widget content) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(builder: (context) {
        return DefaultTextStyle(
          style: DefaultTextStyle.of(context).style.copyWith(
                fontFamily: goldenBricks,
              ),
          child: Center(
            child: GoldenImageBounds(
              child: Container(
                padding: const EdgeInsets.all(24),
                color: Colors.red,
                child: content,
              ),
            ),
          ),
        );
      }),
    ),
    debugShowCheckedModeBanner: false,
  );
}

Widget redItemDecorator(WidgetTester tester, String description, Widget content) {
  return ColoredBox(
    color: Colors.redAccent,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: content,
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            description,
            style: TextStyle(
              color: Colors.black,
              fontFamily: "packages/flutter_test_goldens/OpenSans",
            ),
          ),
        ),
      ],
    ),
  );
}
