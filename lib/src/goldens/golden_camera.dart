import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_test_goldens/src/goldens/golden_rendering.dart';

/// A camera for taking golden screenshots and storing them for later reference.
class GoldenCamera {
  GoldenCamera();

  List<GoldenPhoto> get photos => List.from(_photos);
  final _photos = <GoldenPhoto>[];

  /// Takes a screenshot of the given [finder] and stores it in [photos]
  /// along with its [description].
  ///
  /// {@macro golden_image_bounds_default_finder}
  ///
  /// The photo captures a screenshot of the entire widget tree, and then extracts the pixels
  /// within the [finder] region. This requires moving more pixel data, but this is done so
  /// that the photo captures widgets that sit in the app overlay, such as the mobile drag
  /// handles, magnifier, or popover toolbar for a text field.
  Future<void> takePhoto(String description, [Finder? finder]) async {
    finder = finder ?? find.byType(GoldenImageBounds);

    expect(finder, findsOne);

    final renderObject = finder.evaluate().first.findRenderObject();
    late final Image photo;
    if (renderObject is! RenderBox) {
      throw Exception(
        "Can't take screenshot because the root of the widget tree isn't a RenderBox. It's a ${renderObject.runtimeType}",
      );
    }

    final pictureRecorder = PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final screenSize = renderObject.size;

    final paintingContext = TestRecordingPaintingContext(canvas);
    renderObject.paint(paintingContext, Offset.zero);

    photo = await pictureRecorder.endRecording().toImage(
          screenSize.width.round(),
          screenSize.height.round(),
        );

    _photos.add(
      GoldenPhoto(description, photo),
    );
  }
}

/// A golden screenshot along with a description.
class GoldenPhoto {
  const GoldenPhoto(this.description, this.pixels);

  final String description;
  final Image pixels;
}
