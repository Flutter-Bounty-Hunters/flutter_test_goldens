import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/src/flutter/flutter_camera.dart';
import 'package:flutter_test_goldens/src/flutter/flutter_test_extensions.dart';
import 'package:flutter_test_goldens/src/goldens/golden_collections.dart';
import 'package:flutter_test_goldens/src/goldens/golden_comparisons.dart';
import 'package:flutter_test_goldens/src/goldens/golden_rendering.dart';
import 'package:flutter_test_goldens/src/goldens/golden_scenes.dart';
import 'package:flutter_test_goldens/src/logging.dart';
import 'package:flutter_test_goldens/src/png/png_metadata.dart';
import 'package:flutter_test_goldens/src/scenes/failure_scene.dart';
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
    String sceneDescription, {
    Directory? directory,
    required String fileName,
    GoldenSceneItemScaffold? itemScaffold,
    BoxConstraints? itemConstraints,
    Finder? itemBoundsFinder,
    required SceneLayout layout,
  })  : _fileName = fileName,
        _sceneDescription = sceneDescription,
        _itemScaffold = itemScaffold,
        _itemConstraints = itemConstraints,
        _itemBoundsFinder = itemBoundsFinder,
        _layout = layout {
    _directory = directory ?? GoldenSceneTheme.current.directory;
  }

  /// A scaffold built around each item widget tree in this scene when new screenshots are
  /// being taken.
  ///
  /// This scaffold has no impact when painting the final scene.
  ///
  /// Defaults to [defaultGoldenSceneItemScaffold].
  final GoldenSceneItemScaffold? _itemScaffold;

  /// (Optional) size constraints applied to every item widget tree in the gallery, by default.
  ///
  /// The [_itemConstraints] are applied inside of the [_itemScaffold]. In theory, developers could
  /// accomplish this same goal by replacing [_itemScaffold] with another one that includes constraints,
  /// and then ignore [_itemConstraints]. However, in practice, it's a pain to create a new [_itemScaffold]
  /// just to constrain the size of each item. Therefore, [_itemConstraints] is provided.
  ///
  /// This [_itemConstraints] can be overridden on a per item basis, by providing preferred constraints
  /// for a specific item.
  ///
  /// [_itemConstraints] have no effect on "pumper" items because the pumper makes all decisions about
  /// layout.
  ///
  /// Sizing priority:
  ///
  /// 1. Constraints set on a specific item.
  /// 2. [_itemConstraints].
  /// 3. The layout behavior in [_itemScaffold].
  final BoxConstraints? _itemConstraints;

  /// An (optional) [Finder] that selects which part of each gallery item is screenshotted.
  ///
  /// While [_itemBoundsFinder] is optional, a [Finder] is always used to select the content for a
  /// screenshot. By default, the screenshotter looks for a [GoldenImageBounds] in the widget
  /// tree. If [_itemBoundsFinder] is provided, it will be used instead, for every item in the gallery.
  /// However, each item in the gallery can also provide its own bounds [Finder], which is taken
  /// as the highest priority, and will override this [_itemBoundsFinder].
  ///
  /// Bounds priority:
  ///
  /// 1. Bounds [Finder] provided by a specific item.
  /// 2. [_itemBoundsFinder].
  /// 3. `find.byType(GoldenImageBounds)`.
  final Finder? _itemBoundsFinder;

  /// Requests for all screenshots within this scene, by their ID.
  final _requests = <String, GalleryGoldenRequest>{};

  /// The directory where the golden scene file will be saved.
  late final Directory _directory;

  /// The file name for the golden scene file, which will be saved in [_directory].
  final String _fileName;

  /// A human readable description of what's in this scene.
  final String _sceneDescription;

  /// The layout to use to position all the items in this scene.
  final SceneLayout _layout;

  /// Adds a screenshot item to the scene, based on a given [widget].
  Gallery itemFromWidget({
    String? id,
    required String description,
    TargetPlatform? platform,
    bool forEachPlatform = false,
    GoldenSceneItemScaffold? scaffold,
    BoxConstraints? constraints,
    Finder? boundsFinder,
    GoldenSetup? setup,
    required Widget widget,
  }) {
    assert(
      forEachPlatform && platform == null || !forEachPlatform,
      "You can either specify a `platform` or you can set `forEachPlatform` to `true`, but not both",
    );

    id = id ?? description;
    boundsFinder = boundsFinder ?? _itemBoundsFinder;

    if (forEachPlatform) {
      for (final platform in _allPlatforms) {
        final platformId = "${id}_${platform.name}";

        _requests[platformId] = GalleryGoldenRequest.withWidget(
          id: platformId,
          description: "$description (${platform.name})",
          platform: platform,
          scaffold: scaffold,
          constraints: constraints,
          boundsFinder: boundsFinder,
          setup: setup,
          child: widget,
        );
      }

      return this;
    }

    _requests[id] = GalleryGoldenRequest.withWidget(
      id: id,
      description: description,
      platform: platform,
      scaffold: scaffold,
      constraints: constraints,
      boundsFinder: boundsFinder,
      setup: setup,
      child: widget,
    );

    return this;
  }

  /// Adds a screenshot item to the scene, based on a widget created with a given [builder].
  Gallery itemFromBuilder({
    String? id,
    required String description,
    TargetPlatform? platform,
    bool forEachPlatform = false,
    GoldenSceneItemScaffold? scaffold,
    BoxConstraints? constraints,
    Finder? boundsFinder,
    GoldenSetup? setup,
    required WidgetBuilder builder,
  }) {
    assert(
      forEachPlatform && platform == null || !forEachPlatform,
      "You can either specify a `platform` or you can set `forEachPlatform` to `true`, but not both",
    );

    id = id ?? description;
    boundsFinder = boundsFinder ?? _itemBoundsFinder;

    if (forEachPlatform) {
      for (final platform in _allPlatforms) {
        final platformId = "${id}_${platform.name}";

        _requests[platformId] = GalleryGoldenRequest.withBuilder(
          id: platformId,
          description: "$description (${platform.name})",
          platform: platform,
          scaffold: scaffold,
          constraints: constraints,
          boundsFinder: boundsFinder,
          setup: setup,
          builder: builder,
        );
      }

      return this;
    }

    _requests[id] = GalleryGoldenRequest.withBuilder(
      id: id,
      description: description,
      platform: platform,
      scaffold: scaffold,
      constraints: constraints,
      boundsFinder: boundsFinder,
      setup: setup,
      builder: builder,
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
    String? id,
    required String description,
    TargetPlatform? platform,
    bool forEachPlatform = false,
    GoldenSceneItemScaffold? scaffold,
    BoxConstraints? constraints,
    Finder? boundsFinder,
    GoldenSetup? setup,
    required GoldenSceneItemPumper pumper,
  }) {
    assert(
      forEachPlatform && platform == null || !forEachPlatform,
      "You can either specify a `platform` or you can set `forEachPlatform` to `true`, but not both",
    );

    id = id ?? description;
    boundsFinder = boundsFinder ?? _itemBoundsFinder;

    if (forEachPlatform) {
      for (final platform in _allPlatforms) {
        final platformId = "${id}_${platform.name}";

        _requests[platformId] = GalleryGoldenRequest.withPumper(
          id: platformId,
          description: "$description (${platform.name})",
          platform: platform,
          scaffold: scaffold,
          constraints: constraints,
          boundsFinder: boundsFinder,
          setup: setup,
          pumper: pumper,
        );
      }

      return this;
    }

    _requests[id] = GalleryGoldenRequest.withPumper(
      id: id,
      description: description,
      platform: platform,
      scaffold: scaffold,
      constraints: constraints,
      boundsFinder: boundsFinder,
      setup: setup,
      pumper: pumper,
    );

    return this;
  }

  /// Either renders a new golden to a scene file, or compares new screenshots against an existing
  /// golden scene file.
  Future<void> run(WidgetTester tester) async {
    FtgLog.pipeline.info("Rendering or comparing golden - $_sceneDescription");

    // Build each golden tree and take `FlutterScreenshot`s.
    final camera = FlutterCamera();
    await _takeNewScreenshots(tester, camera);

    // Convert each `FlutterScreenshot` to a golden `GoldenSceneScreenshot`, which includes
    // additional metadata, and multiple image representations.
    final screenshots = await _convertFlutterScreenshotsToSceneScreenshots(tester, camera.photos);

    if (autoUpdateGoldenFiles) {
      // Generate new goldens.
      FtgLog.pipeline.finer("Generating new goldens...");
      // TODO: Return a success/failure report that we can publish to the test output.
      await _updateGoldenScene(
        tester,
        _fileName,
        screenshots,
      );
      FtgLog.pipeline.finer("Done generating new goldens.");
    } else {
      // Compare to existing goldens.
      FtgLog.pipeline.finer("Comparing existing goldens...");
      // TODO: Return a success/failure report that we can publish to the test output.
      await _compareGoldens(
        tester,
        _fileName,
        screenshots,
      );
      FtgLog.pipeline.finer("Done comparing goldens.");
    }

    FtgLog.pipeline.fine("Done with golden generation/comparison");
  }

  /// For each scene screenshot request, pumps its widget tree, and then screenshots it with
  /// the given [camera].
  Future<void> _takeNewScreenshots(WidgetTester tester, FlutterCamera camera) async {
    print("Taking screenshots:");
    for (final item in _requests.values) {
      FtgLog.pipeline.info("Building gallery item: ${item.description}");
      final itemScaffold = item.scaffold ?? _itemScaffold ?? GoldenSceneTheme.current.itemScaffold;
      final itemConstraints = item.constraints ?? _itemConstraints;

      // Simulate the desired platform for this item.
      final previousPlatform = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = item.platform ?? previousPlatform;

      if (item.pumper != null) {
        // Defer to the `pumper` to pump the entire widget tree for this gallery item.
        await item.pumper!.call(tester, itemScaffold, item.description);
      } else if (item.builder != null) {
        // Pump this gallery item, deferring to a `WidgetBuilder` for the content.
        await tester.pumpWidget(
          KeyedSubtree(
            // ^ Always pump with a new GlobalKey to force a fresh tree between screenshots.
            key: GlobalKey(),
            child: _buildItem(tester, itemScaffold, itemConstraints, Builder(builder: item.builder!)),
          ),
        );
      } else {
        // Pump this gallery item, deferring to a `Widget` for the content.
        await tester.pumpWidget(
          KeyedSubtree(
            // ^ Always pump with a new GlobalKey to force a fresh tree between screenshots.
            key: GlobalKey(),
            child: _buildItem(tester, itemScaffold, itemConstraints, item.child!),
          ),
        );
      }

      // Run the item's setup function, if there is one.
      await item.setup?.call(tester);

      // Take a screenshot.
      expect(item.boundsFinder, findsOne);
      final renderObject = item.boundsFinder.evaluate().first.findRenderObject();
      print(
          " - Taking screenshot. Bounds: ${item.boundsFinder}, Render object size: ${(renderObject as RenderBox?)?.size}");
      expect(
        renderObject,
        isNotNull,
        reason: "Failed to find a render object for gallery item '${item.description}'",
      );

      await tester.runAsync(() async {
        await camera.takePhoto(item.id, item.boundsFinder);
      });
      print(" - Done taking photo - ${camera.photos.last.id} - size: ${camera.photos.last.size}");

      // Revert the simulated platform to whatever it was before this item.
      debugDefaultTargetPlatformOverride = previousPlatform;
    }
  }

  Widget _buildItem(
      WidgetTester tester, GoldenSceneItemScaffold itemScaffold, BoxConstraints? constraints, Widget content) {
    print("Building with item constraints: $constraints");
    return itemScaffold(
      tester,
      ConstrainedBox(
        constraints: constraints ?? const BoxConstraints(),
        child: content,
      ),
    );
  }

  Future<Map<String, GoldenSceneScreenshot>> _convertFlutterScreenshotsToSceneScreenshots(
    WidgetTester tester,
    List<FlutterScreenshot> flutterScreenshots,
  ) async {
    print("Converting Flutter screenshots to golden candidates:");
    final candidateScreenshots = <String, GoldenSceneScreenshot>{};
    await tester.runAsync(() async {
      for (final flutterScreenshot in flutterScreenshots) {
        // Decode Flutter screenshot to raw PNG data.
        final byteData = (await flutterScreenshot.pixels.toByteData(format: ui.ImageByteFormat.png))!;

        // Create a golden representation of the screenshot and store it.
        final candidate = GoldenSceneScreenshot(
          flutterScreenshot.id,
          GoldenScreenshotMetadata(
            description: _requests[flutterScreenshot.id]!.description,
            simulatedPlatform: flutterScreenshot.simulatedPlatform,
          ),
          decodePng(byteData.buffer.asUint8List())!,
          byteData.buffer.asUint8List(),
        );

        candidateScreenshots[flutterScreenshot.id] = candidate;
        print(
            " - ${candidate.id} - size: ${candidate.size}, inner PNG size: ${candidate.image.width}, ${candidate.image.height}");
      }
    });

    return candidateScreenshots;
  }

  Future<void> _updateGoldenScene(
    WidgetTester tester,
    String goldenFileName,
    Map<String, GoldenSceneScreenshot> newGoldens,
  ) async {
    // Layout candidate screenshots in the gallery so we can lookup their final offsets and sizes.
    var sceneMetadata = await _layoutGalleryWithNewGoldens(tester, _layout, newGoldens);

    print("Saving new scene metadata. Here are the golden bounds:");
    for (final golden in sceneMetadata.images) {
      print(" - ${golden.id} - at: ${golden.topLeft}, size: ${golden.size}");
    }
    print("---");

    FtgLog.pipeline.finer("Running momentary delay for render flakiness");
    await tester.runAsync(() async {
      // Without this delay, the screenshot loading is spotty. However, with
      // this delay, we seem to always get screenshots displayed in the widget tree.
      // FIXME: Root cause this render flakiness and see if we can fix it.
      await Future.delayed(const Duration(milliseconds: 1));
    });
    await tester.pumpAndSettle();

    FtgLog.pipeline.finer("Doing golden generation - window size: ${tester.view.physicalSize}");
    expect(
      find.byType(GoldenSceneBounds),
      findsOne,
      reason:
          "Every scene layout must include exactly one GoldenSceneBounds widget, which describes the area to screenshot.",
    );
    if (tester.view.physicalSize == Size.zero) {
      throw Exception(
        '''After laying out golden images, the intrinsic size of the scene is zero. This is an error. 

Check the scene layout implementation. The golden images are probably rendered using an Image.memory() widget.

Make sure that the Image.memory widget explicitly sets its "width" and "height". This is because, with the way images are loaded into golden tests, we need to pump a frame without the bitmap data, and then pump another frame with the bitmap data. If you don't specify the width/height on the first frame, Flutter will layout the Image with zero size. 

For example:

Image.memory(
  key: myGoldenGlobalKey,
  goldenPngUint8List,
  width: goldenWidth,
  height: goldenHeight,
)''',
      );
    }
    await expectLater(find.byType(GoldenSceneBounds), matchesGoldenFile(_goldenFilePath()));

    FtgLog.pipeline.finer("Writing updated golden scene to file");
    final goldenFile = File(_goldenFilePath());
    var pngData = goldenFile.readAsBytesSync();
    pngData = pngData.copyWithTextMetadata(
      "flutter_test_goldens",
      const JsonEncoder().convert(sceneMetadata.toJson()),
    );
    goldenFile.writeAsBytesSync(pngData);
  }

  // TODO: de-dup this with FilmStrip
  Future<GoldenSceneMetadata> _layoutGalleryWithNewGoldens(
    WidgetTester tester,
    SceneLayout layout,
    Map<String, GoldenSceneScreenshot> goldenScreenshots,
  ) async {
    print("_layoutGalleryWithNewGoldens()");
    final goldensAndGlobalKeys = Map<GoldenSceneScreenshot, GlobalKey>.fromEntries(
      goldenScreenshots.entries.map((entry) => MapEntry(entry.value, GlobalKey())),
    );

    // Layout the gallery scene with the new goldens, check the intrinsic size of the
    // gallery, then change the test window size to match it, so it fits exactly.
    //
    // We also need to do this because Flutter will only "precache" images for which there is
    // a corresponding `GlobalKey` already in the tree. Therefore, this layout pass inserts a
    // `GlobalKey` for every golden screenshot that we want to render.
    await tester.pumpWidgetAndAdjustWindow(
      _buildGalleryLayout(tester, goldensAndGlobalKeys),
    );

    // Use Flutter's `precacheImage()` mechanism to get each golden screenshot bitmap to
    // render in this widget test.
    await tester.runAsync(() async {
      for (final entry in goldensAndGlobalKeys.entries) {
        await precacheImage(
          MemoryImage(entry.key.pngBytes),
          tester.element(find.byKey(entry.value)),
        );
      }
    });

    // Now that the gallery scene is fully rendered, calculate and return the metadata for
    // all screenshots in the scene.
    return GoldenSceneMetadata(
      description: _sceneDescription,
      images: [
        for (final golden in goldensAndGlobalKeys.keys)
          GoldenImageMetadata(
            id: golden.id,
            metadata: golden.metadata,
            topLeft: (goldensAndGlobalKeys[golden]!.currentContext!.findRenderObject() as RenderBox)
                .localToGlobal(Offset.zero),
            size: goldensAndGlobalKeys[golden]!.currentContext!.size!,
          ),
      ],
    );
  }

  Widget _buildGalleryLayout(WidgetTester tester, Map<GoldenSceneScreenshot, GlobalKey> candidatesAndGlobalKeys) {
    print("Building Gallery scene layout");
    return Builder(builder: (context) {
      return _layout.build(tester, context, candidatesAndGlobalKeys);
    });
  }

  Future<void> _compareGoldens(
    WidgetTester tester,
    String existingGoldenFileName,
    Map<String, GoldenSceneScreenshot> candidateCollection,
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

    // Compare goldens in the scene.
    FtgLog.pipeline.fine("Comparing goldens and screenshots");
    final mismatches = compareGoldenCollections(goldenCollection, ScreenshotCollection(candidateCollection));

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
    for (final candidateId in candidateCollection.keys) {
      if (!goldenCollection.hasId(candidateId)) {
        // This candidate is an extra candidate, i.e., it was found in the scene,
        // but it doesn't have a golden counterpart. We already reported extra candidates
        // above, so we can skip this candidate.
        continue;
      }

      // Find the golden metadata for this candidate.
      final goldenMetadata = metadata.images.where((image) => image.id == candidateId).first;

      final mismatch = mismatches.mismatches[candidateId];
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

        try {
          await encodePngFile(
            "$_goldenFailureDirectoryPath/failure_${existingGoldenFileName}_${mismatch.golden!.id}.png",
            failureImage,
          );
        } catch (exception) {
          throw Exception(
            "Goldens failed with ${mismatches.mismatches.length} mismatch(es), BUT we were unable to paint the mismatches to a failure file. Originating exception: $exception",
          );
        }
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

  // TODO: Dedup following with FilmStrip
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

/// A request for a single UI screenshot within a gallery of independent screenshots.
class GalleryGoldenRequest {
  GalleryGoldenRequest.withWidget({
    required this.id,
    required this.description,
    this.platform,
    this.scaffold,
    this.constraints,
    Finder? boundsFinder,
    this.setup,
    required this.child,
  })  : pumper = null,
        builder = null {
    this.boundsFinder = boundsFinder ?? find.byType(GoldenImageBounds);
  }

  GalleryGoldenRequest.withBuilder({
    required this.id,
    required this.description,
    this.platform,
    this.scaffold,
    this.constraints,
    Finder? boundsFinder,
    this.setup,
    required this.builder,
  })  : pumper = null,
        child = null {
    this.boundsFinder = boundsFinder ?? find.byType(GoldenImageBounds);
  }

  GalleryGoldenRequest.withPumper({
    required this.id,
    required this.description,
    this.platform,
    this.scaffold,
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

  final GoldenSceneItemScaffold? scaffold;

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
  final GoldenSceneItemPumper? pumper;

  /// The [WidgetBuilder] that creates this gallery item, or `null` if this gallery
  /// item is created with a [pumper] or a [child].
  final WidgetBuilder? builder;

  /// The [Widget] that creates this gallery item, or `null` if this gallery
  /// item is created with a [pumper] or a [builder].
  final Widget? child;
}

const _allPlatforms = {
  TargetPlatform.android,
  TargetPlatform.iOS,
  TargetPlatform.macOS,
  TargetPlatform.windows,
  TargetPlatform.linux,
};
