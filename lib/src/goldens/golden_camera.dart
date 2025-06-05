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
  Future<void> takePhoto(String description, [Finder? finder]) async {
    finder = finder ?? find.byType(GoldenImageBounds);

    expect(finder, findsOne);

    final renderObject = finder.evaluate().first.findRenderObject();
    late final Image photo;
    if (renderObject!.isRepaintBoundary) {
      // The render object that we want to screenshot is already a repaint boundary,
      // so we can directly request an image from it.
      final repaintBoundary = finder.evaluate().first.renderObject! as RenderRepaintBoundary;
      photo = await repaintBoundary.toImage(pixelRatio: 1.0);
    } else {
      // The render object that we want to screenshot is NOT a repaint boundary, so we need
      // to screenshot the entire UI and then extract the region belonging to this widget.
      if (renderObject is! RenderBox) {
        throw Exception(
          "Can't take screenshot because the root of the widget tree isn't a RenderBox. It's a ${renderObject.runtimeType}",
        );
      }

      // TODO: Try the following approach. It probably doesn't work because we're
      //       using a TestRecordingPaintingContext with a non-test version of Canvas.
      //       But maybe it will work out.
      final pictureRecorder = PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      final screenSize = renderObject.size;

      final paintingContext = TestRecordingPaintingContext(canvas);
      renderObject.paint(paintingContext, Offset.zero);

      photo = await pictureRecorder.endRecording().toImage(
            screenSize.width.round(),
            screenSize.height.round(),
          );
    }

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
