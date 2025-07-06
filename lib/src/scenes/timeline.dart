import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide Image;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/src/flutter/flutter_camera.dart';
import 'package:flutter_test_goldens/src/flutter/flutter_test_extensions.dart';
import 'package:flutter_test_goldens/src/goldens/golden_collections.dart';
import 'package:flutter_test_goldens/src/goldens/golden_comparisons.dart';
import 'package:flutter_test_goldens/src/goldens/golden_rendering.dart';
import 'package:flutter_test_goldens/src/goldens/golden_scenes.dart';
import 'package:flutter_test_goldens/src/goldens/pixel_comparisons.dart';
import 'package:flutter_test_goldens/src/logging.dart';
import 'package:flutter_test_goldens/src/png/png_metadata.dart';
import 'package:flutter_test_goldens/src/scenes/golden_scene.dart';
import 'package:flutter_test_goldens/src/scenes/scene_layout.dart';
import 'package:golden_bricks/golden_bricks.dart';
import 'package:image/image.dart' hide Color;
import 'package:path/path.dart';

/// A golden builder that takes screenshots over a period of time and
/// stitches them together into a single golden file with a given
/// [_layout].
class Timeline {
  Timeline(
    this._description, {
    Directory? directory,
    required String fileName,
    Size? windowSize,
    GoldenSceneItemScaffold itemScaffold = standardTimelineItemScaffold,
    required SceneLayout layout,
    GoldenSceneBackground? goldenBackground,
  })  : _directory = directory,
        _fileName = fileName,
        _windowSize = windowSize,
        _itemScaffold = itemScaffold,
        _layout = layout,
        _goldenBackground = goldenBackground;

  final String _description;

  late final Directory? _directory;
  final String _fileName;

  final Size? _windowSize;

  final GoldenSceneItemScaffold _itemScaffold;

  final GoldenSceneBackground? _goldenBackground;
  final SceneLayout _layout;

  _TimelineSetup? _setup;
  final _steps = <Object>[];

  /// Setup the scene before taking any photos.
  ///
  /// If you only need to provide a widget tree, without taking other [WidgetTester]
  /// actions, consider using [setupWithPump] for convenience.
  Timeline setup(TimelineSetupDelegate delegate) {
    if (_setup != null) {
      throw Exception("Timeline was already set up, but tried to call setup() again.");
    }

    _setup = _TimelineSetup((tester) async {
      _configureWindowSize(tester);

      await delegate(tester);
    });

    return this;
  }

  /// Setup the scene before taking any photos, by pumping a widget tree.
  ///
  /// If you need to take additional actions, beyond a single pump, use [setup] instead.
  Timeline setupWithPump(TimelineSetupWithPumpFactory sceneBuilder) {
    if (_setup != null) {
      throw Exception("Timeline was already set up, but tried to call setupWithPump() again.");
    }

    _setup = _TimelineSetup((tester) async {
      _configureWindowSize(tester);

      final widgetTree = _itemScaffold(tester, sceneBuilder());
      await tester.pumpWidget(widgetTree);
    });

    return this;
  }

  /// Setup the scene before taking any photos, by pumping a widget tree.
  ///
  /// If you need to take additional actions, beyond a single pump, use [setup] instead.
  Timeline setupWithWidget(Widget widget) {
    if (_setup != null) {
      throw Exception("Timeline was already set up, but tried to call setupWithWidget().");
    }

    _setup = _TimelineSetup((tester) async {
      _configureWindowSize(tester);

      final widgetTree = _itemScaffold(tester, widget);
      await tester.pumpWidget(widgetTree);
    });

    return this;
  }

  void _configureWindowSize(WidgetTester tester) {
    if (_windowSize != null) {
      final previousWindowSize = tester.view.physicalSize;
      tester.view.physicalSize = _windowSize;
      addTearDown(() => tester.view.physicalSize = previousWindowSize);
    }
  }

  /// Take a golden photo screenshot of the current Flutter UI.
  ///
  /// {@template golden_image_bounds_default_finder}
  /// If no [finder] is provided, then it's assumed that somewhere in the widget tree is
  /// a [GoldenImageBounds] widget. That widget is used as the boundary for this photo.
  /// If no such widget exists, an error is thrown.
  /// {@endtemplate}
  Timeline takePhoto(String description, [Finder? photoBoundsFinder]) {
    if (_setup == null) {
      throw Exception("Can't take a photo before setup. Please call setup() or setupWithPump()");
    }

    _steps.add(_TimelinePhotoRequest(photoBoundsFinder ?? find.byType(GoldenImageBounds), description));

    return this;
  }

