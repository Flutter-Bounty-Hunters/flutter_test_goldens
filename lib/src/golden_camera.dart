import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// A camera for taking golden screenshots and storing them for later reference.
class GoldenCamera {
  List<GoldenPhoto> get photos => List.from(_photos);
  final _photos = <GoldenPhoto>[];

  /// Takes a screenshot of the given [finder] and stores it in [photos]
  /// along with its [description].
  Future<void> takePhoto(Finder finder, String description) async {
    expect(finder, findsOne);

    final repaintBoundary = finder.evaluate().first.renderObject! as RenderRepaintBoundary;
    final pixels = await repaintBoundary.toImage(pixelRatio: 1.0);

    _photos.add(
      GoldenPhoto(description, pixels),
    );
  }
}

/// A golden screenshot along with a description.
class GoldenPhoto {
  const GoldenPhoto(this.description, this.pixels);

  final String description;
  final Image pixels;
}
