import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/golden_bricks.dart';
import 'package:flutter_test_goldens/src/flutter/flutter_test_extensions.dart';
import 'package:flutter_test_goldens/src/goldens/golden_camera.dart';
import 'package:flutter_test_goldens/src/goldens/golden_collections.dart';
import 'package:flutter_test_goldens/src/goldens/golden_comparisons.dart';
import 'package:flutter_test_goldens/src/goldens/golden_rendering.dart';
import 'package:flutter_test_goldens/src/goldens/golden_scenes.dart';
import 'package:flutter_test_goldens/src/goldens/pixel_comparisons.dart';
import 'package:flutter_test_goldens/src/logging.dart';
import 'package:flutter_test_goldens/src/png/png_metadata.dart';
import 'package:flutter_test_goldens/src/scenes/golden_files.dart';
import 'package:flutter_test_goldens/src/scenes/golden_scene.dart';
import 'package:flutter_test_goldens/src/scenes/scene_layout.dart';
import 'package:image/image.dart';
import 'package:path/path.dart';

/// A golden builder that builds independent widget tree UIs and then either
/// renders those into a single scene file, or compares them against an existing
/// scene file.
class Gallery {
  Gallery(
    this._tester, {
    Directory? directory,
    required String fileName,
    required String sceneDescription,
    required SceneLayout layout,
    GoldenScaffold itemScaffold = defaultGalleryItemScaffold,
    GoldenDecorator? itemDecorator = defaultGalleryItemDecorator,
    Widget? goldenBackground,
  })  : _fileName = fileName,
        _sceneDescription = sceneDescription,
        _layout = layout,
        _itemScaffold = itemScaffold,
        _itemDecorator = itemDecorator,
        _goldenBackground = goldenBackground {
    _directory = directory ?? defaultGoldenDirectory;
  }

  final WidgetTester _tester;

  /// A scaffold built around each item in this scene.
  ///
  /// Defaults to [defaultGalleryItemScaffold].
  final GoldenScaffold _itemScaffold;

  /// A decoration applied to each item in this scene.
  final GoldenDecorator? _itemDecorator;

  /// All screenshots within this scene.
  final _items = <GalleryItem>[];

  /// The directory where the golden scene file will be saved.
  late final Directory _directory;

  /// The file name for the golden scene file, which will be saved in [_directory].
  final String _fileName;

  /// A human readable description of what's in this scene.
  final String _sceneDescription;

  /// The layout to use to position all the items in this scene.
  final SceneLayout _layout;

  /// The background behind the items in this scene.
  final Widget? _goldenBackground;

  /// Adds a screenshot item to the scene, based on a given [widget].
  Gallery itemFromWidget({
    required String id,
    required String description,
    TargetPlatform? platform,
    bool forEachPlatform = false,
    BoxConstraints? constraints,
    Finder? boundsFinder,
    GoldenSetup? setup,
    required Widget widget,
  }) {
    assert(
      forEachPlatform && platform == null || !forEachPlatform,
      "You can either specify a `platform` or you can set `forEachPlatform` to `true`, but not both",
    );

    if (forEachPlatform) {
      for (final platform in TargetPlatform.values) {
        _items.add(
          GalleryItem.withWidget(
            id: id,
            description: "description (${platform.name})",
            platform: platform,
            constraints: constraints,
            boundsFinder: boundsFinder,
            setup: setup,
            child: widget,
          ),
        );
      }

      return this;
    }

    _items.add(
      GalleryItem.withWidget(
        id: id,
        description: description,
        platform: platform,
        constraints: constraints,
        boundsFinder: boundsFinder,
        setup: setup,
        child: widget,
      ),
    );

    return this;
  }

