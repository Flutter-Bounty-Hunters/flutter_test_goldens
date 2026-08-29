import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/src/png/png_metadata.dart';
import 'package:flutter_test_goldens/src/scenes/scene_file_extractor.dart';
import 'package:image/image.dart';
import 'package:path/path.dart' as path;

void main() {
  group("Scene file extractor >", () {
    group("extracting goldens from bytes >", () {
      test("returns each golden in scene order", () {
        final goldens = extractGoldensFromSceneBytes(_twoGoldenSceneBytes());

        expect(goldens.map((golden) => golden.order), [1, 2]);
        expect(goldens.map((golden) => golden.id), ["first", "second"]);
      });

      test("crops each golden's pixels", () {
        final goldens = extractGoldensFromSceneBytes(_twoGoldenSceneBytes());

        // The first golden is a 3x2 red region.
        final firstGolden = goldens[0].image;
        expect([firstGolden.width, firstGolden.height], [3, 2]);
        expect(_colorAt(firstGolden, 0, 0), [255, 0, 0]);
        expect(_colorAt(firstGolden, 2, 1), [255, 0, 0]);

        // The second golden is a differently sized 5x4 blue region, cropped from
        // a non-zero top-left offset within the scene.
        final secondGolden = goldens[1].image;
        expect([secondGolden.width, secondGolden.height], [5, 4]);
        expect(_colorAt(secondGolden, 0, 0), [0, 0, 255]);
        expect(_colorAt(secondGolden, 4, 3), [0, 0, 255]);
      });

      test("returns nothing for a PNG without scene metadata", () {
        expect(extractGoldensFromSceneBytes(_plainPngBytes()), isEmpty);
      });
    });

    group("extracting a scene file to images >", () {
      test("writes one file per golden next to the scene", () {
        final directory = Directory.systemTemp.createTempSync("scene_file_extractor_test");
        addTearDown(() => directory.deleteSync(recursive: true));
        final sceneFile = File(path.join(directory.path, "my_scene.png"))..writeAsBytesSync(_twoGoldenSceneBytes());

        final writtenFiles = extractSceneFileToImages(sceneFile);

        expect(writtenFiles.length, 2);
        expect(writtenFiles.every((file) => file.existsSync()), isTrue);
      });

      test("names files with scene name, order, and id", () {
        final directory = Directory.systemTemp.createTempSync("scene_file_extractor_test");
        addTearDown(() => directory.deleteSync(recursive: true));
        final sceneFile = File(path.join(directory.path, "my_scene.png"))..writeAsBytesSync(_twoGoldenSceneBytes());

        final writtenFiles = extractSceneFileToImages(sceneFile);

        expect(
          writtenFiles.map((file) => path.basename(file.path)),
          ["my_scene.01_first.png", "my_scene.02_second.png"],
        );
      });

      test("writes nothing for a PNG without scene metadata", () {
        final directory = Directory.systemTemp.createTempSync("scene_file_extractor_test");
        addTearDown(() => directory.deleteSync(recursive: true));
        final sceneFile = File(path.join(directory.path, "not_a_scene.png"))..writeAsBytesSync(_plainPngBytes());

        expect(extractSceneFileToImages(sceneFile), isEmpty);
        expect(directory.listSync().length, 1);
      });
    });
  });
}

/// Builds a golden scene PNG that contains two differently sized goldens: a
/// 3x2 red golden with ID "first" at (0, 0), and a 5x4 blue golden with ID
/// "second" at (3, 1).
///
/// The goldens use different sizes, and the second golden sits at a non-zero
/// top-left offset, to stress the cropping logic beyond trivial 1x1 regions.
Uint8List _twoGoldenSceneBytes() {
  const firstWidth = 3;
  const firstHeight = 2;
  const secondLeft = firstWidth;
  const secondTop = 1;
  const secondWidth = 5;
  const secondHeight = 4;

  final sceneWidth = firstWidth + secondWidth;
  final sceneHeight = secondTop + secondHeight;
  final sceneImage = Image(width: sceneWidth, height: sceneHeight);

  _fillRegion(sceneImage, left: 0, top: 0, width: firstWidth, height: firstHeight, red: 255, green: 0, blue: 0);
  _fillRegion(
    sceneImage,
    left: secondLeft,
    top: secondTop,
    width: secondWidth,
    height: secondHeight,
    red: 0,
    green: 0,
    blue: 255,
  );

  final sceneMetadata = {
    "description": "Test Scene",
    "images": [
      _goldenMetadata(id: "first", left: 0, top: 0, width: firstWidth, height: firstHeight),
      _goldenMetadata(id: "second", left: secondLeft, top: secondTop, width: secondWidth, height: secondHeight),
    ],
  };

  final pngBytes = Uint8List.fromList(encodePng(sceneImage));
  return pngBytes.copyWithTextMetadata("flutter_test_goldens", jsonEncode(sceneMetadata));
}

Map<String, dynamic> _goldenMetadata({
  required String id,
  required int left,
  required int top,
  required int width,
  required int height,
}) {
  return {
    "id": id,
    "metadata": {
      "description": id,
      "simulatedPlatform": "android",
    },
    "topLeft": {"x": left, "y": top},
    "size": {"width": width, "height": height},
  };
}

void _fillRegion(
  Image image, {
  required int left,
  required int top,
  required int width,
  required int height,
  required int red,
  required int green,
  required int blue,
}) {
  for (var y = top; y < top + height; y += 1) {
    for (var x = left; x < left + width; x += 1) {
      image.setPixelRgba(x, y, red, green, blue, 255);
    }
  }
}

/// Builds a regular 1x1 PNG that carries no golden scene metadata.
Uint8List _plainPngBytes() {
  final image = Image(width: 1, height: 1);
  image.setPixelRgba(0, 0, 0, 0, 0, 255);
  return Uint8List.fromList(encodePng(image));
}

List<num> _colorAt(Image image, int x, int y) {
  final pixel = image.getPixel(x, y);
  return [pixel.r, pixel.g, pixel.b];
}
