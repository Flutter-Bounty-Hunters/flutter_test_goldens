import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/src/fonts/fonts.dart';
import 'package:meta/meta.dart';

/// Run a golden scene test, which pretends to run on an iOS platform.
///
/// {@macro golden_scene_test}
///
/// This test runner pretends to run on a Mac by setting [debugDefaultTargetPlatformOverride] to
/// [TargetPlatform.iOS].
@isTest
void testGoldenSceneOnIOS(
  String description,
  WidgetTesterCallback test, {
  bool? skip,
  Timeout? timeout,
  bool semanticsEnabled = true,
  TestVariant<Object?> variant = const DefaultTestVariant(),
  dynamic tags,
  int? retry,
}) {
  testGoldenScene(
    description,
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      tester.view
        ..devicePixelRatio = 1.0
        ..platformDispatcher.textScaleFactorTestValue = 1.0;

      try {
        await test(tester);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
    skip: skip,
    variant: variant,
    timeout: timeout,
    semanticsEnabled: semanticsEnabled,
    tags: tags,
    retry: retry,
  );
}

/// Run a golden scene test, which pretends to run on an Android platform.
///
/// {@macro golden_scene_test}
///
/// This test runner pretends to run on a Mac by setting [debugDefaultTargetPlatformOverride] to
/// [TargetPlatform.android].
@isTest
void testGoldenSceneOnAndroid(
  String description,
  WidgetTesterCallback test, {
  bool? skip,
  Timeout? timeout,
  bool semanticsEnabled = true,
  TestVariant<Object?> variant = const DefaultTestVariant(),
  dynamic tags,
  int? retry,
}) {
  testGoldenScene(
    description,
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      tester.view
        ..devicePixelRatio = 1.0
        ..platformDispatcher.textScaleFactorTestValue = 1.0;

      try {
        await test(tester);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
    skip: skip,
    variant: variant,
    timeout: timeout,
    semanticsEnabled: semanticsEnabled,
    tags: tags,
    retry: retry,
  );
}

/// Run a golden scene test, which pretends to run on a Mac platform.
///
/// {@macro golden_scene_test}
///
/// This test runner pretends to run on a Mac by setting [debugDefaultTargetPlatformOverride] to
/// [TargetPlatform.macOS].
@isTest
void testGoldenSceneOnMac(
  String description,
  WidgetTesterCallback test, {
  bool? skip,
  Timeout? timeout,
  bool semanticsEnabled = true,
  TestVariant<Object?> variant = const DefaultTestVariant(),
  dynamic tags,
  int? retry,
}) {
  testGoldenScene(
    description,
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

      tester.view
        ..devicePixelRatio = 1.0
        ..platformDispatcher.textScaleFactorTestValue = 1.0;

      try {
        await test(tester);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
    skip: skip,
    variant: variant,
    timeout: timeout,
    semanticsEnabled: semanticsEnabled,
    tags: tags,
    retry: retry,
  );
}

/// Run a golden scene test, which pretends to run on a Windows platform.
///
/// {@macro golden_scene_test}
///
/// This test runner pretends to run on a Mac by setting [debugDefaultTargetPlatformOverride] to
/// [TargetPlatform.windows].
@isTest
void testGoldenSceneOnWindows(
  String description,
  WidgetTesterCallback test, {
  bool? skip,
  Timeout? timeout,
  bool semanticsEnabled = true,
  TestVariant<Object?> variant = const DefaultTestVariant(),
  dynamic tags,
  int? retry,
}) {
  testGoldenScene(
    description,
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      tester.view
        ..devicePixelRatio = 1.0
        ..platformDispatcher.textScaleFactorTestValue = 1.0;

      try {
        await test(tester);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
    skip: skip,
    variant: variant,
    timeout: timeout,
    semanticsEnabled: semanticsEnabled,
    tags: tags,
    retry: retry,
  );
}

/// Run a golden scene test, which pretends to run on a Linux platform.
///
/// {@macro golden_scene_test}
///
/// This test runner pretends to run on a Mac by setting [debugDefaultTargetPlatformOverride] to
/// [TargetPlatform.linux].
@isTest
void testGoldenSceneOnLinux(
  String description,
  WidgetTesterCallback test, {
  bool? skip,
  Timeout? timeout,
  bool semanticsEnabled = true,
  TestVariant<Object?> variant = const DefaultTestVariant(),
  dynamic tags,
  int? retry,
}) {
  testGoldenScene(
    description,
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;

      tester.view
        ..devicePixelRatio = 1.0
        ..platformDispatcher.textScaleFactorTestValue = 1.0;

      try {
        await test(tester);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
    skip: skip,
    variant: variant,
    timeout: timeout,
    semanticsEnabled: semanticsEnabled,
    tags: tags,
    retry: retry,
  );
}

/// Run a golden scene test.
///
/// {@template golden_scene_test}
/// A golden scene refers to a single golden file, which might contain many individual golden images
/// within itself.
///
/// Loads app fonts so that text descriptions and instructions can be rendered within the final
/// golden scene.
///
/// Configures the test to use a 1:1 logical to physical pixel ratio so that anti-aliasing is reduced.
///
/// Runs the test with a text scale factor to `1.0`.
///
/// All test view configurations are reset after the [test] completes.
/// {@endtemplate}
@isTest
void testGoldenScene(
  String description,
  WidgetTesterCallback test, {
  bool? skip,
  Timeout? timeout,
  bool semanticsEnabled = true,
  TestVariant<Object?> variant = const DefaultTestVariant(),
  dynamic tags,
  int? retry,
}) {
  testWidgets(
    description,
    (tester) async {
      await TestFonts.loadAppFonts();

      tester.view
        ..devicePixelRatio = 1.0
        ..platformDispatcher.textScaleFactorTestValue = 1.0;

      try {
        await test(tester);
      } finally {
        tester.view.reset();
      }
    },
    skip: skip,
    variant: variant,
    timeout: timeout,
    semanticsEnabled: semanticsEnabled,
    tags: tags,
    retry: retry,
  );
}