  /// Take a series of [count] photos, waiting [timeBeforeEach] photo is taken.
  ///
  /// Each step is given a description equal to the given [baseName] with the step index
  /// appended to to, starting at "1". E.g., with a [baseName] of "step-", the steps would
  /// be called "step-1", "step-2", etc. If [baseName] is `null` then the description will
  /// consist only of the number, e.g., "1", "2", etc.
  Timeline takePhotos(int count, Duration timeBeforeEach, [String baseName = "", Finder? photoBoundsFinder]) {
    if (_setup == null) {
      throw Exception("Can't take a photo before setup. Please call setup() or setupWithPump()");
    }

    for (int i = 1; i <= count; i += 1) {
      wait(timeBeforeEach);
      takePhoto("$baseName$i", photoBoundsFinder);
    }

    return this;
  }

  Timeline wait(Duration duration) {
    return modifyScene((tester, testContext) async {
      await tester.pump(duration);
    });
  }

  Timeline settle() {
    return modifyScene((tester, testContext) async {
      await tester.pumpAndSettle();
    });
  }

  Timeline tap(Finder finder) {
    return modifyScene((tester, testContext) async {
      await tester.tap(finder);
    });
  }

  Timeline hoverOver(Finder finder, {bool pumpAndSettle = true}) {
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

  Timeline pressHover({bool pumpAndSettle = true}) {
    return modifyScene((tester, testContext) async {
      // Press down where the active gesture currently resides.
      await testContext.activeGesture!.down(testContext.activeGestureOffset!);

      if (pumpAndSettle) {
        await tester.pumpAndSettle();
      }
    });
  }

  Timeline releaseHover({bool pumpAndSettle = true}) {
    return modifyScene((tester, testContext) async {
      // Release the active gesture.
      await testContext.activeGesture!.up();

      if (pumpAndSettle) {
        await tester.pumpAndSettle();
      }
    });
  }

  /// Change the scene in this [Timeline] to prepare to take another photo.
  Timeline modifyScene(TimelineModifySceneDelegate delegate) {
    if (_setup == null) {
      throw Exception("Can't modify the scene before setup. Please call setup() or setupWithPump()");
    }

    _steps.add(_TimelineModifySceneAction(delegate));

    return this;
  }

  Future<void> run(WidgetTester tester) async {
    if (_setup == null) {
      throw Exception(
          "Can't render or compare golden file without a setup action. Please call setup() or setupWithPump().");
    }

    FtgLog.pipeline.info("Rendering or comparing golden - $_fileName");

    // Always operate at a 1:1 logical-to-physical pixel ratio to help reduce
    // anti-aliasing and other artifacts from fractional pixel offsets.
    tester.view.devicePixelRatio = 1.0;

    final camera = FlutterCamera();
    final testContext = TimelineTestContext();

    // Setup the scene.
    FtgLog.pipeline.info("Running any given setup delegate before running steps.");
    await _setup!.setupDelegate(tester);

    // Take photos and modify scene over time.
    for (int i = 0; i < _steps.length; i += 1) {
      final step = _steps[i];
      FtgLog.pipeline.info("Running step: $step");

      if (step is _TimelineModifySceneAction) {
        await step.delegate(tester, testContext);
        continue;
      }

      if (step is _TimelinePhotoRequest) {
        expect(step.photoBoundsFinder, findsOne);

        final renderObject = step.photoBoundsFinder.evaluate().first.findRenderObject();
        expect(
          renderObject,
          isNotNull,
          reason:
              "Failed to find a render object for photo '${step.description}', using finder '${step.photoBoundsFinder}'",
        );

        await tester.runAsync(() async {
          await camera.takePhoto(step.description, step.photoBoundsFinder);
        });

        continue;
      }

      throw Exception("Tried to run a step when rendering a Timeline, but we don't recognize this step type: $step");
    }

    // Lay out photos in a row.
    final photos = camera.photos;
    // TODO: cleanup the modeling of these photos vs renderable photos once things are working
    final renderablePhotos = <GoldenSceneScreenshot, GlobalKey>{};
    await tester.runAsync(() async {
      for (final photo in photos) {
        final byteData = (await photo.pixels.toByteData(format: ui.ImageByteFormat.png))!;

        final candidate = GoldenSceneScreenshot(
          // FIXME: When I refactored image modeling to become FlutterScreenshot and GoldenImage, I changed
          //        how IDs and descriptions were stored. The new structure worked fine for Galleries, where
          //        we already had an ID and a description. But timeline didn't appear to have an explicit
          //        ID for a given screenshot, so I gave the description as the "photo ID", which is why it's
          //        now used in 2 places here. We should probably create a first-class concept of an ID for
          //        a given timeline screenshot (independent from step index).
          photo.id,
          GoldenScreenshotMetadata(
            description: photo.id,
            simulatedPlatform: photo.simulatedPlatform,
          ),
          decodePng(byteData.buffer.asUint8List())!,
          byteData.buffer.asUint8List(),
        );

        renderablePhotos[candidate] = GlobalKey();
      }
    });

    // Layout photos in the timeline.
    final sceneMetadata = await _layoutPhotos(
      tester,
      photos,
      SceneLayoutContent(
        description: _description,
        goldens: renderablePhotos,
      ),
      _layout,
      goldenBackground: _goldenBackground,
    );

    FtgLog.pipeline.finer("Running momentary delay for render flakiness");
    await tester.runAsync(() async {
      // Without this delay, the screenshot loading is spotty. However, with
      // this delay, we seem to always get screenshots displayed in the widget tree.
      // FIXME: Root cause this render flakiness and see if we can fix it.
      await Future.delayed(const Duration(milliseconds: 1));
    });

    await tester.pumpAndSettle();

    final relativeGoldenFilePath = "$_relativeGoldenDirectory/$_fileName.png";
    if (autoUpdateGoldenFiles) {
      // Generate new goldens.
      await _updateGoldenScene(
        tester,
        relativeGoldenFilePath,
        sceneMetadata,
      );
    } else {
      // Compare to existing goldens.
      await _compareGoldens(
        tester,
        sceneMetadata,
        relativeGoldenFilePath,
        find.byType(GoldenSceneBounds),
      );
    }

    FtgLog.pipeline.finer("Done with golden generation/comparison");
  }

  Future<GoldenSceneMetadata> _layoutPhotos(
    WidgetTester tester,
    List<FlutterScreenshot> photos,
    SceneLayoutContent content,
    SceneLayout layout, {
    GoldenSceneBackground? goldenBackground,
  }) async {
    // Layout the final strip within an OverflowBox to let it be whatever
    // size it wants. Then check the content render object for final dimensions.
    // Set the window size to match.

    // FIXME: When we're comparing existing goldens, we shouldn't need to actually
    //        run full golden layout, we should be able to directly compare the renderable
    //        images to the regions of the existing golden.

    final contentKey = GlobalKey();
    final galleryKey = GlobalKey();

    final timeline = _buildTimeline(
      tester,
      contentKey,
      content,
      galleryKey: galleryKey,
      goldenBackground: goldenBackground,
    );

    await tester.pumpWidgetAndAdjustWindow(timeline);

    await tester.runAsync(() async {
      for (final entry in content.goldens.entries) {
        await precacheImage(
          MemoryImage(entry.key.pngBytes),
          tester.element(find.byKey(entry.value)),
        );
      }
    });

    // Lookup and return metadata for the position and size of each golden image
    // within the gallery.
    return GoldenSceneMetadata(
      description: _description,
      images: [
        for (final golden in content.goldens.keys)
          GoldenImageMetadata(
            id: golden.id,
            metadata: golden.metadata,
            topLeft:
                (content.goldens[golden]!.currentContext!.findRenderObject() as RenderBox).localToGlobal(Offset.zero),
            size: content.goldens[golden]!.currentContext!.size!,
          ),
      ],
    );
  }

  Future<void> _updateGoldenScene(
      WidgetTester tester, String relativeGoldenFilePath, GoldenSceneMetadata sceneMetadata) async {
    FtgLog.pipeline.finer("Doing golden generation - window height: ${tester.view.physicalSize.height}");
    await expectLater(find.byType(GoldenSceneBounds), matchesGoldenFile(_goldenFilePath()));

    final goldenFile = File(_goldenFilePath());
    var pngData = goldenFile.readAsBytesSync();
    pngData = pngData.copyWithTextMetadata(
      "flutter_test_goldens",
      JsonEncoder().convert(sceneMetadata.toJson()),
    );
    goldenFile.writeAsBytesSync(pngData);
  }

  Widget _buildTimeline(
    WidgetTester tester,
    GlobalKey contentKey,
    SceneLayoutContent content, {
    Key? galleryKey,
    GoldenSceneBackground? goldenBackground,
  }) {
    return Builder(builder: (context) {
      return _layout.build(tester, context, content);
    });
  }

  Future<void> _compareGoldens(
    WidgetTester tester,
    GoldenSceneMetadata sceneMetadata,
    String relativeGoldenFilePath,
    Finder goldenBounds,
  ) async {
    FtgLog.pipeline.finer("Comparing existing goldens...");

    FtgLog.pipeline.fine("Extracting golden collection from scene file (goldens).");
    final testFileDirectory = (goldenFileComparator as LocalFileComparator).basedir.path;
    final goldenFile = File(_goldenFilePath());
    if (!goldenFile.existsSync()) {
      // TODO: report error in structured way.
      throw Exception("Can't compare goldens. Golden file doesn't exist: ${goldenFile.path}");
    }
    final goldenCollection = extractGoldenCollectionFromSceneFile(goldenFile);

    FtgLog.pipeline.fine("Extracting golden collection from current widget tree (screenshots).");
    late final ScreenshotCollection screenshotCollection;
    await tester.runAsync(() async {
      screenshotCollection = await extractGoldenCollectionFromSceneWidgetTree(tester, sceneMetadata);
    });

    FtgLog.pipeline.fine("Comparing goldens and screenshots");
    final mismatches = compareGoldenCollections(goldenCollection, screenshotCollection);
    if (mismatches.mismatches.isNotEmpty) {
      FtgLog.pipeline.fine("Mismatches ($relativeGoldenFilePath):");
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
            "${failureDirectory.path}/failure_${relativeGoldenFilePath}_${mismatch.golden!.id}.png",
            failureImage,
          );
        });
      }

      throw Exception("Goldens failed with ${mismatches.mismatches.length} mismatch(es)");
    } else {
      FtgLog.pipeline.info("No golden mismatches found");
    }

    FtgLog.pipeline.finer("Done comparing goldens for timeline");
  }

  String get _testFileDirectory => (goldenFileComparator as LocalFileComparator).basedir.path;

  String get _goldenDirectory => "$_testFileDirectory$_relativeGoldenDirectory$separator";

  String get _relativeGoldenDirectory => _directory?.path ?? GoldenSceneTheme.current.directory.path;

  /// Calculates and returns a complete file path to the golden file specified by
  /// this gallery, which consists of the current test file directory + an optional
  /// golden subdirectory + the golden file name.
  String _goldenFilePath([bool includeExtension = true]) =>
      "$_goldenDirectory$_fileName${includeExtension ? ".png" : ""}";
}

