import 'dart:convert';
import 'dart:io';
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
import 'package:flutter_test_goldens/src/logging.dart';
import 'package:flutter_test_goldens/src/png/png_metadata.dart';
import 'package:flutter_test_goldens/src/scenes/failure_scene.dart';
import 'package:flutter_test_goldens/src/scenes/golden_files.dart';
import 'package:flutter_test_goldens/src/scenes/golden_scene.dart';
import 'package:flutter_test_goldens/src/scenes/golden_scene_report_printer.dart';
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
      description: _sceneDescription,
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

    // Extract scene metadata from the existing golden file.
    final scenePngBytes = goldenFile.readAsBytesSync();
    final pngText = scenePngBytes.readTextMetadata();
    final sceneJsonText = pngText["flutter_test_goldens"];
    if (sceneJsonText == null) {
      throw Exception("Golden image is missing scene metadata: ${goldenFile.path}");
    }
    final sceneJson = JsonDecoder().convert(sceneJsonText);
    final metadata = GoldenSceneMetadata.fromJson(sceneJson);

    // Extract scene metadata from the current widget tree.
    FtgLog.pipeline.fine("Extracting golden collection from current widget tree (screenshots).");
    late final GoldenCollection screenshotCollection;
    await tester.runAsync(() async {
      screenshotCollection = await extractGoldenCollectionFromSceneWidgetTree(tester, newSceneMetadata);
    });

    // Compare goldens in the scene.
    FtgLog.pipeline.fine("Comparing goldens and screenshots");
    final mismatches = compareGoldenCollections(goldenCollection, screenshotCollection);

    final items = <GoldenReport>[];
    final missingCandidates = <MissingCandidateMismatch>[];
    final extraCandidates = <MissingGoldenMismatch>[];

    FtgLog.pipeline.fine("Mismatches ($existingGoldenFileName):");
    for (final mismatch in mismatches.mismatches.values) {
      FtgLog.pipeline.fine(" - ${mismatch.golden?.id ?? mismatch.screenshot?.id}: $mismatch");
      switch (mismatch) {
        case MissingCandidateMismatch():
          // A golden candidate is missing.
          missingCandidates.add(mismatch);
          break;
        case MissingGoldenMismatch():
          // We have a golden candidate, but not the original golden.
          extraCandidates.add(mismatch);
          break;
      }
    }

    // For each candidate found in the scene, report whether it passed or failed.
    for (final screenshotId in screenshotCollection.ids) {
      if (!goldenCollection.hasId(screenshotId)) {
        // This candidate is an extra candidate, i.e., it was found in the scene,
        // but it doesn't have a golden counterpart. We already reported extra candidates
        // above, so we can skip this candidate.
        continue;
      }

      // Find the golden metadata for this candidate.
      final goldenMetadata = metadata.images.where((image) => image.id == screenshotId).first;

      final mismatch = mismatches.mismatches[screenshotId];
      if (mismatch == null) {
        // The golden check passed.
        items.add(
          GoldenReport.success(goldenMetadata),
        );
      } else {
        // The golden check failed.
        items.add(
          GoldenReport.failure(
            metadata: goldenMetadata,
            mismatch: mismatch,
          ),
        );
      }
    }

    if (mismatches.mismatches.isEmpty) {
      FtgLog.pipeline.info("No golden mismatches found");
    }

    for (final mismatch in mismatches.mismatches.values) {
      if (mismatch.golden == null || mismatch.screenshot == null) {
        continue;
      }

      FtgLog.pipeline.fine("Painting a golden failure: $mismatch");
      Directory(_goldenFailureDirectoryPath).createSync();

      await tester.runAsync(() async {
        final failureImage = await paintGoldenMismatchImages(mismatch);

        await encodePngFile(
          "$_goldenFailureDirectoryPath/failure_${existingGoldenFileName}_${mismatch.golden!.id}.png",
          failureImage,
        );
      });
    }

    final report = GoldenSceneReport(
      metadata: metadata,
      items: items,
      missingCandidates: missingCandidates,
      extraCandidates: extraCandidates,
    );
    _printReport(report);

    if (mismatches.mismatches.isNotEmpty) {
      fail("Goldens failed with ${mismatches.mismatches.length} mismatch(es)");
    }
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
    GoldenSceneReportPrinter().printReport(report);
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
