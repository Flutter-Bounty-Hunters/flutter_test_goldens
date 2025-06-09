---
title: Find the golden test directory
navOrder: 20
---
A golden test either loads an existing golden image from a file, or renders a new golden image to a file.
Golden files are saved and loaded relative the directory that holds the current running test. Therefore, it's
critical that a golden test know the directory that contains the current test.

You might think it's obvious how Flutter finds the desired golden file. You give Flutter a file path like
"goldens/my_golden.png", and then Flutter applies that path relative to the test file directory. Simple, right?

But how does Flutter's golden system know where the current test file lives in the first place?

You might think that surely the test package exposes the location of the current test file, and that's
how Flutter knows where the test file is located. But it turns out that's incorrect. The test package
doesn't explicitly, publicly report the location of the current test file at all.

The following snippet is taking from `generateTestBootstrap()` in `flutter_platform.dart`. This
snippet of code is assembling new Dart source code from a `String`. This is just a small
part of a much larger assembly of raw source code.

```dart
buffer.write('''
    goldenFileComparator = LocalFileComparator(Uri.parse('$testUrl'));
    autoUpdateGoldenFiles = $updateGoldens;
''');
```

You can see that Flutter sets a global variable called `goldenFileComparator` and sets it
equal to a `LocalFileComparator` that takes a `Uri` called `testUrl`. As a result, the only
place to find the current test file path, as far as we know, is within the global `goldenFileComparator`.

```dart
final testFileDirectory = (goldenFileComparator as LocalFileComparator).basedir.path;
```

If it seems crazy that you have to cast and query the global `goldenFileComparator` just to find
out which directory the test is running in, you're correct. This is an obvious oversight by Flutter.
Any test should be able to find out where it's running. Here's an old
[StackOverflow post](https://stackoverflow.com/questions/74704732/get-path-to-current-executing-unit-test-in-flutter).

Nonetheless, this is the state of Flutter testing ~2025.

## Where does the `testUrl` come from?
If you're a bit more curious, you might ask where the `testUrl` comes from.

This `testUrl` gets to this code through a long series of calls. However, the most important
communication points are as follows:

* `flutter_tools:test.dart::TestCommand.verifyThenRunCommand()`: Where test file paths are collected while executing the `flutter test` command.
* `flutter_tools:test.dart::TestCommand.runCommand() - result = await testRunner.runTests(..., _testFileUris.toList(), ...)`: Where the test runner is started with a list of test files.
* `flutter_tools:runner.dart::FlutterTestRunner.runTests() -> flutter_tools:test_wrapper.dart::_DefaultTestWrapper.main()`: Where the `flutter_tools` package hands control to the `test_core` package.
* `test_core:loader.dart::loadFile()` -> `flutter_tools:flutter_platform.dart::load(path, ...)`: Where control flows from the `test_core` package back to `flutter_tools`.
* `flutter_tools:flutter_platform.dart::generateTestBootstrap(testUrl: testUrl, ...)`: Where the test file path is injected into the test code.