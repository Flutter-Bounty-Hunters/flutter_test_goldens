import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide Image;
import 'package:flutter/material.dart' as m;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/src/flutter/flutter_test_extensions.dart';
import 'package:flutter_test_goldens/src/flutter/pixel_boundary_box.dart';
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

/// A golden builder that builds independent widget tree UIs and then either
/// renders those into a single scene file, or compares them against an existing
/// scene file.
class Gallery {
  Gallery(
    this._tester, {
    required String sceneName,
    required SceneLayout layout,
    GalleryItemScaffold itemScaffold = defaultGalleryItemScaffold,
    GalleryItemDecorator? itemDecorator,
    Widget? goldenBackground,
    m.Color qrCodeColor = m.Colors.black,
    m.Color qrCodeBackgroundColor = m.Colors.white,
  })  : _sceneName = sceneName,
        _layout = layout,
        _itemScaffold = itemScaffold,
        _itemDecorator = itemDecorator,
        _goldenBackground = goldenBackground,
        _qrCodeColor = qrCodeColor,
        _qrCodeBackgroundColor = qrCodeBackgroundColor;

  final WidgetTester _tester;

  /// A scaffold built around each item in this scene.
  ///
  /// Defaults to [defaultGalleryItemScaffold].
  final GalleryItemScaffold _itemScaffold;

  /// A decoration applied to each item in this scene.
  final GalleryItemDecorator? _itemDecorator;

  /// All screenshots within this scene.
  final _items = <GalleryItem>[];

  /// The name of the overall golden scene, which may includes many individual
  /// goldens.
  final String _sceneName;

  /// The layout to use to position all the items in this scene.
  final SceneLayout _layout;

  /// The background behind the items in this scene.
  final Widget? _goldenBackground;

  final m.Color _qrCodeColor;
  final m.Color _qrCodeBackgroundColor;

  /// Adds a screenshot item to the scene, based on a given [widget].
  Gallery itemFromWidget({
    required String id,
    required String description,
    Finder? boundsFinder,
    required Widget widget,
  }) {
    _items.add(
      GalleryItem.withWidget(
        id: id,
        description: description,
        child: widget,
      ),
    );

    return this;
  }

