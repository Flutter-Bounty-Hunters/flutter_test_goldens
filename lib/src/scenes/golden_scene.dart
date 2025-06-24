import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Colors, MaterialApp, Scaffold, ThemeData;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/src/fonts/fonts.dart';
import 'package:flutter_test_goldens/src/goldens/golden_collections.dart';
import 'package:flutter_test_goldens/src/goldens/golden_comparisons.dart';
import 'package:flutter_test_goldens/src/goldens/golden_rendering.dart';
import 'package:flutter_test_goldens/src/goldens/golden_scenes.dart';
import 'package:flutter_test_goldens/src/scenes/golden_files.dart';
import 'package:golden_bricks/golden_bricks.dart';

/// A theme, which is applied to various [GoldenScene]s.
///
/// The purpose of [GoldenSceneTheme] is to make it easy to configure similar visual styles
/// for all [GoldenScene]s in a project, file, group, or within a test.
///
/// A [GoldenSceneTheme] captures various details that are visually common among
/// [GoldenScene]s. For example, a theme includes an [itemScaffold] and [itemDecorator] that are
/// built around every golden in a scene. It includes a [background] that renders behind the
/// golden images. For logistics, it includes a relative [directory] path, which says where
/// to store [GoldenScene]s in relation to each golden test file.
class GoldenSceneTheme {
  /// The [GoldenSceneTheme] that should be used for the currently executing test.
  ///
  /// By default, this value is [standard]. The theme can be customized
  /// by [push]ing a new theme on the stack. Any theme that is [push]ed on the stack
  /// will be reported as the [current] theme until it is [pop]ed.
  static GoldenSceneTheme get current => _themeStack.last;

  static final _themeStack = [standard];

  /// Configures a [setUp] that makes the given [theme] the [current] global
  /// [GoldenSceneTheme] within the current test group, and configures a
  /// [tearDown] that returns the previous global theme when the group exits.
  static void useForGroup(GoldenSceneTheme theme) {
    setUp(() => GoldenSceneTheme.push(theme));
    tearDown(() => GoldenSceneTheme.pop());
  }

  /// Configures a [setUp] that makes the given [theme] the [current] global
  /// [GoldenSceneTheme] within the current test, and configures a [tearDown]
  /// that returns the previous global theme when the group exits.
  static void useForTest(GoldenSceneTheme theme) {
    GoldenSceneTheme.push(theme);
    addTearDown(() => GoldenSceneTheme.pop());
  }

  /// Pushes the given [theme] on to the global theme stack, which will make it
  /// the global theme until there's a call to [pop].
  ///
  /// Pushing and popping themes is useful within group and test setups and teardowns
  /// to configure a [GoldenSceneTheme] for that group or test.
  static void push(GoldenSceneTheme theme) => _themeStack.add(theme);

  /// Removes to the top theme on the global stack, which was added with [push].
  ///
  /// If there is no corresponding theme that was added by an earlier [push], then
  /// this method does nothing.
  static void pop() {
    if (_themeStack.length > 1) {
      _themeStack.removeLast();
    }
  }

  /// The default [GoldenSceneTheme] for all tests.
  static final standard = GoldenSceneTheme(
    directory: defaultGoldenDirectory,
    background: defaultGoldenSceneBackground,
    defaultTextStyle: TextStyle(
      color: Colors.black,
      fontFamily: TestFonts.openSans,
    ),
    itemScaffold: defaultGoldenSceneItemScaffold,
    itemDecorator: defaultGoldenSceneItemDecorator,
  );

  /// The default dark [GoldenSceneTheme].
  ///
  /// This theme isn't used anywhere by default, but it's a convenient theme if
  /// you want a dark theme and you don't care about all the specifics.
  static final standardDark = GoldenSceneTheme(
    directory: defaultGoldenDirectory,
    background: defaultDarkGoldenSceneBackground,
    defaultTextStyle: TextStyle(
      color: Colors.white,
      fontFamily: TestFonts.openSans,
    ),
    // The default scaffold is fine - it doesn't have any visual impact.
    itemScaffold: defaultDarkGoldenSceneItemScaffold,
    itemDecorator: defaultDarkGoldenSceneItemDecorator,
  );

