import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter_test_goldens/src/goldens/pixel_comparisons.dart';
import 'package:image/image.dart';

import 'package:flutter_test_goldens/flutter_test_goldens.dart';

/// Given a [mismatch] between a golden and a screenshot, generates an image
/// that shows the golden, the screenshot, and the differences between them.
Future<Image> generateFailureScene(GoldenMismatch mismatch) async {
  final goldenWidth = mismatch.golden!.image.width;
  final goldenHeight = mismatch.golden!.image.height;

  final screenshotWidth = mismatch.screenshot!.image.width;
  final screenshotHeight = mismatch.screenshot!.image.height;

  final maxWidth = max(goldenWidth, screenshotWidth);
  final maxHeight = max(goldenHeight, screenshotHeight);

  final failureImage = Image(
    width: maxWidth * 2,
    height: maxHeight * 2,
  );

  // Copy golden to top left corner.
  for (int x = 0; x < goldenWidth; x += 1) {
    for (int y = 0; y < goldenHeight; y += 1) {
      final goldenPixel = mismatch.golden!.image.getPixel(x, y);
      failureImage.setPixel(x, y, goldenPixel);
    }
  }

  // Copy screenshot to top right corner.
  for (int x = 0; x < screenshotWidth; x += 1) {
    for (int y = 0; y < screenshotHeight; y += 1) {
      final screenshotPixel = mismatch.screenshot!.image.getPixel(x, y);
      failureImage.setPixel(maxWidth + x, y, screenshotPixel);
    }
  }

  // Paint mismatch images.
  final absoluteDiffColor = ColorUint32.rgb(255, 255, 0);
  for (int x = 0; x < maxWidth; x += 1) {
    for (int y = 0; y < maxHeight; y += 1) {
      if (x >= goldenWidth || x >= screenshotWidth || y >= goldenHeight || y >= screenshotHeight) {
        // This pixel doesn't exist in the golden, or it doesn't exist in the
        // screenshot. Therefore, we have nothing to compare. Treat this pixel
        // as a max severity difference.

        // Paint this pixel in the absolute diff image.
        failureImage.setPixel(x, maxHeight + y, absoluteDiffColor);

        // Paint this pixel in the relative severity diff image.
        failureImage.setPixel(maxWidth + x, maxHeight + y, absoluteDiffColor);

        continue;
      }

      // Check if the screenshot matches the golden.
      final goldenPixel = mismatch.golden!.image.getPixel(x, y);
      final screenshotPixel = mismatch.screenshot!.image.getPixel(x, y);
      final pixelsMatch = goldenPixel == screenshotPixel;
      if (pixelsMatch) {
        continue;
      }

      // Paint this pixel in the absolute diff image.
      failureImage.setPixel(x, maxHeight + y, absoluteDiffColor);

      // Paint this pixel in the relative severity diff image.
      final mismatchPercent = calculateColorMismatchPercent(goldenPixel, screenshotPixel);
      final yellowAmount = ui.lerpDouble(0.2, 1.0, mismatchPercent)!;
      failureImage.setPixel(
        goldenWidth + x,
        goldenHeight + y,
        ColorUint32.rgb((255 * yellowAmount).round(), (255 * yellowAmount).round(), 0),
      );
    }
  }

  return failureImage;
}