  /// Adds a screenshot item to the scene, based on a widget created with a given [builder].
  Gallery itemFromBuilder({
    required String id,
    required String description,
    TargetPlatform? platform,
    bool forEachPlatform = false,
    BoxConstraints? constraints,
    Finder? boundsFinder,
    GoldenSetup? setup,
    required WidgetBuilder builder,
  }) {
    assert(
      forEachPlatform && platform == null || !forEachPlatform,
      "You can either specify a `platform` or you can set `forEachPlatform` to `true`, but not both",
    );

    if (forEachPlatform) {
      for (final platform in TargetPlatform.values) {
        _items.add(
          GalleryItem.withBuilder(
            id: id,
            description: "description (${platform.name})",
            platform: platform,
            constraints: constraints,
            boundsFinder: boundsFinder,
            setup: setup,
            builder: builder,
          ),
        );
      }

      return this;
    }

    _items.add(
      GalleryItem.withBuilder(
        id: id,
        description: description,
        platform: platform,
        constraints: constraints,
        boundsFinder: boundsFinder,
        setup: setup,
        builder: builder,
      ),
    );

    return this;
  }

  /// Adds a screenshot item to the scene, based on a widget tree that's pumped with [pumper].
  ///
  /// {@template gallery_item_pumper_purpose}
  /// Typically, gallery items are provided as `Widget`s or `WidgetBuilder`s. However, in some tests,
  /// full control over a `WidgetTester.pump` is required. A pumper provides that level of control.
  /// {@endtemplate}
  ///
  /// {@template gallery_item_pumper_requirements}
  /// The [pumper] implementation **must** do three things:
  ///
  ///  1. Place the `scaffold` at the top of the widget tree.
  ///  1. Place a [GoldenImageBounds] widget under the `scaffold` and above the `decorator` and/or `child`.
  ///  2. Place the given `decorator` around the `child`, if a `decorator` is provided.
  ///
  /// If the above steps are not taken, the golden widget tree may fail to build, or fail
  /// to render, or the expected decoration won't be applied.
  /// {@endtemplate}
  Gallery itemFromPumper({
    required String id,
    required String description,
    TargetPlatform? platform,
    bool forEachPlatform = false,
    BoxConstraints? constraints,
    Finder? boundsFinder,
    GoldenSetup? setup,
    required GalleryItemPumper pumper,
  }) {
    assert(
      forEachPlatform && platform == null || !forEachPlatform,
      "You can either specify a `platform` or you can set `forEachPlatform` to `true`, but not both",
    );

    if (forEachPlatform) {
      for (final platform in TargetPlatform.values) {
        _items.add(
          GalleryItem.withPumper(
            id: id,
            description: "description (${platform.name})",
            platform: platform,
            constraints: constraints,
            boundsFinder: boundsFinder,
            setup: setup,
            pumper: pumper,
          ),
        );
      }

      return this;
    }

    _items.add(
      GalleryItem.withPumper(
        id: id,
        description: description,
        platform: platform,
        constraints: constraints,
        boundsFinder: boundsFinder,
        setup: setup,
        pumper: pumper,
      ),
    );

    return this;
  }

  /// Either renders a new golden to a scene file, or compares new screenshots against an existing
  /// golden scene file.
  Future<void> renderOrCompareGolden() async {
    FtgLog.pipeline.info("Rendering or comparing golden - $_sceneDescription");

    // Build each gallery item and screenshot it.
    final camera = GoldenCamera();
    for (final item in _items) {
      FtgLog.pipeline.info("Building gallery item: ${item.description}, item decorated: $_itemDecorator");

      // Simulate the desired platform for this item.
      final previousPlatform = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = item.platform ?? previousPlatform;

      if (item.pumper != null) {
        // Defer to the `pumper` to pump the entire widget tree for this gallery item.
        await item.pumper!.call(_tester, _itemScaffold, _itemDecorator);
      } else if (item.builder != null) {
        // Pump this gallery item, deferring to a `WidgetBuilder` for the content.
        await _tester.pumpWidget(
          _buildItem(item.constraints, Builder(builder: item.builder!)),
        );
      } else {
        // Pump this gallery item, deferring to a `Widget` for the content.
        await _tester.pumpWidget(
          _buildItem(item.constraints, item.child!),
        );
      }

      // Run the item's setup function, if there is one.
      await item.setup?.call(_tester);

      // Return the simulated platform to whatever it was before this item.
      debugDefaultTargetPlatformOverride = previousPlatform;

      // Take a screenshot.
      expect(item.boundsFinder, findsOne);
      final renderObject = item.boundsFinder.evaluate().first.findRenderObject();
      expect(
        renderObject,
        isNotNull,
        reason: "Failed to find a render object for gallery item '${item.description}'",
      );

      await camera.takePhoto(item.description, item.boundsFinder);
    }

    // Lay out gallery items in the desired layout.
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
    var sceneMetadata = await _layoutPhotos(
      photos,
      renderablePhotos,
      _layout,
      goldenBackground: _goldenBackground,
    );

    FtgLog.pipeline.finer("Running momentary delay for render flakiness");
    await _tester.runAsync(() async {
      // Without this delay, the screenshot loading is spotty. However, with
      // this delay, we seem to always get screenshots displayed in the widget tree.
      // FIXME: Root cause this render flakiness and see if we can fix it.
      await Future.delayed(const Duration(milliseconds: 1));
    });

    await _tester.pumpAndSettle();

    if (autoUpdateGoldenFiles) {
      // Generate new goldens.
      await _updateGoldenScene(
        _tester,
        _fileName,
        sceneMetadata,
      );
    } else {
      // Compare to existing goldens.
      FtgLog.pipeline.finer("Comparing existing goldens...");
      await _compareGoldens(
        _tester,
        sceneMetadata,
        _fileName,
        find.byType(GoldenSceneBounds),
      );
      FtgLog.pipeline.finer("Done comparing goldens for gallery");
    }

    FtgLog.pipeline.finer("Done with golden generation/comparison");
  }

