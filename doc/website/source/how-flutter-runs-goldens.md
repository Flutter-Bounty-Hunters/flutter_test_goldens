---
title: How Flutter Runs Goldens
---
To understand why `flutter_test_goldens` is useful, it's important to first understand
how Flutter runs goldens, internally. Most of what `flutter_test_goldens` brings you is
improvements upon Flutter's internal golden system, thereby making your golden tests more
valuable.

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

### How does Flutter know to compare or update goldens?
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

### How does Flutter know the location of the golden file?
You might think it's obvious how Flutter finds the desired golden file. You give Flutter a file path like
"goldens/my_golden.png", and then Flutter applies that path relative to the test file directory. Simple, right?

But how does Flutter's golden system know where the current test file lives in the first place?

You might think that surely the test package exposes the location of the current test file, and that's
how Flutter knows where the test file is located. But it turns out that's incorrect. The test package
doesn't explicitly, publicly report the location of the current test file at all.

The section about how Flutter knows whether to compare goldens or render goldens included a bunch
of generated Dart code. You may have noticed the following snippet:

flutter_platform.dart::generateTestBootstrap()
```dart
buffer.write('''
    goldenFileComparator = LocalFileComparator(Uri.parse('$testUrl'));
    autoUpdateGoldenFiles = $updateGoldens;
''');
```

You can see that Flutter sets a global variable called `goldenFileComparator` and sets it
equal to a `LocalFileComparator` that takes a `Uri` called the `testUrl`. As a result, the only
place to find the current test file path, as far as we know, is within the global `goldenFileComparator`.

```dart
final testFileDirectory = (goldenFileComparator as LocalFileComparator).basedir.path;
```

