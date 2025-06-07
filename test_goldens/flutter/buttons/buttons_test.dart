import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/flutter_test_goldens.dart';
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
        .renderOrCompareGolden(
          goldenName: "button_elevated_interactions",
          layout: SceneLayout.row,
        );
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
        .renderOrCompareGolden(
          goldenName: "button_text_interactions",
          layout: SceneLayout.row,
        );
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
        .renderOrCompareGolden(
          goldenName: "button_icon_interactions",
          layout: SceneLayout.row,
        );
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
        .renderOrCompareGolden(
          goldenName: "button_fab_interactions",
          layout: SceneLayout.row,
        );
  });

  testGoldenSceneOnMac("extended floating action button interactions", (tester) async {
    final goldenKey = GlobalKey();

    final backgroundImageBytes = File("test_goldens/assets/flutter_background.png").readAsBytesSync();
    final imageProvider = MemoryImage(backgroundImageBytes);
    await tester.runAsync(() async {
      await precacheImage(imageProvider, tester.binding.rootElement!);
    });

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
        .renderOrCompareGolden(
          goldenName: "button_extended_fab_interactions",
          layout: SceneLayout.row,
          goldenBackground: Image.memory(
            backgroundImageBytes,
            fit: BoxFit.cover,
          ),
          qrCodeColor: Colors.white,
          qrCodeBackgroundColor: const Color(0xFF035db8),
        );
  });

  testGoldenSceneOnMac("extended floating action button gallery", (tester) async {
    final backgroundImageBytes = File("test_goldens/assets/flutter_background.png").readAsBytesSync();
    final imageProvider = MemoryImage(backgroundImageBytes);
    await tester.runAsync(() async {
      await precacheImage(imageProvider, tester.binding.rootElement!);
    });

    await Gallery(
      tester,
      sceneName: "button_extended_fab_gallery",
      layout: SceneLayout.row,
      itemScaffold: (context, child) {
        return FlutterWidgetScaffold(
          child: child,
        );
      },
      itemDecorator: (context, child) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: child,
        );
      },
      goldenBackground: Image.memory(
        backgroundImageBytes,
        fit: BoxFit.cover,
      ),
      qrCodeColor: Colors.white,
      qrCodeBackgroundColor: const Color(0xFF035db8),
    )
        .itemFromWidget(
          id: "1",
          description: "Icon + Text",
          widget: FloatingActionButton.extended(
            icon: Icon(Icons.edit),
            label: Text("Hello"),
            onPressed: () {},
          ),
        )
        .itemFromWidget(
          id: "2",
          description: "Icon",
          widget: FloatingActionButton.extended(
            icon: Icon(Icons.edit),
            label: Text(""),
            onPressed: () {},
          ),
        )
        .itemFromWidget(
          id: "3",
          description: "Text",
          widget: FloatingActionButton.extended(
            label: Text("Hello"),
            onPressed: () {},
          ),
        )
        .renderOrCompareGolden();
  });
}