  Widget _buildItem(BoxConstraints? constraints, Widget content) {
    return _itemScaffold(
      _tester,
      ConstrainedBox(
        constraints: constraints ?? BoxConstraints(),
        child: _itemDecorator != null
            ? _itemDecorator.call(
                _tester,
                content,
              )
            : content,
      ),
    );
  }

  // TODO: de-dup this with FilmStrip
  Future<GoldenSceneMetadata> _layoutPhotos(
    List<GoldenPhoto> photos,
    Map<GoldenPhoto, (Uint8List, GlobalKey)> renderablePhotos,
    SceneLayout layout, {
    Widget? goldenBackground,
  }) async {
    // Layout the final strip within an OverflowBox to let it be whatever
    // size it wants. Then check the content render object for final dimensions.
    // Set the window size to match.

    late final Axis galleryDirection;
    switch (layout) {
      case SceneLayout.row:
        galleryDirection = Axis.horizontal;
      case SceneLayout.column:
        galleryDirection = Axis.vertical;
    }

    // FIXME: When we're comparing existing goldens, we shouldn't need to actually
    //        run full golden layout, we should be able to directly compare the renderable
    //        images to the regions of the existing golden.

    final contentKey = GlobalKey();
    final galleryKey = GlobalKey();

    final gallery = _buildGallery(
      galleryDirection,
      contentKey,
      renderablePhotos,
      galleryKey: galleryKey,
      goldenBackground: goldenBackground,
    );

    await _tester.pumpWidgetAndAdjustWindow(gallery);

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

  Widget _buildGallery(
    Axis galleryDirection,
    GlobalKey contentKey,
    Map<GoldenPhoto, (Uint8List, GlobalKey)> renderablePhotos, {
    Key? galleryKey,
    Widget? goldenBackground,
  }) {
    return GoldenSceneBounds(
      child: IntrinsicWidth(
        child: IntrinsicHeight(
          child: GoldenScene(
            key: galleryKey,
            direction: galleryDirection,
            renderablePhotos: renderablePhotos,
            background: goldenBackground,
          ),
        ),
      ),
    );
  }

  Future<void> _updateGoldenScene(
    WidgetTester tester,
    String goldenFileName,
    GoldenSceneMetadata sceneMetadata,
  ) async {
    FtgLog.pipeline.finer("Doing golden generation - window height: ${_tester.view.physicalSize.height}");
    await expectLater(find.byType(GoldenSceneBounds), matchesGoldenFile(_goldenFilePath()));

    final goldenFile = File(_goldenFilePath());
    var pngData = goldenFile.readAsBytesSync();
    pngData = pngData.copyWithTextMetadata(
      "flutter_test_goldens",
      const JsonEncoder().convert(sceneMetadata.toJson()),
    );
    goldenFile.writeAsBytesSync(pngData);
  }

  Future<void> _compareGoldens(
    WidgetTester tester,
    GoldenSceneMetadata newSceneMetadata,
    String existingGoldenFileName,
    Finder goldenBounds,
  ) async {
    // Extract scene metadata and golden images from image file.
    FtgLog.pipeline.fine("Extracting golden collection from scene file (goldens).");
    final goldenFile = File(_goldenFilePath());
    if (!goldenFile.existsSync()) {
      // TODO: report error in structured way.
      throw Exception("Can't compare goldens. Golden file doesn't exist: ${goldenFile.path}");
    }
    final goldenCollection = extractGoldenCollectionFromSceneFile(goldenFile);

    // Extract scene metadata from the current widget tree.
    FtgLog.pipeline.fine("Extracting golden collection from current widget tree (screenshots).");
    late final GoldenCollection screenshotCollection;
    await tester.runAsync(() async {
      screenshotCollection = await extractGoldenCollectionFromSceneWidgetTree(tester, newSceneMetadata);
    });

    // Compare goldens in the scene.
    FtgLog.pipeline.fine("Comparing goldens and screenshots");
    final mismatches = compareGoldenCollections(goldenCollection, screenshotCollection);

    final items = <GoldenReportItem>[];
    final missingCandidates = <MissingGoldenMismatch>[];
    final extraCandidates = <MissingGoldenMismatch>[];

    int totalPassed = 0;
    int totalFailed = 0;

    FtgLog.pipeline.fine("Mismatches ($existingGoldenFileName):");
    for (final mismatch in mismatches.mismatches.values) {
      FtgLog.pipeline.fine(" - ${mismatch.golden?.id ?? mismatch.screenshot?.id}: $mismatch");
      switch (mismatch) {
        case MissingGoldenMismatch(screenshot: null):
          // A golden candidate is missing.
          missingCandidates.add(mismatch);
          break;
        case MissingGoldenMismatch(golden: null):
          // We have a golden candidate, but not the original golden.
          extraCandidates.add(mismatch);
          break;
      }
    }

    for (final screenshotId in screenshotCollection.ids) {
      if (!goldenCollection.hasId(screenshotId)) {
        continue;
      }

      final mismatch = mismatches.mismatches[screenshotId];

      final status = mismatch != null //
          ? GoldenTestStatus.failure
          : GoldenTestStatus.success;

      if (status == GoldenTestStatus.success) {
        totalPassed += 1;
      } else {
        totalFailed += 1;
      }

      items.add(
        GoldenReportItem(
          status: status,
          description: goldenCollection.imagesById[screenshotId]!.id,
          details: [
            if (mismatch != null)
              GoldenCheckDetail(
                status: GoldenTestStatus.failure,
                description: mismatch.toString(),
                mismatch: mismatch,
              ),
          ],
        ),
      );
    }

    final report = GoldenSceneReport(
      sceneDescription: _sceneDescription,
      items: items,
      missingCandidates: missingCandidates,
      extraCandidates: extraCandidates,
      totalPassed: totalPassed,
      totalFailed: totalFailed,
    );
    _printReport(report);

    if (mismatches.mismatches.isEmpty) {
      FtgLog.pipeline.info("No golden mismatches found");
      return;
    }

    for (final mismatch in mismatches.mismatches.values) {
      if (mismatch.golden == null || mismatch.screenshot == null) {
        continue;
      }

      FtgLog.pipeline.fine("Painting a golden failure: $mismatch");
      Directory(_goldenFailureDirectoryPath).createSync();

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
          "$_goldenFailureDirectoryPath/failure_${existingGoldenFileName}_${mismatch.golden!.id}.png",
          failureImage,
        );
      });
    }

    throw Exception("Goldens failed with ${mismatches.mismatches.length} mismatch(es)");
  }

  String get _testFileDirectory => (goldenFileComparator as LocalFileComparator).basedir.path;

  String get _goldenDirectory => "$_testFileDirectory${_directory.path}$separator";

  /// Calculates and returns a complete file path to the golden file specified by
  /// this gallery, which consists of the current test file directory + an optional
  /// golden subdirectory + the golden file name.
  String _goldenFilePath([bool includeExtension = true]) =>
      "$_goldenDirectory$_fileName${includeExtension ? ".png" : ""}";

  String get _goldenFailureDirectoryPath => "${_goldenDirectory}failures";

  /// Prints the report in an human readable format to the console.
  void _printReport(GoldenSceneReport report) {
    if (report.totalFailed == 0 && //
        report.missingCandidates.isEmpty &&
        report.extraCandidates.isEmpty) {
      // All checks passed. Don't print anything.
      return;
    }

    final buffer = StringBuffer();

    // Report the summary of passed/failed tests and missing/extra candidates.
    buffer.write("Golden scene has failures: ${report.sceneDescription} (");
    buffer.write("✅ ${report.totalPassed}/${report.items.length}, ");
    buffer.write("❌ ${report.totalFailed}/${report.items.length}");
    if (report.missingCandidates.isNotEmpty || report.extraCandidates.isNotEmpty) {
      buffer.write(", ❓");

      if (report.missingCandidates.isNotEmpty) {
        buffer.write(" -${report.missingCandidates.length}");
      }

      if (report.extraCandidates.isNotEmpty) {
        if (report.missingCandidates.isNotEmpty) {
          buffer.write(" /");
        }
        buffer.write(" +${report.extraCandidates.length}");
      }
    }
    buffer.writeln(")");

    if (report.totalFailed > 0) {
      buffer.writeln("");
      for (final item in report.items) {
        if (item.status == GoldenTestStatus.success) {
          buffer.writeln("✅ ${item.description}");
          continue;
        }

        // This item has a failed check.
        final mismatch = item.details //
            .where((detail) => detail.mismatch != null)
            .firstOrNull
            ?.mismatch;

        switch (mismatch) {
          case WrongSizeGoldenMismatch():
            buffer.writeln(
                '"❌ ${item.description}" has an unexpected size (expected: ${mismatch.golden.size}, actual: ${mismatch.screenshot.size})');
            break;
          case PixelGoldenMismatch():
            buffer.writeln(
                '"❌ ${item.description}" has a ${mismatch.percent.toStringAsFixed(2)}% (${mismatch.mismatchPixelCount}px) mismatch');
            break;
          case MissingGoldenMismatch():
            // Don't print anything, missing goldens are reported at the end.
            break;
          default:
            buffer.writeln('"❌ ${item.description}": ${mismatch!.describe}');
            break;
        }
      }
    }

    if (report.missingCandidates.isNotEmpty) {
      buffer.writeln("");
      buffer.writeln("Missing goldens:");
      for (final mismatch in report.missingCandidates) {
        buffer.writeln('❓ "${mismatch.golden!.id}"');
      }
    }

    if (report.extraCandidates.isNotEmpty) {
      buffer.writeln("");
      buffer.writeln("Extra (unexpected) candidates:");
      for (final mismatch in report.extraCandidates) {
        buffer.writeln('❓ "${mismatch.screenshot!.id}"');
      }
    }

    // ignore: avoid_print
    print(buffer.toString());
  }
}

