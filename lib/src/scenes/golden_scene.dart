import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/src/goldens/golden_camera.dart';
import 'package:flutter_test_goldens/src/goldens/golden_comparisons.dart';
import 'package:flutter_test_goldens/src/goldens/golden_scenes.dart';

class GoldenScene extends StatelessWidget {
  const GoldenScene({
    super.key,
    required this.direction,
    required this.renderablePhotos,
    this.background,
  });

  final Axis direction;
  final Map<GoldenPhoto, (Uint8List, GlobalKey)> renderablePhotos;
  final Widget? background;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF666666),
      child: Stack(
        children: [
          if (background != null) //
            Positioned.fill(
              child: ColoredBox(color: Colors.green),
            ),
          if (background != null) //
            Positioned.fill(
              child: background!,
            ),
          Padding(
            padding: const EdgeInsets.all(48),
            child: Flex(
              direction: direction,
              mainAxisSize: MainAxisSize.min,
              spacing: 48,
              children: [
                for (final entry in renderablePhotos.entries) //
                  SizedBox(
                    width: entry.key.pixels.width.toDouble(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ColoredBox(
                          // color: Color(0xFF222222),
                          color: Colors.white,
                          child: Image.memory(
                            key: entry.value.$2,
                            entry.value.$1,
                            width: entry.key.pixels.width.toDouble(),
                            height: entry.key.pixels.height.toDouble(),
                          ),
                        ),
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            entry.key.description,
                            style: TextStyle(
                              color: Colors.black,
                              fontFamily: "packages/flutter_test_goldens/OpenSans",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Scaffolds a golden image, such as building a `MaterialApp` with a `Scaffold`.
///
/// {@template golden_structure}
/// The structure of a golden is as follows:
///
///     Scaffold
///       GoldenImageBounds (the default repaint boundary)
///         Decorator
///           Content
/// {@endtemplate}
typedef GoldenScaffold = Widget Function(WidgetTester tester, Widget content);

/// Decorates a golden screenshot by wrapping the given [content] in a new widget tree.
///
/// {@macro golden_structure}
typedef GoldenDecorator = Widget Function(WidgetTester tester, Widget content);

/// Pumps a widget tree into the given [tester], wrapping its content within the given [decorator].
///
/// {@macro gallery_item_pumper_purpose}
///
/// {@macro golden_structure}
///
/// {@macro gallery_item_pumper_requirements}
typedef GoldenPumper = Future<Object?> Function(
  WidgetTester tester,
  GoldenScaffold scaffold,
  GoldenDecorator? decorator,
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
