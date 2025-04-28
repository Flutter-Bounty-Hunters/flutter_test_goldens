import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/src/goldens/golden_collections.dart';
import 'package:flutter_test_goldens/src/goldens/golden_rendering.dart';
import 'package:flutter_test_goldens/src/qr_codes/qr_code_image_scanning.dart';
import 'package:image/image.dart';

/// Extracts a [GoldenCollection] from a golden scene within the given image [file].
///
/// A golden scene is an image that contains some number of individual golden files within it.
/// In other words, a single image contains (possibly) many different golden images.
///
/// This function loads the scene image from the [file], extracts each individual golden
/// image from the scene, and then returns all of those golden images as a [GoldenCollection].
GoldenCollection extractGoldenCollectionFromSceneFile(File file) {
  print("Extracting golden collection from golden image.");

  // Load the scene image into memory.
  final sceneImage = decodePng(file.readAsBytesSync());
  if (sceneImage == null) {
    // TODO: report error in structured way.
    throw Exception("Failed to load existing golden image.");
  }

  // Extract the golden images from the scene image.
  return _extractCollectionFromScene(sceneImage);
}

/// Extracts a [GoldenCollection] from a golden scene within the current widget tree.
///
/// A golden scene is an image that contains some number of individual golden files within it.
/// In other words, a single image contains (possibly) many different golden images.
///
/// This function screenshots the part of the Flutter UI within the given [sceneBounds], extracts
/// each individual golden image from the scene, and then returns all of those golden images as
/// a [GoldenCollection].
///
/// WARNING: When running this method within a test suite, this method must be run with
/// `tester.runAsync()` because this method moves image data from the Flutter engine to
/// the framework, which can only happen with real async support, which is otherwise
/// disabled in tests. If your test hangs, this is probably why.
///
/// ```dart
///   late final GoldenCollection collection;
///   await tester.runAsync(() async {
///     collection = await extractGoldenCollectionFromSceneWidgetTree(tester);
///   });
/// ```
Future<GoldenCollection> extractGoldenCollectionFromSceneWidgetTree(WidgetTester tester, [Finder? sceneBounds]) async {
  print("Extracting golden collection from widget tree.");
  final renderRepaintBoundary = _findNearestRepaintBoundary(sceneBounds ?? find.byType(GoldenSceneBounds));
  if (renderRepaintBoundary == null) {
    // TODO: use structured error
    throw Exception(
      "Can't create golden collection from widget tree because we couldn't find a repaint boundary at or above the given bounds finder: $sceneBounds",
    );
  }

  // Screenshot the widget tree.
  final treeFlutterImage = renderRepaintBoundary.toImageSync();
  final treeRawImageData = (await treeFlutterImage.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  final treeImage = decodePng(treeRawImageData)!;

  // Extract the golden images from the scene image.
  return _extractCollectionFromScene(treeImage);
}

GoldenCollection _extractCollectionFromScene(Image sceneImage) {
  // Extract the scene metadata from the screenshot.
  final qrCode = sceneImage.readQrCode();
  final json = JsonDecoder().convert(qrCode.text);
  final scene = GoldenSceneMetadata.fromJson(json);

  // Cut each golden image out of the scene.
  final goldenImages = <String, GoldenImage>{};
  for (final imageRegion in scene.images) {
    goldenImages[imageRegion.id] = GoldenImage(
      imageRegion.id,
      copyCrop(
        sceneImage,
        x: imageRegion.topLeft.dx.round(),
        y: imageRegion.topLeft.dy.round(),
        width: imageRegion.size.width.round(),
        height: imageRegion.size.height.round(),
      ),
    );
  }

  return GoldenCollection(goldenImages);
}

RenderRepaintBoundary? _findNearestRepaintBoundary(Finder bounds) {
  print("Widget tree bounds: ${bounds.evaluate().firstOrNull}");
  var renderObject = bounds.evaluate().single.renderObject!;
  while (renderObject is! RenderRepaintBoundary && renderObject.parent != null) {
    renderObject = renderObject.parent!;
  }

  return renderObject is RenderRepaintBoundary ? renderObject : null;
}

/// Metadata that describes the golden images that appear in a given scene, such as each
/// golden's position and size.
///
/// A golden scene only exists after rendering golden images to a widget tree or a file.
/// This is because golden images don't have any particular offset or size until they're
/// positioned in a scene. To work with a related set of golden images that aren't currently
/// displayed in a widget tree or an image file, use [GoldenCollection].
///
/// [GoldenSceneMetadata] is used, for example, to extract golden images from a golden scene
/// file, and create a [GoldenCollection] to run golden comparisons.
///
/// [GoldenSceneMetadata] does NOT contain golden pixel data - it only tells you where to
/// find golden pixels within a scene image.
class GoldenSceneMetadata {
  static GoldenSceneMetadata fromJson(Map<String, dynamic> json) {
    return GoldenSceneMetadata(
      images: [
        for (final imageJson in (json["images"] as List<dynamic>)) //
          GoldenImageMetadata.fromJson(imageJson),
      ],
    );
  }

  const GoldenSceneMetadata({
    required this.images,
  });

  final List<GoldenImageMetadata> images;

  Map<String, dynamic> toJson() {
    return {
      "images": images.map((image) => image.toJson()).toList(growable: false),
    };
  }
}

/// Metadata that describes an individual image in a golden scene.
///
/// [GoldenImageMetadata] does NOT contain golden pixel data - it only tells you where to
/// find golden pixels within a scene image.
class GoldenImageMetadata {
  static GoldenImageMetadata fromJson(Map<String, dynamic> json) {
    return GoldenImageMetadata(
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

  const GoldenImageMetadata({
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
