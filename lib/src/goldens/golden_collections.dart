import 'dart:ui';

import 'package:flutter_test_goldens/src/goldens/golden_scenes.dart';
import 'package:image/image.dart' as img;

/// A collection of in-memory golden images or screenshot images.
///
/// {@template golden_vs_screenshot}
/// A "golden" image refers to an image that a developer has inspected, and confirmed
/// that is represents the desired result.
///
/// A "screenshot" refers to the latest image of a UI, which is expected to match a
/// corresponding golden image.
/// {@endtemplate}
class GoldenCollection {
  GoldenCollection(this.imagesById);

  final Map<String, GoldenImage> imagesById;

  List<String> get ids => imagesById.keys.toList(growable: false);

  bool hasId(String id) => imagesById[id] != null;

  GoldenImage? operator [](Object key) => imagesById[key];
}

/// An in-memory golden image or screenshot image.
///
/// {@macro golden_vs_screenshot}
class GoldenImage {
  const GoldenImage(this.id, this.image);

  final String id;
  final img.Image image;

  Size get size => Size(image.width.toDouble(), image.height.toDouble());
}
