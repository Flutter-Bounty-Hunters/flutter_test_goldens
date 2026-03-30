import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';

/// Annotation for tests that generate a golden scene, which allows them to be easily
/// indexed by tooling built on `flutter_test_goldens`.
const isGoldenScene = _IsGoldenScene();

class _IsGoldenScene {
  const _IsGoldenScene();
}

/// Run a golden scene test, which pretends to run on an iOS platform.
///
/// {@macro golden_scene_test}
///
/// This test runner pretends to run on a Mac by setting [debugDefaultTargetPlatformOverride] to
/// [TargetPlatform.iOS].
@isGoldenScene
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
@isGoldenScene
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
@isGoldenScene
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
@isGoldenScene
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
@isGoldenScene
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
@isGoldenScene
@isTest
@Deprecated(
  'Use testWidgets directly. Flutter Test Goldens now automatically '
  'configures the test environment for golden scene tests.',
)
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
      await test(tester);
    },
    skip: skip,
    variant: variant,
    timeout: timeout,
    semanticsEnabled: semanticsEnabled,
    tags: tags,
    retry: retry,
  );
}
