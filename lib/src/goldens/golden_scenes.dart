import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/flutter_test_goldens.dart';
import 'package:flutter_test_goldens/src/png/png_metadata.dart';
import 'package:image/image.dart';

/// Extracts a [ScreenshotCollection] from a golden scene within the given image [file].
///
/// A golden scene is an image that contains some number of individual golden files within it.
/// In other words, a single image contains (possibly) many different golden images.
///
/// This function loads the scene image from the [file], extracts each individual golden
/// image from the scene, and then returns all of those golden images as a [ScreenshotCollection].
ScreenshotCollection extractGoldenCollectionFromSceneFile(File file) {
  FtgLog.pipeline.fine("Extracting golden collection from golden image.");

  // Read the scene PNG data into memory.
  final scenePngBytes = file.readAsBytesSync();

  // Extract scene metadata from PNG.
  final pngText = scenePngBytes.readTextMetadata();
  final sceneJsonText = pngText["flutter_test_goldens"];
  if (sceneJsonText == null) {
    throw Exception("Golden image is missing scene metadata: ${file.path}");
  }

  final sceneJson = JsonDecoder().convert(sceneJsonText);
  late final GoldenSceneMetadata sceneMetadata;
  try {
    sceneMetadata = GoldenSceneMetadata.fromJson(sceneJson);
  } catch (exception, stackTrace) {
    throw Error.throwWithStackTrace(Exception('''
Failed to parse scene metadata for file: ${file.uri}. 

Originating exception: $exception

The given stack trace belongs to the originating exception.

Scene JSON:
${const JsonEncoder.withIndent("  ").convert(sceneJson)}'''), stackTrace);
  }

  // Decode PNG data to an image.
  final sceneImage = decodePng(scenePngBytes);
  if (sceneImage == null) {
    // TODO: report error in structured way.
    throw Exception("Failed to decode golden scene as a PNG.");
  }

  // Extract the golden images from the scene image.
  print("Extracting goldens from file...");
  return _extractCollectionFromScene(sceneMetadata, sceneImage);
}

/// Extracts a [ScreenshotCollection] from a golden scene within the current widget tree.
///
/// A golden scene is an image that contains some number of individual golden files within it.
/// In other words, a single image contains (possibly) many different golden images.
///
/// This function screenshots the part of the Flutter UI within the given [sceneBounds], extracts
/// each individual golden image from the scene, and then returns all of those golden images as
/// a [ScreenshotCollection].
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
Future<ScreenshotCollection> extractGoldenCollectionFromSceneWidgetTree(
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
  print("Extracting candidates from widget tree...");
  return _extractCollectionFromScene(sceneMetadata, treeImage);
}

ScreenshotCollection _extractCollectionFromScene(GoldenSceneMetadata sceneMetadata, Image sceneImage) {
  // Cut each golden image out of the scene.
  print("Extracting screenshots from a scene (maybe goldens, maybe candidates):");
  final goldenImages = <String, GoldenSceneScreenshot>{};
  for (final golden in sceneMetadata.images) {
    final image = copyCrop(
      sceneImage,
      x: golden.topLeft.dx.round(),
      y: golden.topLeft.dy.round(),
      width: golden.size.width.round(),
      height: golden.size.height.round(),
    );
    print(
        " - ${golden.id} - offset: ${golden.topLeft}, size: ${golden.size}, extracted image size: Size(${image.width}, ${image.height})");

    goldenImages[golden.id] = GoldenSceneScreenshot(
      golden.id,
      golden.metadata,
      image,
      image.getBytes(),
    );
  }
  print("----");

  return ScreenshotCollection(goldenImages);
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
/// displayed in a widget tree or an image file, use [ScreenshotCollection].
///
/// [GoldenSceneMetadata] is used, for example, to extract golden images from a golden scene
/// file, and create a [ScreenshotCollection] to run golden comparisons.
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
      metadata: GoldenScreenshotMetadata(
        description: json["metadata"]["description"],
        simulatedPlatform: _parseTargetPlatform(json["metadata"]["simulatedPlatform"]),
      ),
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
    required this.metadata,
    required this.topLeft,
    required this.size,
  });

  final String id;
  final GoldenScreenshotMetadata metadata;
  final ui.Offset topLeft;
  final ui.Size size;

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "metadata": {
        "description": metadata.description,
        "simulatedPlatform": metadata.simulatedPlatform.name,
      },
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

TargetPlatform _parseTargetPlatform(String name) {
  for (final platform in TargetPlatform.values) {
    if (platform.name == name) {
      return platform;
    }
  }

  throw Exception("Unknown TargetPlatform: $name");
}
