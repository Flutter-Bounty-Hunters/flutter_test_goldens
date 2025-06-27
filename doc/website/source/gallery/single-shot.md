---
title: Single Shot
navOrder: 10
headerImage: /images/single_shot_website_header.png
---
A "single shot" is a gallery that displays only one golden image. Most golden use-cases
involve multiple related golden images, but sometimes you only need one. That's when you
should use a `SingleShot`.

```dart
void main() {
  testGoldenScene("Calendar", (tester) async {
    await SingleShot("Calendar", fileName: "shadcn-calendar") //
        .fromWidget(ShadCalendar())
        .inScaffold(shadcnItemScaffold)
        .withLayout(ShadcnSingleShotSceneLayout(
          shadcnWordmarkProvider: shadcnWordmarkProvider,
        ))
        .run(tester);   
  });
}
```
