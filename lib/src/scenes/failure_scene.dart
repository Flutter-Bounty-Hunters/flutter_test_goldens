import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
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
  final photos = <GoldenFailurePhoto>[];

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

    final reportImage = _layoutGoldenFailure(
      report: report,
      golden: golden.image,
      candidate: candidate.image,
      absoluteDiff: absoluteDiff,
      relativeDiff: relativeDiff,
    );

    String description = item.metadata.id;
    if (mismatch is PixelGoldenMismatch) {
      description += " (${mismatch.mismatchPixelCount.toInt()}px, ${(mismatch.percent * 100).toStringAsFixed(2)}%)";
    } else if (mismatch is WrongSizeGoldenMismatch) {
      description += " (wrong size)";
    }
    photos.add(
      GoldenFailurePhoto(
        description: description,
        pixels: reportImage,
      ),
    );
  }

  for (final missingCandidate in report.missingCandidates) {
    photos.add(
      GoldenFailurePhoto(
        description: "${missingCandidate.golden!.id} (missing candidate)",
        pixels: missingCandidate.golden!.image,
      ),
    );
  }

  for (final extraCandidate in report.extraCandidates) {
    photos.add(
      GoldenFailurePhoto(
        description: "${extraCandidate.screenshot!.id} (extra candidate)",
        pixels: extraCandidate.screenshot!.image,
      ),
    );
  }

  return _layoutFailureScene(tester, report, photos);
}

/// Generates a single image that shows all the golden failures.
Future<(Image, FailureSceneMetadata)> _layoutFailureScene(
    WidgetTester tester, GoldenSceneReport report, List<GoldenFailurePhoto> images) async {
  final renderablePhotos = <GoldenFailurePhoto, (Uint8List, GlobalKey)>{};
  for (final photo in images) {
    final image = await _convertImagePackageToUiImage(photo.pixels);
    final pixels = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
    renderablePhotos[photo] = (pixels, GlobalKey());
  }

  final sceneKey = GlobalKey();
  final scene = GoldenSceneBounds(
    child: IntrinsicWidth(
      child: IntrinsicHeight(
        child: GoldenFailureScene(
          key: sceneKey,
          direction: Axis.vertical,
          renderablePhotos: renderablePhotos,
          background: null,
        ),
      ),
    ),
  );
  await tester.pumpWidgetAndAdjustWindow(scene);

  for (final entry in renderablePhotos.entries) {
    await precacheImage(
      MemoryImage(entry.value.$1),
      tester.element(find.byKey(entry.value.$2)),
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
          id: golden.description,
          topLeft:
              (renderablePhotos[golden]!.$2.currentContext!.findRenderObject() as RenderBox).localToGlobal(Offset.zero),
          size: renderablePhotos[golden]!.$2.currentContext!.size!,
        ),
    ],
  );

  return (failureImage, metadata);
}

/// Generates a single image that shows the golden, the candidate, and the
/// absolute and relative differences between them.
Image _layoutGoldenFailure({
  required GoldenSceneReport report,
  required Image golden,
  required Image candidate,
  required Image absoluteDiff,
  required Image relativeDiff,
}) {
  final image = Image(
    width: golden.width + candidate.width,
    height: golden.height + candidate.height,
  );

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
    x: golden.width,
    y: 0,
  );

  // Copy absolute diff to bottom left corner.
  _drawImage(
    source: absoluteDiff,
    destination: image,
    x: 0,
    y: golden.height,
  );

  // Copy relative diff to bottom right corner.
  _drawImage(
    source: relativeDiff,
    destination: image,
    x: golden.width,
    y: golden.height,
  );

  return image;
}

/// Generates an image that shows the absolute differences between the golden
/// and the candidate images.
Image _generateAbsoluteDiff(
  GoldenImage golden,
  GoldenImage candidate,
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
  required GoldenImage golden,
  required GoldenImage candidate,
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
  GoldenImage golden,
  GoldenImage candidate,
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
  required GoldenImage golden,
  required GoldenImage candidate,
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

class GoldenFailureScene extends StatelessWidget {
  const GoldenFailureScene({
    super.key,
    required this.direction,
    required this.renderablePhotos,
    this.background,
  });

  final Axis direction;
  final Map<GoldenFailurePhoto, (Uint8List, GlobalKey)> renderablePhotos;
  final Widget? background;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const material.Color(0xFF666666),
      child: Stack(
        children: [
          if (background != null) //
            Positioned.fill(
              child: ColoredBox(color: material.Colors.green),
            ),
          if (background != null) //
            Positioned.fill(
              child: background!,
            ),
          Padding(
            padding: const EdgeInsets.all(48),
            child: Flex(
              direction: direction,
              mainAxisSize: MainAxisSize.min,
              spacing: 48,
              children: [
                for (final entry in renderablePhotos.entries) //
                  SizedBox(
                    width: entry.key.pixels.width.toDouble(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ColoredBox(
                          color: material.Colors.white,
                          child: material.Image.memory(
                            key: entry.value.$2,
                            entry.value.$1,
                            width: entry.key.pixels.width.toDouble(),
                            height: entry.key.pixels.height.toDouble(),
                          ),
                        ),
                        Container(
                          color: material.Colors.white,
                          padding: const EdgeInsets.all(16),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              entry.key.description,
                              softWrap: false,
                              style: TextStyle(
                                color: material.Colors.black,
                                fontFamily: "packages/flutter_test_goldens/OpenSans",
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
