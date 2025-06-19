import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/src/goldens/golden_camera.dart';
import 'package:flutter_test_goldens/src/goldens/golden_comparisons.dart';

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
/// Holds information to display the results of a golden scene test.
class GoldenSceneReport {
  GoldenSceneReport({
    required this.sceneDescription,
    required this.items,
    required this.missingCandidates,
    required this.extraCandidates,
    required this.totalPassed,
    required this.totalFailed,
  });

  /// The human readable description of the scene.
  final String sceneDescription;

  /// The items found in the scene.
  ///
  /// Each item might be a successful or a failed golden check.
  final List<GoldenReportItem> items;

  /// The golden candidates that were expected to be present in the scene, but were not found.
  final List<MissingCandidateMismatch> missingCandidates;

  /// The golden candidates that were found in the scene, but were not expected to be present.
  final List<MissingGoldenMismatch> extraCandidates;

  /// The total number of successful [items] in the scene.
  final int totalPassed;

  /// The total number of failed [items] in the scene.
  final int totalFailed;
}

/// An item in a golden scene report.
///
/// Each item represents a single gallery item that was found in both the original golden
/// and the candidate image.
class GoldenReportItem {
  GoldenReportItem({
    required this.status,
    required this.description,
    required this.details,
  });

  factory GoldenReportItem.success({
    required String description,
  }) {
    return GoldenReportItem(
      status: GoldenTestStatus.success,
      description: description,
      details: [],
    );
  }

  factory GoldenReportItem.failure({
    required String description,
    required List<GoldenCheckDetail> details,
  }) {
    return GoldenReportItem(
      status: GoldenTestStatus.failure,
      description: description,
      details: details,
    );
  }

  /// Whether the gallery item passed or failed the golden check.
  final GoldenTestStatus status;

  /// The description of the gallery item that was checked.
  final String description;

  /// The details of the golden check for this item.
  ///
  /// Might contain both successful and failed checks.
  final List<GoldenCheckDetail> details;
}

class GoldenCheckDetail {
  GoldenCheckDetail({
    required this.status,
    required this.description,
    this.mismatch,
  }) : assert(
          status != GoldenTestStatus.success || mismatch == null,
          "A successful golden test cannot have a mismatch",
        );

  final GoldenTestStatus status;
  final String description;
  final GoldenMismatch? mismatch;
}

enum GoldenTestStatus {
  success,
  failure,
}
