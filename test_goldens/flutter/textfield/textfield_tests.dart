import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/flutter_test_goldens.dart';
import 'package:flutter_test_goldens/src/scenes/scene_layout.dart';

import '../flutter_widget_scaffold.dart';

void main() {
  testGoldenSceneOnMac("text field interactions", (tester) async {
    final goldenKey = GlobalKey();

    await FilmStrip(tester)
        .setupWithPump(() {
          return FlutterWidgetScaffold(
            goldenKey: goldenKey,
            child: SizedBox(
              width: 300,
              child: TextField(),
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
        })
        .takePhoto("typed text", find.byKey(goldenKey))
        .renderOrCompareGolden(
          goldenName: "textfield_interactions",
          layout: SceneLayout.column,
        );
  });
}
