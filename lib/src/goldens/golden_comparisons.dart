import 'package:flutter_test_goldens/src/goldens/golden_collections.dart';
import 'package:flutter_test_goldens/src/logging.dart';

/// Compares new [screenshots] to existing [goldens] and reports any mismatches between them.
GoldenCollectionMismatches compareGoldenCollections(
  GoldenCollection goldens,
  GoldenCollection screenshots,
) {
  final mismatches = <String, GoldenMismatch>{};

  // For every golden, look for missing and mismatching screenshots.
  for (final id in goldens.ids) {
    if (!screenshots.hasId(id)) {
      mismatches[id] = MissingGoldenMismatch(
        golden: goldens[id],
      );
      continue;
    }

    // This ID has a golden and a screenshot. Look for a size mismatch.
    final golden = goldens[id]!;
    final screenshot = screenshots[id]!;
    if (golden.size != screenshot.size) {
      mismatches[id] = WrongSizeGoldenMismatch(
        golden: golden,
        screenshot: screenshot,
      );
      continue;
    }

    // The golden and screenshot have the same size. Look for a pixel mismatch.
    final mismatchPixelCount = _calculatePixelMismatch(golden, screenshot);
    if (mismatchPixelCount > 0) {
      mismatches[id] = PixelGoldenMismatch(
        golden: golden,
        screenshot: screenshot,
        mismatchPixelCount: mismatchPixelCount,
      );
      continue;
    }
  }

  // Look for any screenshots for which there is a missing golden.
  for (final id in screenshots.ids) {
    if (!goldens.hasId(id)) {
      mismatches[id] = MissingGoldenMismatch(
        screenshot: screenshots[id],
      );
    }
  }

  return GoldenCollectionMismatches(goldens, screenshots, mismatches);
}

/// Compares every pixel between [golden] and [screenshot] and returns the total
/// number of pixels that are different between the two images.
int _calculatePixelMismatch(GoldenImage golden, GoldenImage screenshot) {
  FtgLog.pipeline.fine("Running a pixel comparison for ${golden.id}");
  int mismatchCount = 0;
  for (int x = 0; x < golden.image.width; x += 1) {
    for (int y = 0; y < golden.image.height; y += 1) {
      if (golden.image.getPixel(x, y) != screenshot.image.getPixel(x, y)) {
        mismatchCount += 1;
      }
    }
  }
  FtgLog.pipeline.fine("Found $mismatchCount mismatched pixels");

  return mismatchCount;
}

/// All golden mismatches that were found for a collection of golden images.
class GoldenCollectionMismatches {
  GoldenCollectionMismatches(this.goldens, this.screenshots, this.mismatches);

  /// The golden images used in the comparison.
  final GoldenCollection goldens;

  /// The current screenshots which were compared against the goldens.
  final GoldenCollection screenshots;

  /// The errors between the screenshots and the goldens.
  final Map<String, GoldenMismatch> mismatches;
}

/// A screenshot was compared with a golden but their pixels didn't match.
class PixelGoldenMismatch extends GoldenMismatch {
  PixelGoldenMismatch({
    required super.golden,
    required super.screenshot,
    required this.mismatchPixelCount,
  });

  @override
  GoldenImage get golden => super.golden!;

  @override
  GoldenImage get screenshot => super.screenshot!;

  final int mismatchPixelCount;

  int get totalPixelCount => golden.size.width.toInt() * golden.size.height.toInt();

  double get percent => mismatchPixelCount / totalPixelCount;

  @override
  String get describe =>
      "A new screenshot doesn't match its existing golden image - mismatch: ${(100 * percent).toStringAsFixed(3)}%, ${mismatchPixelCount}px (of ${totalPixelCount}px).";

  @override
  Map<String, dynamic> get describeStructured => throw UnimplementedError();
}

/// A screenshot was compared with a golden but they were different sizes.
class WrongSizeGoldenMismatch extends GoldenMismatch {
  WrongSizeGoldenMismatch({
    required super.golden,
    required super.screenshot,
  });

  @override
  GoldenImage get golden => super.golden!;

  @override
  GoldenImage get screenshot => super.screenshot!;

  @override
  String get describe => "A new screenshot has a different size than its existing golden image (${golden.id}) - "
      "golden size: ${golden.size}, screenshot size: ${screenshot.size}";

  @override
  Map<String, dynamic> get describeStructured => throw UnimplementedError();
}

/// Attempted to compare a screenshot to a golden, but either the screenshot was never
/// generated, or the screenshot was generated for a golden that doesn't exist.
class MissingGoldenMismatch extends GoldenMismatch {
  MissingGoldenMismatch({
    super.golden,
    super.screenshot,
  });

  GoldenImage get _existingGolden => golden ?? screenshot!;

  @override
  String get describe => "A new screenshot was generated with ID '${_existingGolden.id}', $_missingMessage";

  String get _missingMessage => golden != null //
      ? "but no screenshot was generated with that ID."
      : "but there's no existing golden image with that ID.";

  @override
  Map<String, dynamic> get describeStructured => throw UnimplementedError();
}

/// A mismatch between a pristine golden image and its latest screenshot.
abstract class GoldenMismatch {
  GoldenMismatch({
    this.golden,
    this.screenshot,
  }) : assert(
          golden != null || screenshot != null,
          "A mismatch can only exist when there is at least one golden image, otherwise there's nothing to mismatch with anything else.",
        );

  /// The golden image that was previously generated and stored as the
  /// desired visual result.
  ///
  /// If [golden] it means that no existing golden was found, which corresponds
  /// to the [screenshot]. I.e., the new collection has an extra golden.
  final GoldenImage? golden;

  /// A golden image that was generated to compare to [golden].
  ///
  /// If [screenshot] is `null`, it means that the latest golden collection
  /// didn't render with an image that corresponds to [golden]. I.e., the
  /// new collection is missing this golden.
  final GoldenImage? screenshot;

  /// Describes the mismatch in a human-readable way.
  String get describe;

  /// Describes the mismatch with a structure that's useful for further processing.
  Map<String, dynamic> get describeStructured;

  @override
  String toString() => describe;
}
