import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart' hide Image;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/src/scenes/gallery.dart';
import 'package:flutter_test_goldens/src/scenes/scene_layout.dart';

class SingleShot {
  SingleShot(
    String description, {
    Directory? directory,
    required String fileName,
  }) {
    _config = SingleShotConfiguration(
      description: description,
      directory: directory ?? Directory("."),
      fileName: fileName,
    );
  }

  late final SingleShotConfiguration _config;

  SingleShotConfigurator fromWidget(Widget widget) => SingleShotConfigurator(
        _config.copyWith(widget: widget),
      );

  SingleShotConfigurator fromBuilder(WidgetBuilder builder) => SingleShotConfigurator(
        _config.copyWith(builder: builder),
      );

  SingleShotConfigurator fromPumper(GalleryItemPumper pumper) => SingleShotConfigurator(
        _config.copyWith(pumper: pumper),
      );
}

class SingleShotConfigurator {
  const SingleShotConfigurator(this._config, [this._stepsCompleted = const <String>{}]);

  final SingleShotConfiguration _config;

  final Set<String> _stepsCompleted;

  SingleShotConfigurator withDecoration(GalleryItemDecorator decorator) {
    _ensureStepNotComplete("decoration");

    return SingleShotConfigurator(
      _config.copyWith(itemDecorator: decorator),
      {..._stepsCompleted, "decoration"},
    );
  }

  SingleShotConfigurator inScaffold(GalleryItemScaffold scaffold) {
    _ensureStepNotComplete("scaffold");

    return SingleShotConfigurator(
      _config.copyWith(itemScaffold: scaffold),
      {..._stepsCompleted, "scaffold"},
    );
  }

  SingleShotConfigurator withSetup(SingleShotSetup setup) {
    _ensureStepNotComplete("setup");

    return SingleShotConfigurator(
      _config.copyWith(setup: setup),
      {..._stepsCompleted, "setup"},
    );
  }

  SingleShotConfigurator findBounds(Finder finder) {
    _ensureStepNotComplete("find");

    return SingleShotConfigurator(
      _config.copyWith(boundsFinder: finder),
      {..._stepsCompleted, "find"},
    );
  }

  void _ensureStepNotComplete(String name) {
    if (!_stepsCompleted.contains(name)) {
      return;
    }

    throw Exception(
      "SingleShot golden builders are expected to run each step at most one time. You tried to run '$name' twice.",
    );
  }

  Future<void> run(WidgetTester tester) async {
    final scaffold = _config.itemScaffold ?? defaultGalleryItemScaffold;
    final decorator = _config.itemDecorator ?? defaultGalleryItemDecorator;

    final gallery = Gallery(
      tester,
      directory: _config.directory!,
      fileName: _config.fileName!,
      sceneDescription: _config.description!,
      layout: SceneLayout.column,
      itemScaffold: scaffold,
      itemDecorator: decorator,
    );

    if (_config.widget != null) {
      gallery.itemFromWidget(
        id: "1",
        description: _config.description!,
        widget: _config.widget!,
        boundsFinder: _config.boundsFinder,
      );
    } else if (_config.builder != null) {
      gallery.itemFromBuilder(
        id: "1",
        description: _config.description!,
        builder: _config.builder!,
        boundsFinder: _config.boundsFinder,
      );
    } else {
      gallery.itemFromPumper(
        id: "1",
        description: _config.description!,
        pumper: _config.pumper!,
        boundsFinder: _config.boundsFinder,
      );
    }

    if (_config.setup != null) {
      await _config.setup!.call(tester);
    }

    await gallery.renderOrCompareGolden();
  }
}

typedef SingleShotSetup = FutureOr<void> Function(WidgetTester tester);

class SingleShotConfiguration {
  SingleShotConfiguration({
    this.directory,
    this.fileName,
    this.description,
    this.itemScaffold,
    this.itemDecorator,
    this.widget,
    this.builder,
    this.pumper,
    this.setup,
    this.boundsFinder,
  });

  /// The name of the overall golden scene.
  final String? description;

  /// The directory where the golden scene file will be saved.
  final Directory? directory;

  /// The file name for the golden scene file, which will be saved in [_directory].
  final String? fileName;

  final GalleryItemScaffold? itemScaffold;
  final GalleryItemDecorator? itemDecorator;

  final Widget? widget;
  final WidgetBuilder? builder;
  final GalleryItemPumper? pumper;

  final SingleShotSetup? setup;

  final Finder? boundsFinder;

