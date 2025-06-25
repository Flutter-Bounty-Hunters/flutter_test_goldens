import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/flutter_test_goldens.dart';
import 'package:golden_bricks/golden_bricks.dart';

import '../flutter_widget_scaffold.dart';

void main() {
  testGoldenSceneOnMac("elevated button interactions", (tester) async {
    final goldenKey = GlobalKey();

    await Timeline(
      "ElevatedButton Interactions",
      fileName: "button_elevated_interactions",
      layout: RowSceneLayout(),
    )
        .setupWithPump(() {
          return FlutterWidgetScaffold(
            goldenKey: goldenKey,
            child: ElevatedButton(
              onPressed: () {},
              child: Text("Hello"),
            ),
          );
        })
        .takePhoto("idle", find.byKey(goldenKey))
        .hoverOver(find.byType(ElevatedButton))
        .takePhoto("hover", find.byKey(goldenKey))
        .pressHover()
        .takePhoto("pressed", find.byKey(goldenKey))
        .run(tester);
  });

  testGoldenSceneOnMac("text button interactions", (tester) async {
    final goldenKey = GlobalKey();

    await Timeline(
      "TextButton Interactions",
      fileName: "button_text_interactions",
      layout: RowSceneLayout(),
    )
        .setupWithPump(() {
          return FlutterWidgetScaffold(
            goldenKey: goldenKey,
            child: TextButton(
              onPressed: () {},
              child: Text("Hello"),
            ),
          );
        })
        .takePhoto("idle", find.byKey(goldenKey))
        .hoverOver(find.byType(TextButton))
        .takePhoto("hover", find.byKey(goldenKey))
        .pressHover()
        .takePhoto("pressed", find.byKey(goldenKey))
        .run(tester);
  });

  testGoldenSceneOnMac("icon button interactions", (tester) async {
    final goldenKey = GlobalKey();

    await Timeline(
      "IconButton Interactions",
      fileName: "button_icon_interactions",
      layout: RowSceneLayout(),
    )
        .setupWithPump(() {
          return MaterialApp(
            theme: ThemeData(
              fontFamily: goldenBricks,
            ),
            home: Scaffold(
              backgroundColor: Colors.white,
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
        .takePhoto("idle", find.byKey(goldenKey))
        .hoverOver(find.byType(IconButton))
        .takePhoto("hover", find.byKey(goldenKey))
        .pressHover()
        .takePhoto("pressed", find.byKey(goldenKey))
        .run(tester);
  });

  testGoldenSceneOnMac("floating action button interactions", (tester) async {
    final goldenKey = GlobalKey();

    await Timeline(
      "FAB Interactions",
      fileName: "button_fab_interactions",
      layout: RowSceneLayout(),
    )
        .setupWithPump(() {
          return FlutterWidgetScaffold(
            goldenKey: goldenKey,
            child: FloatingActionButton(
              onPressed: () {},
              child: Icon(Icons.edit),
            ),
          );
        })
        .takePhoto("idle", find.byKey(goldenKey))
        .hoverOver(find.byType(FloatingActionButton))
        .takePhoto("hover", find.byKey(goldenKey))
        .pressHover()
        .takePhoto("pressed", find.byKey(goldenKey))
        .run(tester);
  });

  testGoldenSceneOnMac("extended floating action button interactions", (tester) async {
    final goldenKey = GlobalKey();
    final image = await tester.loadImageFromFile("test_goldens/assets/flutter_background.png");

    await Timeline(
      "Extended FAB Interactions",
      fileName: "button_extended_fab_interactions",
      layout: RowSceneLayout(),
      goldenBackground: GoldenSceneBackground.widget(
        Image.memory(
          image.bytes,
          fit: BoxFit.cover,
        ),
      ),
    )
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
        .takePhoto("idle", find.byKey(goldenKey))
        .hoverOver(find.byType(FloatingActionButton))
        .takePhoto("hover", find.byKey(goldenKey))
        .pressHover()
        .takePhoto("pressed", find.byKey(goldenKey))
        .run(tester);
  });

  testGoldenSceneOnMac("extended floating action button gallery", (tester) async {
    // TODO: We lost the golden background while refactoring. Bring this back somewhere.
    // final image = await tester.loadImageFromFile("test_goldens/assets/flutter_background.png");

    await Gallery(
      "FAB Gallery",
      fileName: "button_extended_fab_gallery",
      layout: RowSceneLayout(),
      itemScaffold: (context, child) {
        return FlutterWidgetScaffold(
          child: child,
        );
      },
      // TODO: We lost the golden background while refactoring. Bring this back somewhere.
      // goldenBackground: GoldenSceneBackground.widget(Image.memory(
      //   image.bytes,
      //   fit: BoxFit.cover,
      // )),
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
        .run(tester);
  });
}
