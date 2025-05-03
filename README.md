# Flutter Test Goldens
A toolkit for writing golden tests.

## Getting Started
The following shows an example of how to define a golden test that captures
a variety of independent UIs as a gallery.

```dart
testGoldenSceneOnMac("extended floating action button gallery", (tester) async {
    await Gallery(
      tester,
      itemDecorator: (context, child) {
        return FlutterWidgetScaffold(
          child: child,
        );
      },
      items: [
        GalleryItem.withWidget(
          id: "1",
          description: "Icon + Text",
          child: FloatingActionButton.extended(
            icon: Icon(Icons.edit),
            label: Text("Hello"),
            onPressed: () {},
          ),
        ),
        GalleryItem.withWidget(
          id: "2",
          description: "Icon",
          child: FloatingActionButton.extended(
            icon: Icon(Icons.edit),
            label: Text(""),
            onPressed: () {},
          ),
        ),
        GalleryItem.withWidget(
          id: "3",
          description: "Text",
          child: FloatingActionButton.extended(
            label: Text("Hello"),
            onPressed: () {},
          ),
        ),
      ],
    ).renderOrCompareGolden(
      goldenName: "button_extended_fab_gallery",
      layout: SceneLayout.row,
    );
});
```

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
          layout: SceneLayout.row,
        );
});
```