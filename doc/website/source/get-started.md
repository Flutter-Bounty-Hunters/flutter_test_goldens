---
title: Get Started
---
## Add the Package
To get started with `flutter_test_goldens`, add the package to your pubspec.

```yaml
dev_dependencies:
  flutter_test_goldens: any
```

## Start a Test
Define a test using the `testGoldenScene()` method, or a related test runner.

```dart
void main() {
  testGoldenScene("my golden test", (tester) async {
    // TODO: implement golden test.
  });
}
```

Using `flutter_test_goldens` test runners isn't strictly required, but they handle some test
configuration that's expected for a golden test.

[Learn more](/create-a-test/test-runners) about `flutter_test_goldens` test runners.

## Implement a Test
With a test ready to go, you may want to accomplish a variety of goals:

 * [Write a gallery test](/golden-scenes/gallery)
 * [Write a timeline test](/golden-scenes/filmstrip)
 * [Add focus and semantic tracking](/golden-metadata/payload)
