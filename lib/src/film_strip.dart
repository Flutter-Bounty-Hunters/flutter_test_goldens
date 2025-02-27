import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/src/golden_camera.dart';

/// A golden builder that takes screenshots over a period of time and
/// stitches them together into a single golden file with a given
/// [FilmStripLayout].
class FilmStrip {
  FilmStrip(this._tester);

  final WidgetTester _tester;

  _FilmStripSetup? _setup;
  final _steps = <Object>[];

  /// Setup the scene before taking any photos.
  ///
  /// If you only need to provide a widget tree, without taking other [WidgetTester]
  /// actions, consider using [setupWithPump] for convenience.
  FilmStrip setup(FilmStripSetupDelegate delegate) {
    if (_setup != null) {
      throw Exception("FilmStrip was already set up, but tried to call setup() again.");
    }

    _setup = _FilmStripSetup(delegate);

    return this;
  }

  /// Setup the scene before taking any photos, by pumping a widget tree.
  ///
  /// If you need to take additional actions, beyond a single pump, use [setup] instead.
  FilmStrip setupWithPump(FilmStripSetupWithPumpFactory factory) {
    if (_setup != null) {
      throw Exception("FilmStrip was already set up, but tried to call setupWithPump() again.");
    }

    _setup = _FilmStripSetup((tester) async {
      final widgetTree = factory();
      await _tester.pumpWidget(widgetTree);
    });

    return this;
  }

  /// Take a golden photo screenshot of the current Flutter UI, given the
  /// setup and any modifications since then.
  FilmStrip takePhoto(Finder photoBoundsFinder, String description) {
    if (_setup == null) {
      throw Exception("Can't take a photo before setup. Please call setup() or setupWithPump()");
    }

    _steps.add(_FilmStripPhotoRequest(photoBoundsFinder, description));

    return this;
  }

  /// Change the scene in this [FilmStrip] to prepare to take another photo.
  FilmStrip modifyScene(FilmStripModifySceneDelegate delegate) {
    if (_setup == null) {
      throw Exception("Can't modify the scene before setup. Please call setup() or setupWithPump()");
    }

    _steps.add(_FilmStripModifySceneAction(delegate));

    return this;
  }

  Future<void> renderOrCompareGolden(String goldenName, FilmStripLayout layout) async {
    if (_setup == null) {
      throw Exception(
          "Can't render or compare golden file without a setup action. Please call setup() or setupWithPump().");
    }

    final camera = GoldenCamera(_tester);
    final scratchPad = <Object, dynamic>{};

    // Setup the scene.
    await _setup!.setupDelegate(_tester);

    // Take photos and modify scene over time.
    for (final step in _steps) {
      if (step is _FilmStripModifySceneAction) {
        await step.delegate(_tester, scratchPad);
        continue;
      }

      if (step is _FilmStripPhotoRequest) {
        expect(step.photoBoundsFinder, findsOne);

        final renderObject = step.photoBoundsFinder.evaluate().first.findRenderObject();
        expect(
          renderObject,
          isNotNull,
          reason:
              "Failed to find a render object for photo '${step.description}', using finder '${step.photoBoundsFinder}'",
        );

        await camera.takePhoto(step.photoBoundsFinder, step.description);

        continue;
      }

      throw Exception("Tried to run a step when rendering a FilmStrip, but we don't recognize this step type: $step");
    }

    // Lay out photos in a row.
    final photos = camera.photos;
    // TODO: cleanup the modeling of these photos vs renderable photos once things are working
    final renderablePhotos = <GoldenPhoto, (Uint8List, GlobalKey)>{};
    await _tester.runAsync(() async {
      for (final photo in photos) {
        final byteData = await photo.pixels.toByteData(format: ImageByteFormat.png);
        renderablePhotos[photo] = (byteData!.buffer.asUint8List(), GlobalKey());
      }
    });

    await _layoutPhotos(photos, renderablePhotos, layout);

    await _tester.runAsync(() async {
      // Without this delay, the screenshot loading is spotty. However, with
      // this delay, we seem to always get screenshots displayed in the widget tree.
      await Future.delayed(const Duration(milliseconds: 1));
    });

    await _tester.pumpAndSettle();

    await expectLater(find.byType(MaterialApp), matchesGoldenFile("$goldenName.png"));
  }

  Future<void> _layoutPhotos(
    List<GoldenPhoto> photos,
    Map<GoldenPhoto, (Uint8List, GlobalKey)> renderablePhotos,
    FilmStripLayout layout,
  ) async {
    // Layout the final strip within an OverflowBox to let it be whatever
    // size it wants. Then check the content render object for final dimensions.
    // Set the window size to match.

    late final Size filmStripSize;
    late final Axis filmStripDirection;
    switch (layout) {
      case FilmStripLayout.row:
        filmStripSize = Size(
          photos.fold(0, (width, photo) => width + photo.pixels.width.toDouble()),
          photos.fold(0, (maxHeight, photo) => max(maxHeight, photo.pixels.height.toDouble())),
        );
        filmStripDirection = Axis.horizontal;

      case FilmStripLayout.column:
        filmStripSize = Size(
          photos.fold(0, (maxWidth, photo) => max(maxWidth, photo.pixels.width.toDouble())),
          photos.fold(0, (height, photo) => height + photo.pixels.height.toDouble()),
        );
        filmStripDirection = Axis.vertical;
    }

    _tester.view //
      ..physicalSize = filmStripSize
      ..devicePixelRatio = 1.0;

    await _tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Color(0xFF222222),
          body: Center(
            child: Flex(
              direction: filmStripDirection,
              children: [
                for (final entry in renderablePhotos.entries) //
                  Image.memory(
                    key: entry.value.$2,
                    entry.value.$1,
                    width: entry.key.pixels.width.toDouble(),
                    height: entry.key.pixels.height.toDouble(),
                  ),
              ],
            ),
          ),
        ),
        debugShowCheckedModeBanner: false,
      ),
    );

    await _tester.runAsync(() async {
      for (final entry in renderablePhotos.entries) {
        await precacheImage(
          MemoryImage(entry.value.$1),
          _tester.element(find.byKey(entry.value.$2)),
        );
      }
    });
  }
}

class _FilmStripSetup {
  const _FilmStripSetup(this.setupDelegate);

  final FilmStripSetupDelegate setupDelegate;
}

typedef FilmStripSetupDelegate = Future<void> Function(WidgetTester tester);

typedef FilmStripSetupWithPumpFactory = Widget Function();

class _FilmStripPhotoRequest {
  const _FilmStripPhotoRequest(this.photoBoundsFinder, this.description);

  final Finder photoBoundsFinder;
  final String description;
}

class _FilmStripModifySceneAction {
  const _FilmStripModifySceneAction(this.delegate);

  final FilmStripModifySceneDelegate delegate;
}

typedef FilmStripModifySceneDelegate = Future<void> Function(WidgetTester tester, Map<Object, dynamic> scratchPad);

enum FilmStripLayout {
  row,
  column;
}
