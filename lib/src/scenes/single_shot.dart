import 'dart:io';

import 'package:flutter/material.dart' hide Image;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/src/goldens/golden_rendering.dart';
import 'package:flutter_test_goldens/src/scenes/gallery.dart';
import 'package:flutter_test_goldens/src/scenes/golden_scene.dart';
import 'package:flutter_test_goldens/src/scenes/scene_layout.dart';

/// A golden scene with a single golden image.
class SingleShot {
  /// Creates a [SingleShot] whose content is rendered by a given [widget].
  SingleShot.fromWidget({
    Directory? directory,
    required String fileName,
    required String description,
    GoldenSceneItemScaffold? itemScaffold,
    GoldenSceneItemDecorator? itemDecorator,
    Finder? boundsFinder,
    required Widget widget,
  })  : _directory = directory,
        _fileName = fileName,
        _description = description,
        _itemScaffold = itemScaffold,
        _itemDecorator = itemDecorator,
        _boundsFinder = boundsFinder ?? find.byType(GoldenImageBounds),
        _widget = widget,
        _builder = null,
        _pumper = null;

  /// Creates a [SingleShot] whose content is rendered by a given [builder].
  SingleShot.fromBuilder({
    Directory? directory,
    required String fileName,
    required String description,
    GoldenSceneItemScaffold itemScaffold = defaultGoldenSceneItemScaffold,
    GoldenSceneItemDecorator? itemDecorator,
    Finder? boundsFinder,
    required WidgetBuilder builder,
  })  : _directory = directory,
        _fileName = fileName,
        _description = description,
        _itemScaffold = itemScaffold,
        _itemDecorator = itemDecorator,
        _boundsFinder = boundsFinder ?? find.byType(GoldenImageBounds),
        _builder = builder,
        _widget = null,
        _pumper = null;

  /// Creates a [SingleShot] whose content is rendered by a given [pumper].
  ///
  /// This constructor is useful when a golden scene needs full control over the [WidgetTester],
  /// and the call to [WidgetTester.pumpWidget].
  SingleShot.fromPumper({
    Directory? directory,
    required String fileName,
    required String description,
    GoldenSceneItemScaffold itemScaffold = defaultGoldenSceneItemScaffold,
    GoldenSceneItemDecorator? itemDecorator,
    Finder? boundsFinder,
    required GalleryItemPumper pumper,
  })  : _directory = directory,
        _fileName = fileName,
        _description = description,
        _itemScaffold = itemScaffold,
        _itemDecorator = itemDecorator,
        _boundsFinder = boundsFinder ?? find.byType(GoldenImageBounds),
        _pumper = pumper,
        _widget = null,
        _builder = null;

  /// The directory where the golden scene file will be saved.
  late final Directory? _directory;

  /// The file name for the golden scene file, which will be saved in [_directory].
  final String _fileName;

  /// The name of the overall golden scene.
  final String _description;

  /// A scaffold built around each item in this scene.
  ///
  /// Defaults to [defaultGoldenSceneItemScaffold].
  final GoldenSceneItemScaffold? _itemScaffold;

  /// A decoration applied to each item in this scene.
  final GoldenSceneItemDecorator? _itemDecorator;

  /// [Finder] that locates the content that will be screenshotted in this golden scene.
  final Finder _boundsFinder;

  final GalleryItemPumper? _pumper;

  final WidgetBuilder? _builder;

  final Widget? _widget;

  /// Either renders a new golden to a scene file, or compares new screenshots against an existing
  /// golden scene file.
  Future<void> renderOrCompareGolden(WidgetTester tester) async {
    final gallery = Gallery(
      directory: _directory,
      fileName: _fileName,
      sceneDescription: _description,
      layout: SceneLayout.column,
      itemScaffold: _itemScaffold,
      itemDecorator: _itemDecorator,
    );

    if (_widget != null) {
      gallery.itemFromWidget(id: "1", description: _description, widget: _widget, boundsFinder: _boundsFinder);
    } else if (_builder != null) {
      gallery.itemFromBuilder(id: "1", description: _description, builder: _builder, boundsFinder: _boundsFinder);
    } else {
      gallery.itemFromPumper(id: "1", description: _description, pumper: _pumper!, boundsFinder: _boundsFinder);
    }

    await gallery.renderOrCompareGolden(tester);
  }
}
