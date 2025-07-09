import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart' hide Image;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/src/goldens/pixel_comparisons.dart';
import 'package:image/image.dart';

import 'package:flutter_test_goldens/flutter_test_goldens.dart';

/// Given a [mismatch] between a golden and a screenshot, generates an image
/// that shows the golden, the screenshot, and the differences between them.
Future<Image> paintGoldenMismatchImages(GoldenMismatch mismatch) async {
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

/// Given a [report], generates that shows all the mismatches found in the report.
Future<(Image, FailureSceneMetadata)> paintFailureScene(WidgetTester tester, GoldenSceneReport report) async {
  final photos = <GoldenSceneScreenshot>[];

  for (final item in report.items) {
    final mismatch = item.mismatch;
    if (!(mismatch is WrongSizeGoldenMismatch || mismatch is PixelGoldenMismatch)) {
      // Missing candidates and extra candidates are handled separately.
      continue;
    }

    final golden = mismatch!.golden!;
    final candidate = mismatch.screenshot!;
    final absoluteDiff = _generateAbsoluteDiff(golden, candidate, mismatch);
    final relativeDiff = _generateRelativeDiff(golden, candidate, mismatch);

    final reportImage = await _layoutGoldenFailure(
      report: report,
      golden: golden.image,
      candidate: candidate.image,
      absoluteDiff: absoluteDiff,
      relativeDiff: relativeDiff,
    );
    final image = await _convertImagePackageToUiImage(reportImage);
    final pixels = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();

    String description = item.metadata.metadata.description;
    if (mismatch is PixelGoldenMismatch) {
      description += " (${mismatch.mismatchPixelCount.toInt()}px, ${(mismatch.percent * 100).toStringAsFixed(2)}%)";
    } else if (mismatch is WrongSizeGoldenMismatch) {
      description += " (wrong size)";
    }

    photos.add(
      GoldenSceneScreenshot(
        item.metadata.id,
        item.metadata.metadata.copyWith(description: description),
        reportImage,
        pixels,
      ),
    );
  }

  // for (final missingCandidate in report.missingCandidates) {
  //   // TODO: Figure out why using missingCandidate.golden!.pngBytes causes an "Invalid image data" error.
  //   final image = await _convertImagePackageToUiImage(missingCandidate.golden!.image);
  //   final pixels = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  //   photos.add(
  //     GoldenSceneScreenshot(
  //       missingCandidate.golden!.id,
  //       missingCandidate.golden!.metadata.copyWith(
  //         description: "${missingCandidate.golden!.metadata.description} (missing candidate)",
  //       ),
  //       missingCandidate.golden!.image,
  //       pixels,
  //     ),
  //   );
  // }

  // for (final extraCandidate in report.extraCandidates) {
  //   photos.add(
  //     GoldenSceneScreenshot(
  //       extraCandidate.screenshot!.id,
  //       extraCandidate.screenshot!.metadata.copyWith(
  //         description: "${extraCandidate.screenshot!.metadata.description} (extra candidate)",
  //       ),
  //       extraCandidate.screenshot!.image,
  //       extraCandidate.screenshot!.pngBytes,
  //     ),
  //   );
  // }

  return _layoutFailureScene(tester, report, photos);
}

/// Generates a single image that shows all the golden failures.
Future<(Image, FailureSceneMetadata)> _layoutFailureScene(
  WidgetTester tester,
  GoldenSceneReport report,
  List<GoldenSceneScreenshot> images,
) async {
  final renderablePhotos = <GoldenSceneScreenshot, GlobalKey>{};
  for (final photo in images) {
    renderablePhotos[photo] = GlobalKey();
  }

  final layout = RowSceneLayout(
    itemDecorator: _itemDecorator,
  );

  final sceneKey = GlobalKey();
  final scene = GoldenSceneBounds(
    child: IntrinsicWidth(
      child: IntrinsicHeight(
        child: material.Builder(
          key: sceneKey,
          builder: (context) {
            return layout.build(
              tester,
              context,
              SceneLayoutContent(goldens: renderablePhotos),
            );
          },
        ),
      ),
    ),
  );
  await tester.pumpWidgetAndAdjustWindow(scene);

  for (final entry in renderablePhotos.entries) {
    await precacheImage(
      MemoryImage(entry.key.pngBytes),
      tester.element(find.byKey(entry.value)),
    );
  }

  await tester.pumpAndSettle();

  final uiImage = await captureImage(find.byKey(sceneKey).evaluate().single);
  final bytes = await uiImage.toByteData(format: ui.ImageByteFormat.rawRgba);
  final failureImage = Image.fromBytes(
    width: uiImage.width,
    height: uiImage.height,
    bytes: bytes!.buffer,
    order: ChannelOrder.rgba,
  );

  // Lookup and return metadata for the position and size of each failure image
  // within the scene.
  final metadata = FailureSceneMetadata(
    description: report.metadata.description,
    images: [
      for (final golden in renderablePhotos.keys)
        FailureImageMetadata(
          id: golden.id,
          topLeft:
              (renderablePhotos[golden]!.currentContext!.findRenderObject() as RenderBox).localToGlobal(Offset.zero),
          size: renderablePhotos[golden]!.currentContext!.size!,
        ),
    ],
  );

  return (failureImage, metadata);
}

/// Generates a single image that shows the golden, the candidate, and the
/// absolute and relative differences between them.
Future<Image> _layoutGoldenFailure({
  required GoldenSceneReport report,
  required Image golden,
  required Image candidate,
  required Image absoluteDiff,
  required Image relativeDiff,
}) async {
  final maxWidth = max(golden.width, candidate.width);
  final maxHeight = max(golden.height, candidate.height);
  const gap = 4;

  final image = Image(
    width: maxWidth * 2 + gap,
    height: maxHeight * 2 + gap,
  );

  final white = ColorUint32.rgb(255, 255, 255);
  for (int x = 0; x < image.width; x += 1) {
    for (int y = 0; y < image.height; y += 1) {
      image.setPixel(x, y, white);
    }
  }

  // Copy golden to top left corner.
  _drawImage(
    source: golden,
    destination: image,
    x: 0,
    y: 0,
  );

  // Copy screenshot to top right corner.
  _drawImage(
    source: candidate,
    destination: image,
    x: maxWidth + gap,
    y: 0,
  );

  // Copy absolute diff to bottom left corner.
  final diffY = maxHeight + gap;
  _drawImage(
    source: absoluteDiff,
    destination: image,
    x: 0,
    y: diffY,
  );

  // Copy relative diff to bottom right corner.
  _drawImage(
    source: relativeDiff,
    destination: image,
    x: maxWidth + gap,
    y: diffY,
  );

  return image;
}

/// Generates an image that shows the absolute differences between the golden
/// and the candidate images.
Image _generateAbsoluteDiff(
  GoldenSceneScreenshot golden,
  GoldenSceneScreenshot candidate,
  GoldenMismatch mismatch,
) {
  final maxWidth = max(golden.image.width, candidate.image.width);
  final maxHeight = max(golden.image.height, candidate.image.height);

  final failureImage = Image(width: maxWidth, height: maxHeight);
  _paintAbsoluteDiff(
    destination: failureImage,
    originX: 0,
    originY: 0,
    golden: golden,
    candidate: candidate,
  );

  return failureImage;
}

/// Paints the absolute differences between the golden and candidate images
/// into the [destination] image at the specified [originX] and [originY].
void _paintAbsoluteDiff({
  required Image destination,
  required int originX,
  required int originY,
  required GoldenSceneScreenshot golden,
  required GoldenSceneScreenshot candidate,
}) {
  final maxWidth = max(golden.image.width, candidate.image.width);
  final maxHeight = max(golden.image.height, candidate.image.height);

  // Paint mismatch images.
  final absoluteDiffColor = ColorUint32.rgb(255, 255, 0);
  for (int x = 0; x < maxWidth; x += 1) {
    for (int y = 0; y < maxHeight; y += 1) {
      if (x >= golden.image.width ||
          x >= candidate.image.width ||
          y >= golden.image.height ||
          y >= candidate.image.height) {
        // This pixel doesn't exist in the golden, or it doesn't exist in the
        // screenshot. Therefore, we have nothing to compare. Treat this pixel
        // as a max severity difference.

        // Paint this pixel in the absolute diff image.
        destination.setPixel(originX + x, originY + y, absoluteDiffColor);

        continue;
      }

      // Check if the screenshot matches the golden.
      final goldenPixel = golden.image.getPixel(x, y);
      final screenshotPixel = candidate.image.getPixel(x, y);
      final pixelsMatch = goldenPixel == screenshotPixel;
      if (pixelsMatch) {
        continue;
      }

      // Paint this pixel in the absolute diff image.
      destination.setPixel(originX + x, originY + y, absoluteDiffColor);
    }
  }
}

/// Generates an image that shows the relative differences between the golden
/// and the candidate images.
Image _generateRelativeDiff(
  GoldenSceneScreenshot golden,
  GoldenSceneScreenshot candidate,
  GoldenMismatch mismatch,
) {
  final maxWidth = max(golden.image.width, candidate.image.width);
  final maxHeight = max(golden.image.height, candidate.image.height);

  final failureImage = Image(width: maxWidth, height: maxHeight);
  _paintRelativeDiff(
    destination: failureImage,
    originX: 0,
    originY: 0,
    golden: golden,
    candidate: candidate,
  );

  return failureImage;
}

/// Paints the relative differences between the golden and candidate images
/// into the [destination] image at the specified [originX] and [originY].
void _paintRelativeDiff({
  required Image destination,
  required int originX,
  required int originY,
  required GoldenSceneScreenshot golden,
  required GoldenSceneScreenshot candidate,
}) {
  final maxWidth = max(golden.image.width, candidate.image.width);
  final maxHeight = max(golden.image.height, candidate.image.height);

  // Paint mismatch images.
  final absoluteDiffColor = ColorUint32.rgb(255, 255, 0);
  for (int x = 0; x < maxWidth; x += 1) {
    for (int y = 0; y < maxHeight; y += 1) {
      if (x >= golden.image.width ||
          x >= candidate.image.width ||
          y >= golden.image.height ||
          y >= candidate.image.height) {
        // This pixel doesn't exist in the golden, or it doesn't exist in the
        // screenshot. Therefore, we have nothing to compare. Treat this pixel
        // as a max severity difference.
        destination.setPixel(originX + x, originY + y, absoluteDiffColor);

        continue;
      }

      // Check if the screenshot matches the golden.
      final goldenPixel = golden.image.getPixel(x, y);
      final screenshotPixel = candidate.image.getPixel(x, y);
      final pixelsMatch = goldenPixel == screenshotPixel;
      if (pixelsMatch) {
        continue;
      }

      final mismatchPercent = calculateColorMismatchPercent(goldenPixel, screenshotPixel);
      final yellowAmount = ui.lerpDouble(0.2, 1.0, mismatchPercent)!;
      destination.setPixel(
        originX + x,
        originY + y,
        ColorUint32.rgb((255 * yellowAmount).round(), (255 * yellowAmount).round(), 0),
      );
    }
  }
}

/// Draws the [source] image onto the [destination] image at the specified
/// [x] and [y] coordinates.
void _drawImage({
  required Image source,
  required Image destination,
  required int x,
  required int y,
}) {
  for (int i = 0; i < source.width; i += 1) {
    for (int j = 0; j < source.height; j += 1) {
      final pixel = source.getPixel(i, j);
      destination.setPixel(x + i, y + j, pixel);
    }
  }
}

/// Converts an [Image] from the image package to a [ui.Image].
Future<ui.Image> _convertImagePackageToUiImage(Image image) async {
  final pixels = image.getBytes(order: ChannelOrder.rgba);

  final completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    pixels,
    image.width,
    image.height,
    ui.PixelFormat.rgba8888,
    (ui.Image img) => completer.complete(img),
  );
  return completer.future;
}

