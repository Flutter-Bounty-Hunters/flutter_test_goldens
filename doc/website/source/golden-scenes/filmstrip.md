---
title: Filmstrip
navOrder: 2
---
A filmstrip is a golden scene, which displays a widget at different points in
time, and possibly across various user interactions.

```dart
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
```
