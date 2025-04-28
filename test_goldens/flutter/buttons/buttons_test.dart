import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/flutter_test_goldens.dart';
import 'package:flutter_test_goldens/src/flutter/flutter_test_extensions.dart';
import 'package:flutter_test_runners/flutter_test_runners.dart';
import 'package:golden_bricks/golden_bricks.dart';

import '../flutter_widget_scaffold.dart';

void main() {
  testGoldenSceneOnMac("elevated button interactions", (tester) async {
    final goldenKey = GlobalKey();

    await FilmStrip(tester)
        .setupWithPump(() {
          return FlutterWidgetScaffold(
            goldenKey: goldenKey,
            child: ElevatedButton(
              onPressed: () {},
              child: Text("Hello"),
            ),
          );
        })
        .takePhoto(find.byKey(goldenKey), "idle")
        .hoverOver(find.byType(ElevatedButton))
        .takePhoto(find.byKey(goldenKey), "hover")
        .pressHover()
        .takePhoto(find.byKey(goldenKey), "pressed")
        .renderOrCompareGolden("button_elevated_interactions", FilmStripLayout.row);
  });

  testGoldenSceneOnMac("text button interactions", (tester) async {
    final goldenKey = GlobalKey();

    await FilmStrip(tester)
        .setupWithPump(() {
          return FlutterWidgetScaffold(
            goldenKey: goldenKey,
            child: TextButton(
              onPressed: () {},
              child: Text("Hello"),
            ),
          );
        })
        .takePhoto(find.byKey(goldenKey), "idle")
        .hoverOver(find.byType(TextButton))
        .takePhoto(find.byKey(goldenKey), "hover")
        .pressHover()
        .takePhoto(find.byKey(goldenKey), "pressed")
        .renderOrCompareGolden("button_text_interactions", FilmStripLayout.row);
  });

  testGoldenSceneOnMac("icon button interactions", (tester) async {
    final goldenKey = GlobalKey();

    await FilmStrip(tester)
        .setupWithPump(() {
          return MaterialApp(
            theme: ThemeData(
              fontFamily: goldenBricks,
            ),
            home: Scaffold(
              backgroundColor: const Color(0xFF222222),
              body: Padding(
                key: goldenKey,
                padding: const EdgeInsets.all(48),
                child: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {},
                ),
              ),
            ),
          );
        })
        .takePhoto(find.byKey(goldenKey), "idle")
        .hoverOver(find.byType(IconButton))
        .takePhoto(find.byKey(goldenKey), "hover")
        .pressHover()
        .takePhoto(find.byKey(goldenKey), "pressed")
        .renderOrCompareGolden("button_icon_interactions", FilmStripLayout.row);
  });

  testGoldenSceneOnMac("floating action button interactions", (tester) async {
    final goldenKey = GlobalKey();

    await FilmStrip(tester)
        .setupWithPump(() {
          return FlutterWidgetScaffold(
            goldenKey: goldenKey,
            child: FloatingActionButton(
              onPressed: () {},
              child: Icon(Icons.edit),
            ),
          );
        })
        .takePhoto(find.byKey(goldenKey), "idle")
        .hoverOver(find.byType(FloatingActionButton))
        .takePhoto(find.byKey(goldenKey), "hover")
        .pressHover()
        .takePhoto(find.byKey(goldenKey), "pressed")
        .renderOrCompareGolden("button_fab_interactions", FilmStripLayout.row);
  });

  testGoldenSceneOnMac("extended floating action button interactions", (tester) async {
    final goldenKey = GlobalKey();

    await FilmStrip(tester)
        .setupWithPump(() {
          return FlutterWidgetScaffold(
            goldenKey: goldenKey,
            child: FloatingActionButton.extended(
              icon: Icon(Icons.edit),
              label: Text("Hello"),
              onPressed: () {},
            ),
          );
        })
        .takePhoto(find.byKey(goldenKey), "idle")
        // .takePhoto(find.byType(FlutterWidgetScaffold), "idle")

        .hoverOver(find.byType(FloatingActionButton))
        .takePhoto(find.byKey(goldenKey), "hover")
        // .takePhoto(find.byType(FlutterWidgetScaffold), "idle")

        .pressHover()
        .takePhoto(find.byKey(goldenKey), "pressed")
        // .takePhoto(find.byType(FlutterWidgetScaffold), "pressed")
        .renderOrCompareGolden("button_extended_fab_interactions", FilmStripLayout.row);
  });
}
