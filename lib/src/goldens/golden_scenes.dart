import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/flutter_test_goldens.dart';
import 'package:flutter_test_goldens/src/png/png_metadata.dart';
import 'package:image/image.dart';

/// Extracts a [GoldenCollection] from a golden scene within the given image [file].
///
/// A golden scene is an image that contains some number of individual golden files within it.
/// In other words, a single image contains (possibly) many different golden images.
///
/// This function loads the scene image from the [file], extracts each individual golden
/// image from the scene, and then returns all of those golden images as a [GoldenCollection].
GoldenCollection extractGoldenCollectionFromSceneFile(File file) {
  FtgLog.pipeline.fine("Extracting golden collection from golden image.");

  // Read the scene PNG data into memory.
  final scenePngBytes = file.readAsBytesSync();

  // Extract scene metadata from PNG.
  final sceneMetadata = _extractGoldenSceneMetadataFromBytes(scenePngBytes);
  if (sceneMetadata == null) {
    throw Exception("Golden image is missing scene metadata: ${file.path}");
  }

  // Decode PNG data to an image.
  final sceneImage = decodePng(scenePngBytes);
  if (sceneImage == null) {
    // TODO: report error in structured way.
    throw Exception("Failed to decode golden scene as a PNG.");
  }

  // Extract the golden images from the scene image.
  return _extractCollectionFromScene(sceneMetadata, sceneImage);
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
Future<GoldenCollection> extractGoldenCollectionFromSceneWidgetTree(
  WidgetTester tester,
  GoldenSceneMetadata sceneMetadata, [
  Finder? sceneBounds,
]) async {
  FtgLog.pipeline.fine("Extracting golden collection from widget tree.");
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
  return _extractCollectionFromScene(sceneMetadata, treeImage);
}

/// Extracts then golden scene metadata within the given image [file].
GoldenSceneMetadata extractGoldenSceneMetadataFromFile(File file) {
  // Read the scene PNG data into memory.
  final scenePngBytes = file.readAsBytesSync();

  // Extract scene metadata from PNG.
  final sceneMetadata = _extractGoldenSceneMetadataFromBytes(scenePngBytes);
  if (sceneMetadata == null) {
    throw Exception("Golden image is missing scene metadata: ${file.path}");
  }

  return sceneMetadata;
}

GoldenSceneMetadata? _extractGoldenSceneMetadataFromBytes(Uint8List pngBytes) {
  // Extract scene metadata from PNG.
  final pngText = pngBytes.readTextMetadata();
  final sceneJsonText = pngText["flutter_test_goldens"];
  if (sceneJsonText == null) {
    return null;
  }
  final sceneJson = JsonDecoder().convert(sceneJsonText);
  return GoldenSceneMetadata.fromJson(sceneJson);
}

GoldenCollection _extractCollectionFromScene(GoldenSceneMetadata sceneMetadata, Image sceneImage) {
  // Cut each golden image out of the scene.
  final goldenImages = <String, GoldenImage>{};
  for (final imageRegion in sceneMetadata.images) {
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
      description: json["description"] ?? "",
      images: [
        for (final imageJson in (json["images"] as List<dynamic>)) //
          GoldenImageMetadata.fromJson(imageJson),
      ],
    );
  }

  const GoldenSceneMetadata({
    required this.description,
    required this.images,
  });

  final String description;
  final List<GoldenImageMetadata> images;

  Map<String, dynamic> toJson() {
    return {
      "description": description,
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
