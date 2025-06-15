---
title: Compare Screenshots
navOrder: 30
---
## How does Flutter compare a screenshot against a golden file?
The `flutter_test` package includes a global variable called `goldenFileComparator`. This variable is 
assigned a `LocalFileComparator`, which is an implementation of `GoldenFileComparator`. This means, in 
practice, all goldens are compared using a `LocalFileComparator`.

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