class _TimelineSetup {
  const _TimelineSetup(this.setupDelegate);

  final TimelineSetupDelegate setupDelegate;
}

typedef TimelineSetupDelegate = Future<void> Function(WidgetTester tester);

typedef TimelineSetupWithPumpFactory = Widget Function();

class _TimelinePhotoRequest {
  const _TimelinePhotoRequest(this.photoBoundsFinder, this.description);

  final Finder photoBoundsFinder;
  final String description;
}

class _TimelineModifySceneAction {
  const _TimelineModifySceneAction(this.delegate);

  final TimelineModifySceneDelegate delegate;
}

typedef TimelineModifySceneDelegate = Future<void> Function(WidgetTester tester, TimelineTestContext testContext);

class TimelineTestContext {
  TestGesture? activeGesture;
  Offset? activeGestureOffset;

  final scratchPad = <String, dynamic>{};
}

/// The standard [GoldenSceneItemScaffold] that wraps the content of a [Timeline], which
/// includes a dark theme, a dark background color, and some padding around the content.
Widget standardTimelineItemScaffold(WidgetTester tester, Widget content) {
  return MaterialApp(
    theme: ThemeData(
      brightness: Brightness.dark,
      fontFamily: goldenBricks,
    ),
    home: Center(
      child: ColoredBox(
        color: Color(0xff020817),
        child: GoldenImageBounds(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: content,
          ),
        ),
      ),
    ),
    debugShowCheckedModeBanner: false,
  );
}

/// An absolute minimal [GoldenSceneItemScaffold] that wraps the content within a [Timeline].
Widget minimalTimelineItemScaffold(WidgetTester tester, Widget content) {
  return MaterialApp(
    theme: ThemeData(
      fontFamily: goldenBricks,
    ),
    home: Center(
      child: GoldenImageBounds(
        child: content,
      ),
    ),
    debugShowCheckedModeBanner: false,
  );
}