/// Pumps a widget tree into the given [tester], wrapping its content within the given [decorator].
///
/// {@macro gallery_item_pumper_purpose}
///
/// {@macro gallery_item_structure}
///
/// {@macro gallery_item_pumper_requirements}
typedef GalleryItemPumper = Future<void> Function(
  WidgetTester tester,
  GoldenScaffold scaffold,
  GoldenDecorator? decorator,
);

/// A single UI screenshot within a gallery of gallery items.
class GalleryItem {
  GalleryItem.withWidget({
    required this.id,
    required this.description,
    this.platform,
    this.constraints,
    Finder? boundsFinder,
    this.setup,
    required this.child,
  })  : pumper = null,
        builder = null {
    this.boundsFinder = boundsFinder ?? find.byType(GoldenImageBounds);
  }

  GalleryItem.withBuilder({
    required this.id,
    required this.description,
    this.platform,
    this.constraints,
    Finder? boundsFinder,
    this.setup,
    required this.builder,
  })  : pumper = null,
        child = null {
    this.boundsFinder = boundsFinder ?? find.byType(GoldenImageBounds);
  }

  GalleryItem.withPumper({
    required this.id,
    required this.description,
    this.platform,
    this.constraints,
    Finder? boundsFinder,
    this.setup,
    required this.pumper,
  })  : builder = null,
        child = null {
    this.boundsFinder = boundsFinder ?? find.byType(GoldenImageBounds);
  }

