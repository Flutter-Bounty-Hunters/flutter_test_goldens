import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide Image;
import 'package:flutter/material.dart' as m;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/src/flutter/flutter_test_extensions.dart';
import 'package:flutter_test_goldens/src/goldens/golden_camera.dart';
import 'package:flutter_test_goldens/src/goldens/golden_collections.dart';
import 'package:flutter_test_goldens/src/goldens/golden_comparisons.dart';
import 'package:flutter_test_goldens/src/goldens/golden_rendering.dart';
import 'package:flutter_test_goldens/src/goldens/golden_scenes.dart';
import 'package:flutter_test_goldens/src/goldens/pixel_comparisons.dart';
import 'package:flutter_test_goldens/src/logging.dart';
import 'package:flutter_test_goldens/src/scenes/golden_scene.dart';
import 'package:flutter_test_goldens/src/scenes/scene_layout.dart';
import 'package:image/image.dart';
import 'package:qr_bar_code/code/code.dart';

/// A golden builder that takes screenshots over a period of time and
/// stitches them together into a single golden file with a given
/// [FilmStripLayout].
class FilmStrip {
  FilmStrip(
    this._tester, {
    required this.goldenName,
    required this.layout,
    this.goldenBackground,
  });

  final WidgetTester _tester;

  final String goldenName;
  final SceneLayout layout;
  final Widget? goldenBackground;

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
  FilmStrip setupWithPump(FilmStripSetupWithPumpFactory sceneBuilder) {
    if (_setup != null) {
      throw Exception("FilmStrip was already set up, but tried to call setupWithPump() again.");
    }

    _setup = _FilmStripSetup((tester) async {
      final widgetTree = sceneBuilder();
      await _tester.pumpWidget(widgetTree);
    });

    return this;
  }

  /// Take a golden photo screenshot of the current Flutter UI.
  FilmStrip takePhoto(Finder photoBoundsFinder, String description) {
    if (_setup == null) {
      throw Exception("Can't take a photo before setup. Please call setup() or setupWithPump()");
    }

    _steps.add(_FilmStripPhotoRequest(photoBoundsFinder, description));

    return this;
  }

  FilmStrip hoverOver(Finder finder, {bool pumpAndSettle = true}) {
    return modifyScene((tester, testContext) async {
      // Hover over the desired widget and store the gesture details for future
      // scene modifications.
      final (gesture, hoverPosition) = await tester.hoverOver(finder);
      testContext.activeGesture = gesture;
      testContext.activeGestureOffset = hoverPosition;

      if (pumpAndSettle) {
        await tester.pumpAndSettle();
      }
    });
  }

  FilmStrip pressHover({bool pumpAndSettle = true}) {
    return modifyScene((tester, testContext) async {
      // Press down where the active gesture currently resides.
      await testContext.activeGesture!.down(testContext.activeGestureOffset!);

      if (pumpAndSettle) {
        await tester.pumpAndSettle();
      }
    });
  }

  FilmStrip releaseHover({bool pumpAndSettle = true}) {
    return modifyScene((tester, testContext) async {
      // Release the active gesture.
      await testContext.activeGesture!.up();

      if (pumpAndSettle) {
        await tester.pumpAndSettle();
      }
    });
  }

  /// Change the scene in this [FilmStrip] to prepare to take another photo.
  FilmStrip modifyScene(FilmStripModifySceneDelegate delegate) {
    if (_setup == null) {
      throw Exception("Can't modify the scene before setup. Please call setup() or setupWithPump()");
    }

    _steps.add(_FilmStripModifySceneAction(delegate));

    return this;
  }

  Future<void> renderOrCompareGolden({
    m.Color qrCodeColor = m.Colors.black,
    m.Color qrCodeBackgroundColor = m.Colors.white,
  }) async {
    if (_setup == null) {
      throw Exception(
          "Can't render or compare golden file without a setup action. Please call setup() or setupWithPump().");
    }

    FtgLog.pipeline.info("Rendering or comparing golden - $goldenName");

    // Always operate at a 1:1 logical-to-physical pixel ratio to help reduce
    // anti-aliasing and other artifacts from fractional pixel offsets.
    _tester.view.devicePixelRatio = 1.0;

    final camera = GoldenCamera(_tester);
    final testContext = FilmStripTestContext();

    // Setup the scene.
    FtgLog.pipeline.info("Running any given setup delegate before running steps.");
    await _setup!.setupDelegate(_tester);

    // Take photos and modify scene over time.
    for (final step in _steps) {
      FtgLog.pipeline.info("Running step: $step");
      if (step is _FilmStripModifySceneAction) {
        await step.delegate(_tester, testContext);
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
        final byteData = await photo.pixels.toByteData(format: ui.ImageByteFormat.png);
        renderablePhotos[photo] = (byteData!.buffer.asUint8List(), GlobalKey());
      }
    });

    // Layout photos in the gallery so we can lookup their final offsets and sizes.
    var goldenMetadata = await _layoutPhotos(
      photos,
      renderablePhotos,
      layout,
      qrCodeBackgroundColor: qrCodeBackgroundColor,
    );

