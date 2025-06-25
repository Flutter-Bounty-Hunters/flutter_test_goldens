import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as img;

/// A collection of in-memory goldens or candidates.
///
/// {@template golden_vs_candidate}
/// "Golden" refers to a screenshot that a developer has inspected, and confirmed
/// that is represents the desired result.
///
/// "Candidate" refers to the latest screenshot of a UI, which is expected to match a
/// corresponding golden.
/// {@endtemplate}
class ScreenshotCollection {
  ScreenshotCollection(this.screenshotsById);

  final Map<String, GoldenSceneScreenshot> screenshotsById;

  List<String> get ids => screenshotsById.keys.toList(growable: false);

  bool hasId(String id) => screenshotsById[id] != null;

  GoldenSceneScreenshot? operator [](Object key) => screenshotsById[key];
}

/// An in-memory golden screenshot or candidate screenshot.
///
/// {@macro golden_vs_candidate}
class GoldenSceneScreenshot {
  const GoldenSceneScreenshot(
    this.id,
    this.metadata,
    this.image,
    this.pngBytes,
  );

  /// Uniquely identifies this golden within a scene.
  final String id;

  /// Metadata about this screenshot, e.g., a human-readable description, simulated
  /// platform, etc.
  final GoldenScreenshotMetadata metadata;

  /// Structured image representation, which gives us the dimensions of the image,
  /// and lets us query individual pixel values.
  final img.Image image;

  /// Raw image bytes in a PNG format, which is needed to render the image using a
  /// traditional Flutter `Image.memory()` widget.
  final Uint8List pngBytes;

  Size get size => Size(image.width.toDouble(), image.height.toDouble());
}

class GoldenScreenshotMetadata {
  const GoldenScreenshotMetadata({
    required this.description,
    required this.simulatedPlatform,
  });

  /// A human-readable description of this golden.
  final String description;

  /// The simulated platform when the screenshot was taken, e.g., Android, iOS,
  /// Mac, Windows, Linux.
  ///
  /// This is *NOT* the same thing as the platform used to run the golden test suite.
  final TargetPlatform simulatedPlatform;

  GoldenScreenshotMetadata copyWith({
    String? description,
    TargetPlatform? simulatedPlatform,
  }) {
    return GoldenScreenshotMetadata(
      description: description ?? this.description,
      simulatedPlatform: simulatedPlatform ?? this.simulatedPlatform,
    );
  }
}