  /// The ID of this gallery item.
  final String id;

  /// A human readable description of this gallery item.
  final String description;

  /// The platform to simulate when building this item.
  ///
  /// The platform is simulated by setting [debugDefaultTargetPlatformOverride] to
  /// the given platform.
  ///
  /// If [platform] is `null`, the [debugDefaultTargetPlatformOverride] isn't changed
  /// at all - it uses whatever is configured by the test suite.
  final TargetPlatform? platform;

  /// Optional constraints for the golden, or unbounded if `null`.
  final BoxConstraints? constraints;

  /// [Finder] to locate the part of the subtree that should be screenshotted
  /// for this gallery item.
  late final Finder boundsFinder;

  /// Optional function that runs after the [pumper], [builder], or [child] is pumped
  /// into the widget tree, but before the screenshot is taken.
  final GoldenSetup? setup;

  /// The [GalleryItemPumper] that creates this gallery item, or `null` if this gallery
  /// item is created with a [builder] or a [child].
  final GalleryItemPumper? pumper;

  /// The [WidgetBuilder] that creates this gallery item, or `null` if this gallery
  /// item is created with a [pumper] or a [child].
  final WidgetBuilder? builder;

  /// The [Widget] that creates this gallery item, or `null` if this gallery
  /// item is created with a [pumper] or a [builder].
  final Widget? child;
}

