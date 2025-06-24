---
title: Timeline
navOrder: 30
---
A timeline is a Golden Scene, which displays a widget at different points in
time, and possibly across various user interactions.

```dart
await Timeline(
  "Elevated Button Interactions",
  fileName: "button_elevated_interactions",
  layout: RowSceneLayout(),
)
  .setupWithWidget(
    FlutterWidgetScaffold(
      goldenKey: goldenKey,
      child: ElevatedButton(
        onPressed: () {},
        child: Text("Hello"),
      ),
    ),
  )
  .takePhoto("Idle")
  // Screenshot the hovered state.
  .hoverOver(find.byType(ElevatedButton))
  .takePhoto("Hover")
  // Screenshot the pressed state.
  .pressHover()
  .takePhoto("Pressed")
  // Render or compare the scene.
  .run(tester);
```
