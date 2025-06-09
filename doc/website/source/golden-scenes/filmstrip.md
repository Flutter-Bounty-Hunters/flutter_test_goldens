---
title: Filmstrip
navOrder: 30
---
A filmstrip is a Golden Scene, which displays a widget at different points in
time, and possibly across various user interactions.

```dart
await FilmStrip(
  tester,
  goldenName: "button_elevated_interactions",
  layout: SceneLayout.row,
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
  .takePhoto("idle")
  // Screenshot the hovered state.
  .hoverOver(find.byType(ElevatedButton))
  .takePhoto("hover")
  // Screenshot the pressed state.
  .pressHover()
  .takePhoto("pressed")
  // Render or compare the scene.
  .renderOrCompareGolden();
```