/// The ancestor widget tree for every item in a gallery, unless overridden by
/// the gallery configuration.
Widget defaultGalleryItemScaffold(WidgetTester tester, Widget content) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(builder: (context) {
        return DefaultTextStyle(
          style: DefaultTextStyle.of(context).style.copyWith(
                fontFamily: goldenBricks,
              ),
          child: Center(
            child: GoldenImageBounds(child: content),
          ),
        );
      }),
    ),
    debugShowCheckedModeBanner: false,
  );
}

Widget defaultGalleryItemDecorator(WidgetTester tester, Widget content) {
  return Padding(
    padding: const EdgeInsets.all(24),
    child: content,
  );
}

/// A report of a golden scene test.
///
/// Holds information to display the results of a golden scene test.
class GoldenSceneReport {
  GoldenSceneReport({
    required this.sceneDescription,
    required this.items,
    required this.missingCandidates,
    required this.extraCandidates,
    required this.totalPassed,
    required this.totalFailed,
  });

  /// The human readable description of the scene.
  final String sceneDescription;

  /// The items found in the scene.
  ///
  /// Each item might be a successful or a failed golden check.
  final List<GoldenReportItem> items;

  /// The golden candidates that were expected to be present in the scene, but were not found.
  final List<MissingGoldenMismatch> missingCandidates;

  /// The golden candidates that were found in the scene, but were not expected to be present.
  final List<MissingGoldenMismatch> extraCandidates;

  /// The total number of successful [items] in the scene.
  final int totalPassed;

  /// The total number of failed [items] in the scene.
  final int totalFailed;
}

/// An item in a golden scene report.
///
/// Each item represents a single gallery item that was found in both the original golden
/// and the candidate image.
class GoldenReportItem {
  GoldenReportItem({
    required this.status,
    required this.description,
    required this.details,
  });

  /// Whether the gallery item passed or failed the golden check.
  final GoldenTestStatus status;

  /// The description of the gallery item that was checked.
  final String description;

  /// The details of the golden check for this item.
  ///
  /// Might contain both successful and failed checks.
  final List<GoldenCheckDetail> details;
}

class GoldenCheckDetail {
  GoldenCheckDetail({
    required this.status,
    required this.description,
    this.mismatch,
  }) : assert(
          status != GoldenTestStatus.success || mismatch == null,
          "A successful golden test cannot have a mismatch",
        );

  final GoldenTestStatus status;
  final String description;
  final GoldenMismatch? mismatch;
}

enum GoldenTestStatus {
  success,
  failure,
}
