import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart' hide Image;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/src/scenes/gallery.dart';
import 'package:flutter_test_goldens/src/scenes/golden_scene.dart';
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

  SingleShotConfigurator fromPumper(GoldenPumper pumper) => SingleShotConfigurator(
        _config.copyWith(pumper: pumper),
      );
}

class SingleShotConfigurator {
  const SingleShotConfigurator(this._config, [this._stepsCompleted = const <String>{}]);

  final SingleShotConfiguration _config;

  final Set<String> _stepsCompleted;

  SingleShotConfigurator withDecoration(GoldenDecorator decorator) {
    _ensureStepNotComplete("decoration");

    return SingleShotConfigurator(
      _config.copyWith(itemDecorator: decorator),
      {..._stepsCompleted, "decoration"},
    );
  }

  SingleShotConfigurator inScaffold(GoldenScaffold scaffold) {
    _ensureStepNotComplete("scaffold");

    return SingleShotConfigurator(
      _config.copyWith(itemScaffold: scaffold),
      {..._stepsCompleted, "scaffold"},
    );
  }

  SingleShotConfigurator withSetup(GoldenSetup setup) {
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
        setup: _config.setup,
      );
    } else if (_config.builder != null) {
      gallery.itemFromBuilder(
        id: "1",
        description: _config.description!,
        builder: _config.builder!,
        boundsFinder: _config.boundsFinder,
        setup: _config.setup,
      );
    } else {
      gallery.itemFromPumper(
        id: "1",
        description: _config.description!,
        pumper: _config.pumper!,
        boundsFinder: _config.boundsFinder,
        setup: _config.setup,
      );
    }

    await gallery.renderOrCompareGolden();
  }
}

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

  final GoldenScaffold? itemScaffold;
  final GoldenDecorator? itemDecorator;

  final Widget? widget;
  final WidgetBuilder? builder;
  final GoldenPumper? pumper;

  final GoldenSetup? setup;

  final Finder? boundsFinder;

  SingleShotConfiguration copyWith({
    String? description,
    Directory? directory,
    String? fileName,
    GoldenScaffold? itemScaffold,
    GoldenDecorator? itemDecorator,
    Widget? widget,
    WidgetBuilder? builder,
    GoldenPumper? pumper,
    GoldenSetup? setup,
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
