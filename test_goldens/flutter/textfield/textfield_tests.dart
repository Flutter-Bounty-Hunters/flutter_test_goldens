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
        .takePhoto(find.byKey(goldenKey), "idle")
        .hoverOver(find.byType(TextField))
        .takePhoto(find.byKey(goldenKey), "hover")
        .pressHover()
        .takePhoto(find.byKey(goldenKey), "pressed")
        .releaseHover()
        .takePhoto(find.byKey(goldenKey), "placed caret")
        .modifyScene((tester, testContext) async {
          await tester.enterText(find.byType(TextField), "Hello, world!");
          await tester.pumpAndSettle();
        })
        .takePhoto(find.byKey(goldenKey), "typed text")
        .renderOrCompareGolden(
          goldenName: "textfield_interactions",
          layout: SceneLayout.column,
        );
  });
}
