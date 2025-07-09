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
      await SingleShot("Group Scope", fileName: "scoped-theme_group-scope")
          .fromWidget(
            Text("Hello, World!"),
          )
          .run(tester);
    });

    testGoldenScene("test scope", (tester) async {
      GoldenSceneTheme.useForTest(GoldenSceneTheme.current.copyWith(
        itemScaffold: redItemScaffold,
        itemDecorator: redItemDecorator,
      ));

      // This theme should be red.
      await SingleShot("Test Scope", fileName: "scoped-theme_test-scope")
          .fromWidget(
            Text("Hello, World!"),
          )
          .run(tester);
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

Widget yellowItemDecorator(BuildContext context, GoldenScreenshotMetadata metadata, Widget content) {
  return PixelSnapColumn(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        color: Colors.yellowAccent,
        padding: const EdgeInsets.all(24),
        child: content,
      ),
      Container(
        color: Colors.white,
        padding: const EdgeInsets.all(24),
        child: Text(
          metadata.description,
          textAlign: TextAlign.center,
        ),
      ),
    ],
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

Widget redItemDecorator(BuildContext context, GoldenScreenshotMetadata metadata, Widget content) {
  return PixelSnapColumn(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        color: Colors.redAccent,
        padding: const EdgeInsets.all(24),
        child: content,
      ),
      Container(
        color: Colors.white,
        padding: const EdgeInsets.all(24),
        child: Text(
          metadata.description,
          textAlign: TextAlign.center,
        ),
      ),
    ],
  );
}
