---
title: Gallery
navOrder: 20
---
A gallery is a Golden Scene, which includes a variety of different widgets
and/or widget configurations.

```dart
await Gallery(
    tester,
    sceneName: "button_extended_fab_gallery",
    layout: SceneLayout.row,
    itemDecorator: (context, child) {
      return FlutterWidgetScaffold(
        child: child,
      );
    },
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
```