  /// Adds a screenshot item to the scene, based on a widget created with a given [builder].
  Gallery itemFromBuilder({
    required String id,
    required String description,
    Finder? boundsFinder,
    required WidgetBuilder builder,
  }) {
    _items.add(
      GalleryItem.withBuilder(
        id: id,
        description: description,
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
    Finder? boundsFinder,
    required GalleryItemPumper pumper,
  }) {
    _items.add(
      GalleryItem.withPumper(
        id: id,
        description: description,
        pumper: pumper,
      ),
    );

    return this;
  }

  /// Either renders a new golden to a scene file, or compares new screenshots against an existing
  /// golden scene file.
  Future<void> renderOrCompareGolden() async {
    FtgLog.pipeline.info("Rendering or comparing golden - $_sceneName");

    // Build each gallery item and screenshot it.
    final camera = GoldenCamera(_tester);
    for (final item in _items) {
      FtgLog.pipeline.info("Building gallery item: ${item.description}, item decorated: $_itemDecorator");

      if (item.pumper != null) {
        // Defer to the `pumper` to pump the entire widget tree for this gallery item.
        await item.pumper!.call(_tester, _itemScaffold, _itemDecorator);
      } else if (item.builder != null) {
        // Pump this gallery item, deferring to a `WidgetBuilder` for the content.
        await _tester.pumpWidget(
          PixelBoundaryBox(
            child: _itemScaffold(
              _tester,
              GoldenImageBounds(
                child: _itemDecorator != null
                    ? _itemDecorator.call(
                        _tester,
                        Builder(builder: item.builder!),
                      )
                    : Builder(builder: item.builder!),
              ),
            ),
          ),
        );
      } else {
        // Pump this gallery item, deferring to a `Widget` for the content.
        await _tester.pumpWidget(
          PixelBoundaryBox(
            child: _itemScaffold(
              _tester,
              GoldenImageBounds(
                child: _itemDecorator != null
                    ? _itemDecorator.call(
                        _tester,
                        item.child!,
                      )
                    : item.child!,
              ),
            ),
          ),
        );
      }

      expect(item.boundsFinder, findsOne);
      final renderObject = item.boundsFinder.evaluate().first.findRenderObject();
      expect(
        renderObject,
        isNotNull,
        reason: "Failed to find a render object for gallery item '${item.description}'",
      );

      await camera.takePhoto(item.boundsFinder, item.description);
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
    var goldenMetadata = await _layoutPhotos(
      photos,
      renderablePhotos,
      _layout,
      qrCodeBackgroundColor: _qrCodeBackgroundColor,
    );

    // Layout photos one last time, this time adding the metadata QR code, which encodes
    // each photo's offset and size.
    goldenMetadata = await _layoutPhotos(
      photos,
      renderablePhotos,
      _layout,
      goldenBackground: _goldenBackground,
      qrCode: Code(
        data: const JsonEncoder().convert(goldenMetadata.toJson()),
        codeType: CodeType.qrCode(),
        color: _qrCodeColor,
      ),
      qrCodeBackgroundColor: _qrCodeBackgroundColor,
    );

    FtgLog.pipeline.finer("Running momentary delay for render flakiness");
    await _tester.runAsync(() async {
      // Without this delay, the screenshot loading is spotty. However, with
      // this delay, we seem to always get screenshots displayed in the widget tree.
      // FIXME: Root cause this render flakiness and see if we can fix it.
      await Future.delayed(const Duration(milliseconds: 1));
    });

    await _tester.pumpAndSettle();

    final goldenFileName = "$_sceneName.png";
    if (autoUpdateGoldenFiles) {
      // Generate new goldens.
      FtgLog.pipeline.finer("Doing golden generation - window height: ${_tester.view.physicalSize.height}");
      await expectLater(find.byType(GoldenSceneBounds), matchesGoldenFile(goldenFileName));
    } else {
      // Compare to existing goldens.
      FtgLog.pipeline.finer("Comparing existing goldens...");
      await _compareGoldens(_tester, goldenFileName, find.byType(GoldenSceneBounds));
      FtgLog.pipeline.finer("Done comparing goldens for gallery");
    }

    FtgLog.pipeline.finer("Done with golden generation/comparison");
  }

  // TODO: de-dup this with FilmStrip
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
    final qrCodeKey = GlobalKey();

    final gallery = _buildGallery(
      galleryDirection,
      contentKey,
      renderablePhotos,
      galleryKey: galleryKey,
      goldenBackground: goldenBackground,
      qrCodeKey: qrCodeKey,
      qrCode: qrCode,
      qrCodeBackgroundColor: qrCodeBackgroundColor,
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
                direction: galleryDirection,
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

/// Pumps a widget tree into the given [tester], wrapping its content within the given [decorator].
///
/// {@macro gallery_item_pumper_purpose}
///
/// {@macro gallery_item_structure}
///
/// {@macro gallery_item_pumper_requirements}
typedef GalleryItemPumper = Future<void> Function(
  WidgetTester tester,
  GalleryItemScaffold scaffold,
  GalleryItemDecorator? decorator,
);

/// Scaffolds a gallery item, such as building a `MaterialApp` with a `Scaffold`.
///
/// {@template gallery_item_structure}
/// The structure of a gallery item is as follows:
///
///     Gallery item scaffold
///       GalleryImageBounds (the default repaint boundary)
///         Gallery item decorator
///           Gallery item (the content)
/// {@endtemplate}
typedef GalleryItemScaffold = Widget Function(WidgetTester tester, Widget content);

/// Decorates a golden screenshot by wrapping the given [content] in a new widget tree.
///
/// {@macro gallery_item_structure}
typedef GalleryItemDecorator = Widget Function(WidgetTester tester, Widget content);

/// A single UI screenshot within a gallery of gallery items.
class GalleryItem {
  GalleryItem.withWidget({
    required this.id,
    required this.description,
    Finder? boundsFinder,
    required this.child,
  })  : pumper = null,
        builder = null {
    this.boundsFinder = boundsFinder ?? find.byType(GoldenImageBounds);
  }

  GalleryItem.withBuilder({
    required this.id,
    required this.description,
    Finder? boundsFinder,
    required this.builder,
  })  : pumper = null,
        child = null {
    this.boundsFinder = boundsFinder ?? find.byType(GoldenImageBounds);
  }

  GalleryItem.withPumper({
    required this.id,
    required this.description,
    Finder? boundsFinder,
    required this.pumper,
  })  : builder = null,
        child = null {
    this.boundsFinder = boundsFinder ?? find.byType(GoldenImageBounds);
  }

  /// The ID of this gallery item.
  final String id;

  /// A human readable description of this gallery item.
  final String description;

  /// [Finder] to locate the part of the subtree that should be screenshotted
  /// for this gallery item.
  late final Finder boundsFinder;

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

Widget defaultGalleryItemScaffold(WidgetTester tester, Widget content) {
  return MaterialApp(
    home: Scaffold(
      body: content,
    ),
    debugShowCheckedModeBanner: false,
  );
}
