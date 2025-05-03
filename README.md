# Flutter Test Goldens
A toolkit for writing golden tests.

## Getting Started
The following shows an example of how to define a golden test that captures
screenshots over time, placing all of them in a single scene file.

```dart
testGoldenSceneOnMac("elevated button interactions", (tester) async {
    final goldenKey = GlobalKey();

    await FilmStrip(tester)
        // Setup the widget tree.
        .setupWithPump(() {
          return FlutterWidgetScaffold(
            goldenKey: goldenKey,
            child: ElevatedButton(
              onPressed: () {},
              child: Text("Hello"),
            ),
          );
        })
        // Take a photo.
        .takePhoto(find.byKey(goldenKey), "idle")
        // Adjust the existing widget tree by hovering over the ElevatedButton.
        .hoverOver(find.byType(ElevatedButton))
        // Take a photo.
        .takePhoto(find.byKey(goldenKey), "hover")
        // Adjust the existing widget tree by pressing down at the current offset.
        .pressHover()
        // Take a photo.
        .takePhoto(find.byKey(goldenKey), "pressed")
        // Either stitch the photos into a single scene file, or compare them against
        // an existing scene file.
        .renderOrCompareGolden(
          goldenName: "button_elevated_interactions",
          layout: FilmStripLayout.row,
        );
});
```