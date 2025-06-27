---
title: Gallery
navOrder: 20
headerImage: /images/gallery.png
---
A gallery is a Golden Scene, which includes a variety of different widgets
and/or widget configurations.

```dart
await Gallery(
    "Extended FAB",
    fileName: "button_extended_fab_gallery",
    layout: ColumnSceneLayout(),
  )
    .itemFromWidget(
      description: "Icon + Text",
      widget: FloatingActionButton.extended(
        icon: Icon(Icons.edit),
        label: Text("Hello"),
        onPressed: () {},
      ),
    )
    .itemFromWidget(
      description: "Icon",
      widget: FloatingActionButton.extended(
        icon: Icon(Icons.edit),
        label: Text(""),
        onPressed: () {},
      ),
    )
    .itemFromWidget(
      description: "Text",
      widget: FloatingActionButton.extended(
        label: Text("Hello"),
        onPressed: () {},
      ),
    )
    .run(tester);
```