If it seems crazy that you have to cast and query the global `goldenFileComparator` just to find
out which directory the test is running in, you're correct. This is an obvious oversight by Flutter.
Any test should be able to find out where it's running. Here's an old 
[StackOverflow post](https://stackoverflow.com/questions/74704732/get-path-to-current-executing-unit-test-in-flutter).

Nonetheless, this is the state of Flutter testing ~2025.

#### Where does the `testUrl` come from?
If you're a bit more curious, you might ask where the `testUrl` comes from.

This `testUrl` gets to this code through a long series of calls. However, the most important
communication points are as follows:

 * `flutter_tools:test.dart::TestCommand.verifyThenRunCommand()`: Where test file paths are collected while executing the `flutter test` command.
 * `flutter_tools:test.dart::TestCommand.runCommand() - result = await testRunner.runTests(..., _testFileUris.toList(), ...)`: Where the test runner is started with a list of test files.
 * `flutter_tools:runner.dart::FlutterTestRunner.runTests() -> flutter_tools:test_wrapper.dart::_DefaultTestWrapper.main()`: Where the `flutter_tools` package hands control to the `test_core` package.
 * `test_core:loader.dart::loadFile()` -> `flutter_tools:flutter_platform.dart::load(path, ...)`: Where control flows from the `test_core` package back to `flutter_tools`.
 * `flutter_tools:flutter_platform.dart::generateTestBootstrap(testUrl: testUrl, ...)`: Where the test file path is injected into the test code.

## How does Flutter compare a screenshot against a golden file?
The `flutter_test` package includes a global variable called `goldenFileComparator`. As shown in other
sections, this variable is assigned a `LocalFileComparator`, which is an implementation of `GoldenFileComparator`.
This means, in practice, all goldens are compared using a `LocalFileComparator`.

See: `flutter_test:_goldens_io.dart::LocalFileComparator`.

When we say that golden tests are pixel comparisons, we really mean it. The `LocalFileComparator` loads
pixel byte data from the given file.

```dart
/// Returns the bytes of the given [golden] file.
///
/// If the file cannot be found, an error will be thrown.
@protected
Future<List<int>> getGoldenBytes(Uri golden) async {
  final File goldenFile = _getGoldenFile(golden);
  if (!goldenFile.existsSync()) {
    fail('Could not be compared against non-existent file: "$golden"');
  }
  final List<int> goldenBytes = await goldenFile.readAsBytes();
  return goldenBytes;
}
```

With the pixel bytes loaded from the golden file, the `flutter_test` package then runs
a comparison, pixel by pixel. In the following method, the `LocalFileComparator` delegates
back to a central comparison method.

```dart
@override
Future<bool> compare(Uint8List imageBytes, Uri golden) async {
  // Compare pixel by pixel.
  final ComparisonResult result = await GoldenFileComparator.compareLists(
    imageBytes,
    await getGoldenBytes(golden),
  );

  if (result.passed) {
    result.dispose();
    return true;
  }

  final String error = await generateFailureOutput(result, golden, basedir);
  result.dispose();
  throw FlutterError(error);
}
```

For clarity, the full implementation of the pixel comparison function is reproduced below.
The replicated code includes lots of our own comments to help you understand what's happening.

```dart
/// Returns a [ComparisonResult] to describe the pixel differential of the
/// [test] and [master] image bytes provided.
Future<ComparisonResult> compareLists(List<int>? test, List<int>? master) async {
  if (test == null || master == null || test.isEmpty || master.isEmpty) {
    return ComparisonResult(
      passed: false,
      diffPercent: 1.0,
      error: 'Pixel test failed, null image provided.',
    );
  }

  if (listEquals(test, master)) {
    // If we get here, it means all pixels were the same, and the test passes. We're done.
    //
    // However, even if this if-statement fails, it doesn't necessarily mean that the test
    // fails. There are other reasons why PNG data might not exactly match new screenshot data.
    // The other cases are handled after this if-statement.
    return ComparisonResult(passed: true, diffPercent: 0.0);
  }

  // If we get here, it means that the golden PNG data didn't **exactly** match the new screenshot
  // data. This might be the result of mismatched pixels, or it might be the result of the PNG image
  // including metadata, which has nothing to do with pixel values.
  //
  // Now, flutter_test is going to fully decode the two images so that it can check each actual
  // pixel, instead of doing a superficial byte comparison.
  
  // Create a structured image representation of the new screenshot.
  final Codec testImageCodec = await instantiateImageCodec(Uint8List.fromList(test));
  final Image testImage = (await testImageCodec.getNextFrame()).image;
  final ByteData? testImageRgba = await testImage.toByteData();

  // Create a structured image representation of the existing golden.
  final Codec masterImageCodec = await instantiateImageCodec(Uint8List.fromList(master));
  final Image masterImage = (await masterImageCodec.getNextFrame()).image;
  final ByteData? masterImageRgba = await masterImage.toByteData();

  final int width = testImage.width;
  final int height = testImage.height;

  // The flutter_test package short circuits when the new screenshot doesn't have the same
  // dimensions as the existing golden. This is annoying because Flutter never shows you the
  // new screenshot - it just tells you that the sizes are different.
  if (width != masterImage.width || height != masterImage.height) {
    final ComparisonResult result = ComparisonResult(
      passed: false,
      diffPercent: 1.0,
      error:
          'Pixel test failed, image sizes do not match.\n'
          'Master Image: ${masterImage.width} X ${masterImage.height}\n'
          'Test Image: ${testImage.width} X ${testImage.height}',
      diffs: <String, Image>{'masterImage': masterImage, 'testImage': testImage},
    );
    return result;
  }

  // flutter_test will now count the number of actual mismatching pixels.
  //
  // During this process, flutter_test will also prepare for the eventuality that some pixels
  // don't match. flutter_test knows that it wants to paint special images that show which pixels
  // are different. Therefore, you'll notice th tracking of various pixel data and the eventual
  // creation of "masked" and "isolated" images. 
  int pixelDiffCount = 0;
  final int totalPixels = width * height;
  final ByteData invertedMasterRgba = _invert(masterImageRgba!);
  final ByteData invertedTestRgba = _invert(testImageRgba!);

  final Uint8List testImageBytes = (await testImage.toByteData())!.buffer.asUint8List();
  final ByteData maskedDiffRgba = ByteData(testImageBytes.length);
  maskedDiffRgba.buffer.asUint8List().setRange(0, testImageBytes.length, testImageBytes);
  final ByteData isolatedDiffRgba = ByteData(width * height * 4);

  for (int x = 0; x < width; x++) {
    for (int y = 0; y < height; y++) {
      final int byteOffset = (width * y + x) * 4;
      final int testPixel = testImageRgba.getUint32(byteOffset);
      final int masterPixel = masterImageRgba.getUint32(byteOffset);

      final int diffPixel =
          (_readRed(testPixel) - _readRed(masterPixel)).abs() +
          (_readGreen(testPixel) - _readGreen(masterPixel)).abs() +
          (_readBlue(testPixel) - _readBlue(masterPixel)).abs() +
          (_readAlpha(testPixel) - _readAlpha(masterPixel)).abs();

      if (diffPixel != 0) {
        final int invertedMasterPixel = invertedMasterRgba.getUint32(byteOffset);
        final int invertedTestPixel = invertedTestRgba.getUint32(byteOffset);
        // We grab the max of the 0xAABBGGRR encoded bytes, and then convert
        // back to 0xRRGGBBAA for the actual pixel value, since this is how it
        // was historically done.
        final int maskPixel = _toRGBA(
          math.max(_toABGR(invertedMasterPixel), _toABGR(invertedTestPixel)),
        );
        maskedDiffRgba.setUint32(byteOffset, maskPixel);
        isolatedDiffRgba.setUint32(byteOffset, maskPixel);
        pixelDiffCount++;
      }
    }
  }

  if (pixelDiffCount > 0) {
    // At least one pixel was different between the new screenshot and the existing golden.
    // Report the difference to the caller.
    final double diffPercent = pixelDiffCount / totalPixels;
    return ComparisonResult(
      passed: false,
      diffPercent: diffPercent,
      error:
          'Pixel test failed, '
          '${(diffPercent * 100).toStringAsFixed(2)}%, ${pixelDiffCount}px '
          'diff detected.',
      diffs: <String, Image>{
        'masterImage': masterImage,
        'testImage': testImage,
        'maskedDiff': await _createImage(maskedDiffRgba, width, height),
        'isolatedDiff': await _createImage(isolatedDiffRgba, width, height),
      },
    );
  }
  
  // The new screenshot and the existing golden have exactly the same pixels.
  masterImage.dispose();
  testImage.dispose();
  return ComparisonResult(passed: true, diffPercent: 0.0);
}
```

As you can see from `compareLists()`, the `flutter_test` package really does compare every pixel,
and reports even a single mis-matched pixel. Furthermore, you can see in the `compare()` method
that if a single pixel is different, the comparator reports failure.

## What does Flutter generate upon golden failure?
When a golden test fails, the Flutter test runner prints a message with details about the pixel mismatch amount.

```
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following assertion was thrown while running async test code:
Golden "failure_example.png": Pixel test failed, 2.07%, 89339px diff detected.
Failure feedback can be found at
/Users/admin/Projects/flutter_test_goldens/test_goldens/flutter/failures

When the exception was thrown, this was the stack:
#0      LocalFileComparator.compare (package:flutter_test/src/_goldens_io.dart:108:5)
<asynchronous suspension>
#1      MatchesGoldenFile.matchAsync.<anonymous closure> (package:flutter_test/src/_matchers_io.dart:124:32)
<asynchronous suspension>
<asynchronous suspension>
#3      _expect.<anonymous closure> (package:matcher/src/expect/expect.dart:123:26)
<asynchronous suspension>
<asynchronous suspension>
#5      expectLater.<anonymous closure> (package:flutter_test/src/widget_tester.dart:509:19)
<asynchronous suspension>
#6      main.<anonymous closure> (file:///Users/admin/Projects/flutter_test_goldens/test_goldens/flutter/failing_test.dart:15:5)
<asynchronous suspension>
#7      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:193:15)
<asynchronous suspension>
#8      TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1064:5)
<asynchronous suspension>
<asynchronous suspension>
(elided 3 frames from dart:async and package:stack_trace)

The exception was caught asynchronously.
════════════════════════════════════════════════════════════════════════════════════════════════════
```

The `flutter_test` package also generates four files in the same directory as the test:

 * `./failures/failure_my-test_masterImage.png`: The existing golden screenshot.
 * `./failures/failure_my-test_testImage.png`: The new screenshot from the test.
 * `./failures/failure_my-test_isolatedDiff.png`: The pixels that didn't match.
 * `./failures/failure_my-test_maskedDiff.png`: The pixels that didn't match, on top of the existing golden screenshot.

These images are useful for visual verification, but it's annoying that they're saved
separately. To make use of these images, a developer either needs to open multiple images at
the same time and flip between them, or use some kind of visualizer program.

Furthermore, with the subdirectory structure, and the naming convention, if multiple golden
tests fail in the same test directory, it can be tedious to find the failure files that correspond
to a specific golden file.

## References
### Notes
To learn about execution order, you can add `print()` statements to the Flutter tool at desired
locations. To get those `print()` statements to run, you'll need to trigger a rebuild of the Flutter
tool. To do that, delete the file at `[my_flutter_sdk]/bin/cache/flutter_tools.snapshot`. The next
time a `flutter` command is executed, it will rebuild the tool from source, and include your
`print()` statements.

### Key Stack Traces
Some stack traces that show execution path.

**Execution from test command launch:**
This captures the start of execution, and also captures the handoff point from the
`flutter_tools` package to the `test_core` package.

```
executable.dart - main()
StackTrace:
#0      main (package:test_core/src/executable.dart:39:36)
#1      _DefaultTestWrapper.main (package:flutter_tools/src/test/test_wrapper.dart:31:16)
#2      FlutterTestRunner.runTests (package:flutter_tools/src/test/runner.dart:179:25)
#3      TestCommand.runCommand (package:flutter_tools/src/commands/test.dart:664:33)
<asynchronous suspension>
#4      FlutterCommand.run.<anonymous closure> (package:flutter_tools/src/runner/flutter_command.dart:1558:27)
<asynchronous suspension>
#5      AppContext.run.<anonymous closure> (package:flutter_tools/src/base/context.dart:154:19)
<asynchronous suspension>
#6      CommandRunner.runCommand (package:args/command_runner.dart:212:13)
<asynchronous suspension>
#7      FlutterCommandRunner.runCommand.<anonymous closure> (package:flutter_tools/src/runner/flutter_command_runner.dart:496:9)
<asynchronous suspension>
#8      AppContext.run.<anonymous closure> (package:flutter_tools/src/base/context.dart:154:19)
<asynchronous suspension>
#9      FlutterCommandRunner.runCommand (package:flutter_tools/src/runner/flutter_command_runner.dart:431:5)
<asynchronous suspension>
#10     run.<anonymous closure>.<anonymous closure> (package:flutter_tools/runner.dart:98:11)
<asynchronous suspension>
#11     AppContext.run.<anonymous closure> (package:flutter_tools/src/base/context.dart:154:19)
<asynchronous suspension>
#12     main (package:flutter_tools/executable.dart:99:3)
<asynchronous suspension>
```

**test_core run():**

```
Runner.run()
_loadSuites()
loadFile() - path: /Users/admin/Projects/flutter_test_goldens/test_goldens/flutter/failing_test.dart
LoadSuite() - name: loading /Users/admin/Projects/flutter_test_goldens/test_goldens/flutter/failing_test.dart, path: /Users/admin/Projects/flutter_test_goldens/test_goldens/flutter/failing_test.dart
StackTrace:
#0      new LoadSuite (package:test_core/src/runner/load_suite.dart:88:78)
#1      Loader.loadFile (package:test_core/src/runner/loader.dart:208:15)
<asynchronous suspension>
#2      _StreamController.add (dart:async/stream_controller.dart:616:3)
<asynchronous suspension>
#3      _ForwardingStreamSubscription._handleData (dart:async/stream_pipe.dart:183:3)
<asynchronous suspension>
```

**Generate the code that bootstraps the test:**
The `test_core` package hands control back to `flutter_tools` to bootstrap a test.

```
Generate test bootstrap:
#0      generateTestBootstrap (package:flutter_tools/src/test/flutter_platform.dart:155:49)
#1      FlutterPlatform._generateTestMain (package:flutter_tools/src/test/flutter_platform.dart:813:12)
#2      FlutterPlatform._createListenerDart (package:flutter_tools/src/test/flutter_platform.dart:798:7)
#3      FlutterPlatform._startTest (package:flutter_tools/src/test/flutter_platform.dart:651:20)
#4      FlutterPlatform.loadChannel (package:flutter_tools/src/test/flutter_platform.dart:443:36)
#5      FlutterPlatform.load (package:flutter_tools/src/test/flutter_platform.dart:395:44)
#6      Loader.loadFile.<anonymous closure> (package:test_core/src/runner/loader.dart:216:40)
<asynchronous suspension>
#7      new LoadSuite.<anonymous closure>.<anonymous closure> (package:test_core/src/runner/load_suite.dart:98:19)
<asynchronous suspension>
```