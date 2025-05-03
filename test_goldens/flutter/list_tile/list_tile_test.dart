import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/flutter_test_goldens.dart';
import 'package:flutter_test_goldens/src/scenes/scene_layout.dart';

import '../flutter_widget_scaffold.dart';

void main() {
  testGoldenSceneOnMac("list tile interactions", (tester) async {
    await TestFonts.loadAppFonts();

    final goldenKey = GlobalKey();

    await FilmStrip(tester)
        .setupWithPump(() {
          return FlutterWidgetScaffold(
            goldenKey: goldenKey,
            child: SizedBox(
              width: 400,
              child: ListTile(
                title: Text("Flutter Test Goldens"),
                subtitle: Text("The best tool for golden tests"),
                trailing: Icon(Icons.chevron_right),
                tileColor: Colors.white,
                hoverColor: Colors.blue,
                onTap: () {},
              ),
            ),
          );
        })
        .takePhoto(find.byKey(goldenKey), "idle")
        .hoverOver(find.byType(ListTile))
        .takePhoto(find.byKey(goldenKey), "hover")
        .pressHover()
        .takePhoto(find.byKey(goldenKey), "pressed")
        .renderOrCompareGolden(
          goldenName: "list_tile_interactions",
          layout: SceneLayout.column,
        );
  });
}