class GoldenFailurePhoto {
  const GoldenFailurePhoto({
    required this.description,
    required this.pixels,
  });

  final String description;
  final Image pixels;
}

class FailureSceneMetadata {
  static FailureSceneMetadata fromJson(Map<String, dynamic> json) {
    return FailureSceneMetadata(
      description: json["description"] ?? "",
      images: [
        for (final photoJson in (json["images"] as List<dynamic>)) //
          FailureImageMetadata.fromJson(photoJson),
      ],
    );
  }

  const FailureSceneMetadata({
    required this.description,
    required this.images,
  });

  final String description;
  final List<FailureImageMetadata> images;

  Map<String, dynamic> toJson() {
    return {
      "description": description,
      "images": images.map((photo) => photo.toJson()).toList(),
    };
  }
}

class FailureImageMetadata {
  static FailureImageMetadata fromJson(Map<String, dynamic> json) {
    return FailureImageMetadata(
      id: json["id"],
      topLeft: ui.Offset(
        (json["topLeft"]["x"] as num).toDouble(),
        (json["topLeft"]["y"] as num).toDouble(),
      ),
      size: ui.Size(
        (json["size"]["width"] as num).toDouble(),
        (json["size"]["height"] as num).toDouble(),
      ),
    );
  }

  FailureImageMetadata({
    required this.id,
    required this.topLeft,
    required this.size,
  });

  final String id;
  final ui.Offset topLeft;
  final ui.Size size;

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "topLeft": {
        "x": topLeft.dx,
        "y": topLeft.dy,
      },
      "size": {
        "width": size.width,
        "height": size.height,
      },
    };
  }
}

Widget _itemDecorator(
  BuildContext context,
  GoldenScreenshotMetadata metadata,
  Widget content,
) {
  return Padding(
    padding: const EdgeInsets.all(24),
    child: IntrinsicWidth(
      child: PixelSnapColumn(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PixelSnapRow(
            children: [
              Expanded(child: Text('Golden')),
              Expanded(child: Text('Candidate')),
            ],
          ),
          content,
          PixelSnapRow(
            children: [
              Expanded(child: Text('Absolute Diff')),
              Expanded(child: Text('Relative Diff')),
            ],
          ),
          const material.Divider(),
          Expanded(
            child: Text(metadata.description),
          ),
        ],
      ),
    ),
  );
}