  const GoldenSceneTheme({
    required this.directory,
    required this.background,
    required this.defaultTextStyle,
    required this.itemScaffold,
    required this.itemDecorator,
  });

  /// The relative path from a running test to where that test's goldens are
  /// stored.
  ///
  /// The [standard] directory is `Directory("./goldens/")`. To store goldens in the same
  /// directory as the running tests, use `Directory(".")`.
  final Directory directory;

  /// The background that's painted full-bleed across the scene, behind the goldens.
  ///
  /// The [standard] background is a color.
  final GoldenSceneBackground background;

  /// The default text style applied across the [GoldenScene].
  final TextStyle defaultTextStyle;

  /// A scaffold that builds around each golden in a scene.
  ///
  /// The primary purpose of a scaffold is not to be seen, but to provide widget structure
  /// that's required for correct rendering. For example, the [standard] item scaffold includes
  /// a `MaterialApp`, a `Scaffold`, and a `DefaultTextStyle`.
  final GoldenSceneItemScaffold itemScaffold;

  /// A decoration that wraps around each golden in a scene.
  ///
  /// The item decoration is responsible for adding things like padding around the golden image,
  /// a description label, etc. The [standard] item decorator adds padding around each golden, and
  /// displays each golden's description beneath the golden.
  final GoldenSceneItemDecorator itemDecorator;

  GoldenSceneTheme copyWith({
    Directory? directory,
    GoldenSceneBackground? background,
    TextStyle? defaultTextStyle,
    GoldenSceneItemScaffold? itemScaffold,
    GoldenSceneItemDecorator? itemDecorator,
  }) {
    return GoldenSceneTheme(
      directory: directory ?? this.directory,
      background: background ?? this.background,
      defaultTextStyle: defaultTextStyle ?? this.defaultTextStyle,
      itemScaffold: itemScaffold ?? this.itemScaffold,
      itemDecorator: itemDecorator ?? this.itemDecorator,
    );
  }
}

class GoldenSceneBackground {
  const GoldenSceneBackground.color(this.color)
      : builder = null,
        widget = null;

  const GoldenSceneBackground.builder(this.builder)
      : color = null,
        widget = null;

  const GoldenSceneBackground.widget(this.widget)
      : builder = null,
        color = null;

  final Color? color;
  final WidgetBuilder? builder;
  final Widget? widget;

  Widget build(BuildContext context) {
    if (builder != null) {
      return builder!(context);
    }

    if (widget != null) {
      return widget!;
    }

    return ColoredBox(color: color!);
  }
}

/// The default background for all [GoldenScene]s.
const defaultGoldenSceneBackground = GoldenSceneBackground.color(Color(0xFFF0F0EA));

/// The ancestor widget tree for every item in a golden scene, unless using a custom
/// [GoldenSceneTheme], or is configured directly on a gallery, film strip, etc.
Widget defaultGoldenSceneItemScaffold(WidgetTester tester, Widget content) {
  return MaterialApp(
    home: Scaffold(
      // FIXME: background probably needs to be configurable.
      backgroundColor: Colors.white,
      body: Builder(builder: (context) {
        return DefaultTextStyle(
          style: DefaultTextStyle.of(context).style.copyWith(
                fontFamily: goldenBricks,
              ),
          child: GoldenImageBounds(
            child: content,
          ),
        );
      }),
    ),
    debugShowCheckedModeBanner: false,
  );
}

/// The widget tree that wraps around each golden image in a Golden Scene, unless using a custom
/// [GoldenSceneTheme], or is configured directly on a gallery, film strip, etc.
Widget defaultGoldenSceneItemDecorator(
  BuildContext context,
  GoldenScreenshotMetadata metadata,
  Widget content,
) {
  return ColoredBox(
    // TODO: need this to be configurable, e.g., light vs dark
    color: Colors.white,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        content,
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            metadata.description,
            style: TextStyle(fontFamily: TestFonts.openSans),
          ),
        ),
      ],
    ),
  );
}

/// The [GoldenSceneBackground] for [GoldenSceneTheme.standardDark].
const defaultDarkGoldenSceneBackground = GoldenSceneBackground.color(Color(0xFF111111));

