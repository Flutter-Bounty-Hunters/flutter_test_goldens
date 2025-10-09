---
title: Test Runners
---
Test runners are the methods that are used to declare and define tests. Typically,
golden tests are defined with the `testWidgets()` test runner. However, `flutter_test_goldens`
comes with its own test runners for convenience, e.g., `testGoldenScene()`.

## The Standard Test Runner
The standard test runner in `flutter_test_goldens` is `testGoldenScene()`.

```dart
void main() {
  testGoldenScene("my golden test", (tester) async {
    // TODO: implement golden test.
  });
}
```

The `testGoldenScene()` test runner wraps around Flutter's standard `testWidgets()`
test runner, while making a few adjustments:

 * Sets the `devicePixelRatio` to `1.0` to unify all test pixel densities, and reduce scaling artifacts.
 * Sets the `textScaleFactor` to `1.0` to unify all test text scales, and reduce scaling artifacts.
 * Loads app fonts so that labels and decorations around your goldens are rendered with a real font.


## Platform Specific Test Runners
When writing golden tests, sometimes you may want to simulate a specific platform. For example, maybe
you want to render a golden of your app with an iOS style UI, specifically. For this purpose,
`flutter_test_goldens` provides per-platform test runners.

```dart
void main() {
  testGoldenSceneOnIOS("my iOS golden test", (tester) async {
    // TODO: implement golden test.
  });

  testGoldenSceneOnAndroid("my Android golden test", (tester) async {
    // TODO: implement golden test.
  });

  testGoldenSceneOnMac("my Mac golden test", (tester) async {
    // TODO: implement golden test.
  });

  testGoldenSceneOnWindow("my Windows golden test", (tester) async {
    // TODO: implement golden test.
  });

  testGoldenSceneOnLinux("my Linux golden test", (tester) async {
    // TODO: implement golden test.
  });
}
```

The implementation of the platform-specific test runners are nearly identical to `testGoldenScene()`, except
they set the `debugDefaultTargetPlatformOverride` property to the given platform.

```dart
debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
```

When the test completes, `debugDefaultTargetPlatformOverride` is reset to `null`.

You could implement this behavior yourself, within the standard `testWidgets()` runner, but
these platform-specific test runners are provided as a convenient way to simulate a platform without
repeating the platform configuration every time.

