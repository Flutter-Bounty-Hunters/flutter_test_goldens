import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/flutter_test_goldens.dart';

import '../flutter_widget_scaffold.dart';

void main() {
  testGoldenSceneOnMac("text field interactions", (tester) async {
    final goldenKey = GlobalKey();

    await Timeline(
      "TextField Interactions",
      fileName: "textfield_interactions",
      layout: ColumnSceneLayout(),
    )
        .setupWithBuilder(() {
          return FlutterWidgetScaffold(
            goldenKey: goldenKey,
            child: SizedBox(
              width: 300,
              child: TextField(
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
            ),
          );
        })
        .takePhoto("idle", find.byKey(goldenKey))
        .hoverOver(find.byType(TextField))
        .takePhoto("hover", find.byKey(goldenKey))
        .pressHover()
        .takePhoto("pressed", find.byKey(goldenKey))
        .releaseHover()
        .takePhoto("placed caret", find.byKey(goldenKey))
        .modifyScene((tester, testContext) async {
          await tester.enterText(find.byType(TextField), "Hello, world!");
          await tester.pumpAndSettle();

          expect(find.byKey(goldenKey), findsOne);
          expect(find.byType(TextField), findsOne);
          expect(find.text("Hello, world!"), findsOne);
        })
        .takePhoto("typed text", find.byKey(goldenKey))
        .run(tester);
  });
}