/// The [GoldenSceneItemScaffold] for [GoldenSceneTheme.standardDark].
Widget defaultDarkGoldenSceneItemScaffold(WidgetTester tester, Widget content) {
  return MaterialApp(
    theme: ThemeData(brightness: Brightness.dark),
    home: Scaffold(
      body: Builder(builder: (context) {
        return DefaultTextStyle(
          style: DefaultTextStyle.of(context).style.copyWith(
                fontFamily: goldenBricks,
              ),
          child: Center(
            child: GoldenImageBounds(
              child: content,
            ),
          ),
        );
      }),
    ),
    debugShowCheckedModeBanner: false,
  );
}

/// The [GoldenSceneItemDecorator] for [GoldenSceneTheme.standardDark].
Widget defaultDarkGoldenSceneItemDecorator(
  BuildContext context,
  GoldenScreenshotMetadata metadata,
  Widget content,
) {
  return ColoredBox(
    color: const Color(0xFF1A1A1A),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: content,
    ),
  );
}

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
typedef GoldenSceneItemScaffold = Widget Function(WidgetTester tester, Widget content);

/// Decorates a golden screenshot by wrapping the given [content] in a new widget tree.
///
/// {@macro gallery_item_structure}
typedef GoldenSceneItemDecorator = Widget Function(
  BuildContext context,
  GoldenScreenshotMetadata metadata,
  Widget content,
);

/// Pumps a widget tree into the given [tester], wrapping its content within the given [decorator].
///
/// {@macro gallery_item_pumper_purpose}
///
/// {@macro golden_structure}
///
/// {@macro gallery_item_pumper_requirements}
typedef GoldenSceneItemPumper = Future<dynamic> Function(
  WidgetTester tester,
  GoldenSceneItemScaffold scaffold,
  String description,
);

typedef GoldenSetup = FutureOr<void> Function(WidgetTester tester);

/// A report of a golden scene test.
///
/// Reports the success or failure of each individual golden in the scene, as well as
/// the missing candidates and candidates that have no corresponding golden.
class GoldenSceneReport {
  GoldenSceneReport({
    required this.metadata,
    required this.items,
    required this.missingCandidates,
    required this.extraCandidates,
  });

  /// The metadata of the scene, such as the golden images and their positions.
  final GoldenSceneMetadata metadata;

  /// The items found in the scene.
  ///
  /// Each item might be a successful or a failed golden check.
  final List<GoldenReport> items;

  /// The golden candidates that were expected to be present in the scene, but were not found.
  final List<MissingCandidateMismatch> missingCandidates;

  /// The golden candidates that were found in the scene, but were not expected to be present.
  final List<MissingGoldenMismatch> extraCandidates;

  /// The total number of successful [items] in the scene.
  int get totalPassed => items.where((e) => e.status == GoldenTestStatus.success).length;

  /// The total number of failed [items] in the scene.
  ///
  /// Only candidates that have a corresponding golden image and failed the golden check
  /// count as a failure.
  ///
  /// See [missingCandidates] for candidates that were expected but not found,
  /// and [extraCandidates] for candidates that were found but not expected.
  int get totalFailed => items.where((e) => e.status == GoldenTestStatus.failure).length;
}

/// A report of success or failure for a single golden within a scene.
///
/// A [GoldenReport] holds the test results for a candidate that has a corresponding golden.
class GoldenReport {
  factory GoldenReport.success(GoldenImageMetadata metadata) {
    return GoldenReport(
      status: GoldenTestStatus.success,
      metadata: metadata,
    );
  }

  factory GoldenReport.failure({
    required GoldenImageMetadata metadata,
    required GoldenMismatch mismatch,
  }) {
    return GoldenReport(
      status: GoldenTestStatus.failure,
      metadata: metadata,
      mismatch: mismatch,
    );
  }

  GoldenReport({
    required this.status,
    required this.metadata,
    this.mismatch,
  }) : assert(
          status == GoldenTestStatus.success || mismatch != null,
          "A failure report must have a mismatch.",
        );

  /// Whether the gallery item passed or failed the golden check.
  final GoldenTestStatus status;

  /// The metadata of the candidate image of this report.
  final GoldenImageMetadata metadata;

  /// The failure details of the gallery item, if it failed the golden check.
  ///
  /// Non-`null` if [status] is [GoldenTestStatus.failure] and `null` otherwise.
  final GoldenMismatch? mismatch;
}

enum GoldenTestStatus {
  success,
  failure,
}
