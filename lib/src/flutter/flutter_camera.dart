import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/src/goldens/golden_rendering.dart';

/// A camera for taking screenshots of a Flutter UI.
class FlutterCamera {
  FlutterCamera();

  List<FlutterScreenshot> get photos => List.from(_photos);
  final _photos = <FlutterScreenshot>[];

  /// Takes a screenshot of the given [finder] and stores it in [photos] along with its [id].
  ///
  /// {@macro golden_image_bounds_default_finder}
  ///
  /// The image captures a screenshot of the entire widget tree, and then extracts the pixels
  /// within the [finder] region. This requires moving more pixel data, but this is done so
  /// that the photo captures widgets that sit in the app overlay, such as the mobile drag
  /// handles, magnifier, or popover toolbar for a text field.
  Future<void> takePhoto(String id, [Finder? finder]) async {
    final fullscreenRenderObject = find
        .byElementPredicate((element) => element.renderObject is RenderRepaintBoundary)
        .evaluate()
        .first
        .findRenderObject() as RenderRepaintBoundary?;
    if (fullscreenRenderObject == null) {
      throw Exception(
        "Tried to take a photo of a Flutter UI but the widget tree doesn't have any repaint boundaries. Can't take any screenshots.",
      );
    }

    final fullscreenPhoto = fullscreenRenderObject.toImageSync();

    final contentFinder = finder ?? find.byType(GoldenImageBounds);
    expect(finder, findsOne);
    final contentRenderObject = contentFinder.evaluate().first.findRenderObject();
    if (contentRenderObject is! RenderBox) {
      throw Exception(
        "Tried to take screenshot of $contentFinder but its render object is not a RenderBox. Can't take screenshot.",
      );
    }

    final contentPhoto = await _cropImage(
      fullscreenPhoto,
      contentRenderObject.localToGlobal(Offset.zero),
      contentRenderObject.size,
    );

    _photos.add(
      FlutterScreenshot(id, contentPhoto, defaultTargetPlatform),
    );
  }

  Future<Image> _cropImage(
    Image image,
    Offset topLeft,
    Size size,
  ) async {
    final top = topLeft.dy.round();
    final left = topLeft.dx.round();
    final width = size.width.round();
    final height = size.height.round();

    final byteData = await image.toByteData(format: ImageByteFormat.rawRgba);
    if (byteData == null) {
      throw Exception('Failed to get byte data from image');
    }

    final originalBytes = byteData.buffer.asUint8List();
    final bytesPerPixel = 4;
    final originalWidth = image.width;

    final croppedBytes = Uint8List(width * height * bytesPerPixel);

    for (int row = 0; row < height; row++) {
      final srcStart = ((top + row) * originalWidth + left) * bytesPerPixel;
      final destStart = row * width * bytesPerPixel;
      croppedBytes.setRange(
        destStart,
        destStart + width * bytesPerPixel,
        originalBytes,
        srcStart,
      );
    }

    final completer = Completer<Image>();
    decodeImageFromPixels(
      croppedBytes,
      width,
      height,
      PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
  }
}

/// An in-memory screenshot of a Flutter UI.
class FlutterScreenshot {
  const FlutterScreenshot(this.id, this.pixels, this.simulatedPlatform);

  final String id;
  final Image pixels;
  final TargetPlatform simulatedPlatform;

  Size get size => Size(pixels.width.toDouble(), pixels.height.toDouble());
}
