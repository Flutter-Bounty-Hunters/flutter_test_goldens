---
title: Animation
navOrder: 10
headerImage: /images/crazy-switch_5-shot.png
---
A Timeline is a Golden Scene, which displays a widget at different points in
time. One use for such a Timeline is to capture individual frames within a widget
animation.

```dart
await Timeline(
    "Crazy Switch - Flip animation",
    fileName: 'crazy-switch_5-shot',
    layout: AnimationTimelineSceneLayout(),
  )
  .setupWithWidget(Padding(
    padding: const EdgeInsets.all(48),
    child: CrazySwitch(),
  ))
  .takePhoto("Off")
  .tap(find.byType(CrazySwitch))
  .takePhotos(3, const Duration(milliseconds: 100))
  .settle()
  .takePhoto("On")
  .run(tester);
```
