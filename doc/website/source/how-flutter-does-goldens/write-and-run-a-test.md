---
title: Write and run a Golden Test
navOrder: 10
---
## How golden tests are defined
A golden test is a Flutter widget test, but it inspects pixels instead of inspecting widget
sizes, offsets, properties, etc. The critical workhorse that does the "golden stuff" in a
widget test is a `Matcher` called [`matchesGoldenFile()`](https://api.flutter.dev/flutter/flutter_test/matchesGoldenFile.html).

A typical golden test includes three steps:
1. Pump a widget tree.
2. (Maybe) take some user action, like tapping on something.
3. Take a screenshot, or compare to an existing screenshot.

```dart
testWidgets("basic golden test", (tester) async {
  // Pump a widget tree.
  await tester.pumpWidget(MyApp());
  
  // Take an action (optional).
  await tester.tap(find.byType(MyButton));
  
  // Take a screenshot, or compare to an existing screenshot.
  await expectLater(find.byType(MyApp), matchesGoldenFile("my-app.png"));
});
```

## How golden tests are run
In the section about defining golden tests, it was mentioned that the `matchesGoldenFile()` either
creates a new screenshot, or compares to an existing screenshot. This is the most unusual
aspect of golden tests, because it means that sometimes a matcher does matching, but other times
the matcher generates a golden file. How does the matcher know which one to do?

The matcher is controlled by the Flutter tool, which is used to run widget tests.
The Flutter tool includes a flag called [`--update-goldens`](https://github.com/flutter/flutter/blob/e9e989bef3de34cd8d2b24215f76bfb660aa544a/packages/flutter_tools/lib/src/commands/test.dart#L176).

Generate new golden screenshots:

    flutter test --update-goldens

Compare to existing golden screenshots:

    flutter test

### How does your test know to compare or update goldens?
Developers either pass `--update-goldens` when running tests, or they don't. But how does Flutter's
test system know about the developer's choice?

The `flutter_test` package (which lives in the Flutter SDK), declares a global variable called
[`autoUpdateGoldenFiles`](https://github.com/flutter/flutter/blob/e9e989bef3de34cd8d2b24215f76bfb660aa544a/packages/flutter_test/lib/src/goldens.dart#L211).

The compare/render mode is achieved by setting `autoUpdateGoldenFiles` to `true` for "render" or
`false` for "compare". But the way that Flutter writes this variable is very unusual. If you search
through Flutter SDK code references in your IDE, you'll never find where that variable is set, because
it's set in such an unusual way.

When Flutter bootstraps a test, it partially generates the code that's run, from a `String`.

Here's a partial copy of how Flutter generates this code, in `generateTestBootstrap()` from `flutter_platform.dart`:

flutter_platform.dart::generateTestBootstrap()
```dart
buffer.write('''
//....
void main() {
  final String serverPort = Platform.environment['SERVER_PORT'] ?? '';
  final String server = '$websocketUrl:\$serverPort';
  StreamChannel<dynamic> testChannel = serializeSuite(() {
    catchIsolateErrors();
''');
if (flutterTestDep) {
buffer.write('''
    goldenFileComparator = LocalFileComparator(Uri.parse('$testUrl'));
    autoUpdateGoldenFiles = $updateGoldens;
''');
}
if (testConfigFile != null) {
buffer.write('''
    return () => test_config.testExecutable(_testMain);
''');
} else {
buffer.write('''
    return _testMain;
''');
}
buffer.write('''
  });
''');
```

The complete implementation in Flutter is much longer, and includes many more segments of `String`s
that are later compiled as Dart code.

If you look closely at the code `String` above, you'll notice that `updateGoldens` is injected into
the code: `autoUpdateGoldenFiles = $updateGoldens;`. When this code is eventually compiled and
run, it sets `autoUpdateGoldenFiles` to the value that the Flutter tool passed in for `updateGoldens`.

Therefore, the end result is that when the global variable `autoUpdateGoldenFiles` is `true`, a golden
test should render a new golden file, and when it's `false`, a golden test should compare the new
screenshot against the existing golden image.