  SingleShotConfiguration copyWith({
    String? description,
    Directory? directory,
    String? fileName,
    GalleryItemScaffold? itemScaffold,
    GalleryItemDecorator? itemDecorator,
    Widget? widget,
    WidgetBuilder? builder,
    GalleryItemPumper? pumper,
    SingleShotSetup? setup,
    Finder? boundsFinder,
  }) {
    return SingleShotConfiguration(
      description: description ?? this.description,
      directory: directory ?? this.directory,
      fileName: fileName ?? this.fileName,
      itemScaffold: itemScaffold ?? this.itemScaffold,
      itemDecorator: itemDecorator ?? this.itemDecorator,
      widget: widget ?? this.widget,
      builder: builder ?? this.builder,
      pumper: pumper ?? this.pumper,
      setup: setup ?? this.setup,
      boundsFinder: boundsFinder ?? this.boundsFinder,
    );
  }
}

// /// A golden scene with a single golden image.
// class SingleShot {
//   /// Creates a [SingleShot] whose content is rendered by a given [widget].
//   SingleShot.fromWidget(
//     this._tester, {
//     Directory? directory,
//     required String fileName,
//     required String description,
//     GalleryItemScaffold itemScaffold = defaultGalleryItemScaffold,
//     GalleryItemDecorator? itemDecorator,
//     Finder? boundsFinder,
//     required Widget widget,
//   })  : _fileName = fileName,
//         _description = description,
//         _itemScaffold = itemScaffold,
//         _itemDecorator = itemDecorator,
//         _boundsFinder = boundsFinder ?? find.byType(GoldenImageBounds),
//         _widget = widget,
//         _builder = null,
//         _pumper = null {
//     _directory = directory ?? defaultGoldenDirectory;
//   }
//
//   /// Creates a [SingleShot] whose content is rendered by a given [builder].
//   SingleShot.fromBuilder(
//     this._tester, {
//     Directory? directory,
//     required String fileName,
//     required String description,
//     GalleryItemScaffold itemScaffold = defaultGalleryItemScaffold,
//     GalleryItemDecorator? itemDecorator,
//     Finder? boundsFinder,
//     required WidgetBuilder builder,
//   })  : _fileName = fileName,
//         _description = description,
//         _itemScaffold = itemScaffold,
//         _itemDecorator = itemDecorator,
//         _boundsFinder = boundsFinder ?? find.byType(GoldenImageBounds),
//         _builder = builder,
//         _widget = null,
//         _pumper = null {
//     _directory = directory ?? defaultGoldenDirectory;
//   }
//
//   /// Creates a [SingleShot] whose content is rendered by a given [pumper].
//   ///
//   /// This constructor is useful when a golden scene needs full control over the [WidgetTester],
//   /// and the call to [WidgetTester.pumpWidget].
//   SingleShot.fromPumper(
//     this._tester, {
//     Directory? directory,
//     required String fileName,
//     required String description,
//     GalleryItemScaffold itemScaffold = defaultGalleryItemScaffold,
//     GalleryItemDecorator? itemDecorator,
//     Finder? boundsFinder,
//     required GalleryItemPumper pumper,
//   })  : _fileName = fileName,
//         _description = description,
//         _itemScaffold = itemScaffold,
//         _itemDecorator = itemDecorator,
//         _boundsFinder = boundsFinder ?? find.byType(GoldenImageBounds),
//         _pumper = pumper,
//         _widget = null,
//         _builder = null {
//     _directory = directory ?? defaultGoldenDirectory;
//   }
//
//   final WidgetTester _tester;
//
//   /// The directory where the golden scene file will be saved.
//   late final Directory _directory;
//
//   /// The file name for the golden scene file, which will be saved in [_directory].
//   final String _fileName;
//
//   /// The name of the overall golden scene.
//   final String _description;
//
//   /// A scaffold built around each item in this scene.
//   ///
//   /// Defaults to [defaultGalleryItemScaffold].
//   final GalleryItemScaffold _itemScaffold;
//
//   /// A decoration applied to each item in this scene.
//   final GalleryItemDecorator? _itemDecorator;
//
//   /// [Finder] that locates the content that will be screenshotted in this golden scene.
//   final Finder _boundsFinder;
//
//   final GalleryItemPumper? _pumper;
//
//   final WidgetBuilder? _builder;
//
//   final Widget? _widget;
//
//   /// Either renders a new golden to a scene file, or compares new screenshots against an existing
//   /// golden scene file.
//   Future<void> renderOrCompareGolden() async {
//     final gallery = Gallery(
//       _tester,
//       directory: _directory,
//       fileName: _fileName,
//       sceneDescription: _description,
//       layout: SceneLayout.column,
//       itemScaffold: _itemScaffold,
//       itemDecorator: _itemDecorator,
//     );
//
//     if (_widget != null) {
//       gallery.itemFromWidget(id: "1", description: _description, widget: _widget, boundsFinder: _boundsFinder);
//     } else if (_builder != null) {
//       gallery.itemFromBuilder(id: "1", description: _description, builder: _builder, boundsFinder: _boundsFinder);
//     } else {
//       gallery.itemFromPumper(id: "1", description: _description, pumper: _pumper!, boundsFinder: _boundsFinder);
//     }
//
//     await gallery.renderOrCompareGolden();
//   }
// }