    // Layout photos one last time, this time adding the metadata QR code, which encodes
    // each photo's offset and size.
    goldenMetadata = await _layoutPhotos(
      photos,
      renderablePhotos,
      layout,
      goldenBackground: goldenBackground,
      qrCode: Code(
        data: const JsonEncoder().convert(goldenMetadata.toJson()),
        codeType: CodeType.qrCode(),
        color: qrCodeColor,
      ),
      qrCodeBackgroundColor: qrCodeBackgroundColor,
    );

    FtgLog.pipeline.finer("Running momentary delay for render flakiness");
    await _tester.runAsync(() async {
      // Without this delay, the screenshot loading is spotty. However, with
      // this delay, we seem to always get screenshots displayed in the widget tree.
      // FIXME: Root cause this render flakiness and see if we can fix it.
      await Future.delayed(const Duration(milliseconds: 1));
    });

    await _tester.pumpAndSettle();

    final goldenFileName = "$goldenName.png";
    if (autoUpdateGoldenFiles) {
      // Generate new goldens.
      FtgLog.pipeline.finer("Doing golden generation - window height: ${_tester.view.physicalSize.height}");
      await expectLater(find.byType(GoldenSceneBounds), matchesGoldenFile(goldenFileName));
    } else {
      // Compare to existing goldens.
      FtgLog.pipeline.finer("Comparing existing goldens...");
      await _compareGoldens(_tester, goldenFileName, find.byType(GoldenSceneBounds));
      FtgLog.pipeline.finer("Done comparing goldens for film strip");
    }

