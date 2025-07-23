import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/src/scenes/golden_scene.dart';

/// A configuration for golden tests.
///
/// The purpose of [GoldenTestConfig] is to make it easy to configure multiple golden
/// tests in a project, file, group, or within a test.
///
/// A [GoldenTestConfig] captures various details that are common among [GoldenScene]s. For
/// example, a relative [directory] path, which says where to store [GoldenScene]s in
/// relation to each golden test file.
class GoldenTestConfig {
  /// The [GoldenTestConfig] that should be used for the currently executing test.
  ///
  /// By default, this value is [standard]. The theme can be customized
  /// by [push]ing a new theme on the stack. Any theme that is [push]ed on the stack
  /// will be reported as the [current] theme until it is [pop]ed.
  static GoldenTestConfig get current => _themeStack.last;

  static final _themeStack = [standard];

  /// Configures a [setUp] that makes the given [config] the [current] global
  /// [GoldenTestConfig] within the current test group, and configures a
  /// [tearDown] that returns the previous global theme when the group exits.
  static void useForGroup(GoldenTestConfig config) {
    setUp(() => GoldenTestConfig.push(config));
    tearDown(() => GoldenTestConfig.pop());
  }

  /// Configures a [setUp] that makes the given [config] the [current] global
  /// [GoldenTestConfig] within the current test, and configures a [tearDown]
  /// that returns the previous global theme when the group exits.
  static void useForTest(GoldenTestConfig config) {
    GoldenTestConfig.push(config);
    addTearDown(() => GoldenTestConfig.pop());
  }

  /// Pushes the given [config] on to the global config stack, which will make it
  /// the global theme until there's a call to [pop].
  ///
  /// Pushing and popping themes is useful within group and test setups and teardowns
  /// to configure a [GoldenTestConfig] for that group or test.
  static void push(GoldenTestConfig config) => _themeStack.add(config);

  /// Removes to the top config on the global stack, which was added with [push].
  ///
  /// If there is no corresponding config that was added by an earlier [push], then
  /// this method does nothing.
  static void pop() {
    if (_themeStack.length > 1) {
      _themeStack.removeLast();
    }
  }

  /// The default [GoldenTestConfig] for all tests.
  static final standard = GoldenTestConfig(
    directory: defaultGoldenDirectory,
  );

  /// The default dark [GoldenTestConfig].
  ///
  /// This theme isn't used anywhere by default, but it's a convenient theme if
  /// you want a dark theme and you don't care about all the specifics.
  static final standardDark = GoldenTestConfig(
    directory: defaultGoldenDirectory,
  );

  const GoldenTestConfig({
    required this.directory,
  });

  /// The relative path from a running test to where that test's goldens are stored.
  ///
  /// The [standard] directory is `Directory("./goldens/")`. To store goldens in the same
  /// directory as the running tests, use `Directory(".")`.
  final Directory directory;

  GoldenTestConfig copyWith({
    Directory? directory,
    GoldenSceneTheme? theme,
  }) {
    return GoldenTestConfig(
      directory: directory ?? this.directory,
    );
  }
}

/// The standard path to where goldens are saved.
///
/// The default path is a `/goldens/` directory, which sits in the same parent directory as
/// the test file that's running the test.
final defaultGoldenDirectory = Directory("./goldens/");