    FtgLog.pipeline.finer("Done with golden generation/comparison");
  }

  Future<GoldenSceneMetadata> _layoutPhotos(
    List<GoldenPhoto> photos,
    Map<GoldenPhoto, (Uint8List, GlobalKey)> renderablePhotos,
    SceneLayout layout, {
    Widget? goldenBackground,
    Widget? qrCode,
    required m.Color qrCodeBackgroundColor,
  }) async {
    // Layout the final strip within an OverflowBox to let it be whatever
    // size it wants. Then check the content render object for final dimensions.
    // Set the window size to match.

    late final Axis filmStripDirection;
    switch (layout) {
      case SceneLayout.row:
        filmStripDirection = Axis.horizontal;
      case SceneLayout.column:
        filmStripDirection = Axis.vertical;
    }

    // FIXME: When we're comparing existing goldens, we shouldn't need to actually
    //        run full golden layout, we should be able to directly compare the renderable
    //        images to the regions of the existing golden.

    final contentKey = GlobalKey();
    final galleryKey = GlobalKey();
    final qrCodeKey = GlobalKey();

    final filmStrip = _buildFilmStrip(
      filmStripDirection,
      contentKey,
      renderablePhotos,
      galleryKey: galleryKey,
      goldenBackground: goldenBackground,
      qrCodeKey: qrCodeKey,
      qrCode: qrCode,
      qrCodeBackgroundColor: qrCodeBackgroundColor,
    );

    await _tester.pumpWidgetAndAdjustWindow(filmStrip);

    await _tester.runAsync(() async {
      for (final entry in renderablePhotos.entries) {
        await precacheImage(
          MemoryImage(entry.value.$1),
          _tester.element(find.byKey(entry.value.$2)),
        );
      }
    });

    // Lookup and return metadata for the position and size of each golden image
    // within the gallery.
    return GoldenSceneMetadata(
      images: [
        for (final golden in renderablePhotos.keys)
          GoldenImageMetadata(
            id: golden.description,
            topLeft: (renderablePhotos[golden]!.$2.currentContext!.findRenderObject() as RenderBox)
                .localToGlobal(Offset.zero),
            size: renderablePhotos[golden]!.$2.currentContext!.size!,
          ),
      ],
    );
  }

  Widget _buildFilmStrip(
    Axis filmStripDirection,
    GlobalKey contentKey,
    Map<GoldenPhoto, (Uint8List, GlobalKey)> renderablePhotos, {
    Key? galleryKey,
    Widget? goldenBackground,
    Key? qrCodeKey,
    Widget? qrCode,
    required m.Color qrCodeBackgroundColor,
  }) {
    return GoldenSceneBounds(
      child: IntrinsicWidth(
        child: IntrinsicHeight(
          child: Column(
            key: contentKey,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GoldenScene(
                key: galleryKey,
                direction: filmStripDirection,
                renderablePhotos: renderablePhotos,
                background: goldenBackground,
              ),
              if (qrCode != null) //
                Container(
                  padding: const EdgeInsets.all(48),
                  color: qrCodeBackgroundColor,
                  child: Center(
                    child: SizedBox(
                      height: 200,
                      child: KeyedSubtree(
                        key: qrCodeKey,
                        child: qrCode,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _compareGoldens(WidgetTester tester, String existingGoldenFileName, Finder goldenBounds) async {
    final testFileDirectory = (goldenFileComparator as LocalFileComparator).basedir.path;
    final goldenFile = File("$testFileDirectory$existingGoldenFileName");

    if (!goldenFile.existsSync()) {
      // TODO: report error in structured way.
      throw Exception("Can't compare goldens. Golden file doesn't exist: ${goldenFile.path}");
    }

    FtgLog.pipeline.fine("Extracting golden collection from scene file (goldens).");
    final goldenCollection = extractGoldenCollectionFromSceneFile(goldenFile);

    FtgLog.pipeline.fine("Extracting golden collection from current widget tree (screenshots).");
    late final GoldenCollection screenshotCollection;
    await tester.runAsync(() async {
      screenshotCollection = await extractGoldenCollectionFromSceneWidgetTree(tester);
    });

    FtgLog.pipeline.fine("Comparing goldens and screenshots");
    final mismatches = compareGoldenCollections(goldenCollection, screenshotCollection);
    if (mismatches.mismatches.isNotEmpty) {
      FtgLog.pipeline.fine("Mismatches ($existingGoldenFileName):");
      for (final mismatch in mismatches.mismatches.values) {
        FtgLog.pipeline.fine(" - ${mismatch.golden?.id ?? mismatch.screenshot?.id}: $mismatch");
      }

      for (final mismatch in mismatches.mismatches.values) {
        if (mismatch.golden == null || mismatch.screenshot == null) {
          continue;
        }

        FtgLog.pipeline.fine("Painting a golden failure: $mismatch");
        final failureDirectory = Directory("${testFileDirectory}failures");
        failureDirectory.createSync();

        await tester.runAsync(() async {
          final goldenWidth = mismatch.golden!.image.width;
          final goldenHeight = mismatch.golden!.image.height;

          final screenshotWidth = mismatch.screenshot!.image.width;
          final screenshotHeight = mismatch.screenshot!.image.height;

          final maxWidth = max(goldenWidth, screenshotWidth);
          final maxHeight = max(goldenHeight, screenshotHeight);

          final failureImage = Image(
            width: maxWidth * 2,
            height: maxHeight * 2,
          );

          // Copy golden to top left corner.
          for (int x = 0; x < goldenWidth; x += 1) {
            for (int y = 0; y < goldenHeight; y += 1) {
              final goldenPixel = mismatch.golden!.image.getPixel(x, y);
              failureImage.setPixel(x, y, goldenPixel);
            }
          }

          // Copy screenshot to top right corner.
          for (int x = 0; x < screenshotWidth; x += 1) {
            for (int y = 0; y < screenshotHeight; y += 1) {
              final screenshotPixel = mismatch.screenshot!.image.getPixel(x, y);
              failureImage.setPixel(maxWidth + x, y, screenshotPixel);
            }
          }

          // Paint mismatch images.
          final absoluteDiffColor = ColorUint32.rgb(255, 255, 0);
          for (int x = 0; x < maxWidth; x += 1) {
            for (int y = 0; y < maxHeight; y += 1) {
              if (x >= goldenWidth || x >= screenshotWidth || y >= goldenHeight || y >= screenshotHeight) {
                // This pixel doesn't exist in the golden, or it doesn't exist in the
                // screenshot. Therefore, we have nothing to compare. Treat this pixel
                // as a max severity difference.

                // Paint this pixel in the absolute diff image.
                failureImage.setPixel(x, maxHeight + y, absoluteDiffColor);

                // Paint this pixel in the relative severity diff image.
                failureImage.setPixel(maxWidth + x, maxHeight + y, absoluteDiffColor);

                continue;
              }

              // Check if the screenshot matches the golden.
              final goldenPixel = mismatch.golden!.image.getPixel(x, y);
              final screenshotPixel = mismatch.screenshot!.image.getPixel(x, y);
              final pixelsMatch = goldenPixel == screenshotPixel;
              if (pixelsMatch) {
                continue;
              }

              // Paint this pixel in the absolute diff image.
              failureImage.setPixel(x, maxHeight + y, absoluteDiffColor);

              // Paint this pixel in the relative severity diff image.
              final mismatchPercent = calculateColorMismatchPercent(goldenPixel, screenshotPixel);
              final yellowAmount = ui.lerpDouble(0.2, 1.0, mismatchPercent)!;
              failureImage.setPixel(
                goldenWidth + x,
                goldenHeight + y,
                ColorUint32.rgb((255 * yellowAmount).round(), (255 * yellowAmount).round(), 0),
              );
            }
          }

          await encodePngFile(
            "${failureDirectory.path}/failure_${existingGoldenFileName}_${mismatch.golden!.id}.png",
            failureImage,
          );
        });
      }

      throw Exception("Goldens failed with ${mismatches.mismatches.length} mismatch(es)");
    } else {
      FtgLog.pipeline.info("No golden mismatches found");
    }
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

typedef FilmStripModifySceneDelegate = Future<void> Function(WidgetTester tester, FilmStripTestContext testContext);

class FilmStripTestContext {
  TestGesture? activeGesture;
  Offset? activeGestureOffset;

  final scratchPad = <String, dynamic>{};
}
