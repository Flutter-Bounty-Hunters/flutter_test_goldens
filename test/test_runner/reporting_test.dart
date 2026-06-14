import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/src/goldens/golden_collections.dart';
import 'package:flutter_test_goldens/src/goldens/golden_comparisons.dart';
import 'package:flutter_test_goldens/src/goldens/golden_scenes.dart';
import 'package:flutter_test_goldens/src/scenes/golden_scene.dart';
import 'package:flutter_test_goldens/src/scenes/golden_scene_report_printer.dart';
import 'package:flutter_test_goldens/src/test_runner/test_run_reporter.dart';
import 'package:image/image.dart' as img;

void main() {
  group("Golden reporting >", () {
    test("prints scene details and whole-run golden totals", () {
      final topGolden = _screenshot("Top (Constrained)");
      final topCandidate = _screenshot("Top (Constrained)");
      final rightGolden = _screenshot("Right (Constrained)");
      final rightCandidate = _screenshot("Right (Constrained)");

      final report = GoldenSceneReport(
        metadata: GoldenSceneMetadata(
          description: "Follower > preferred position aligner > not enough space on either side",
          images: [
            _imageMetadata("Left (Constrained)"),
            _imageMetadata("Top (Constrained)"),
            _imageMetadata("Right (Constrained)"),
            _imageMetadata("Bottom (Constrained)"),
          ],
        ),
        items: [
          GoldenReport.success(
            _imageMetadata("Left (Constrained)"),
            goldenFilePath: "/project/test_goldens/preferred_position_aligner.png",
          ),
          GoldenReport.failure(
            metadata: _imageMetadata("Top (Constrained)"),
            mismatch: PixelGoldenMismatch(
              golden: topGolden,
              screenshot: topCandidate,
              mismatchPixelCount: 240,
            ),
            goldenFilePath: "/project/test_goldens/preferred_position_aligner.png",
            failureFilePaths: ["/project/test_goldens/failures/failure_preferred_position_aligner_top.png"],
          ),
          GoldenReport.failure(
            metadata: _imageMetadata("Right (Constrained)"),
            mismatch: PixelGoldenMismatch(
              golden: rightGolden,
              screenshot: rightCandidate,
              mismatchPixelCount: 220,
            ),
            goldenFilePath: "/project/test_goldens/preferred_position_aligner.png",
            failureFilePaths: ["/project/test_goldens/failures/failure_preferred_position_aligner_right.png"],
          ),
          GoldenReport.success(
            _imageMetadata("Bottom (Constrained)"),
            goldenFilePath: "/project/test_goldens/preferred_position_aligner.png",
          ),
        ],
        missingCandidates: const [],
        extraCandidates: const [],
      );

      final reporter = GoldenTestRunReporter()
        ..recordGoldenPassesAndFailures(passed: 2, failed: 1)
        ..recordGoldenPassesAndFailures(passed: 3, failed: 0)
        ..recordGoldenPassesAndFailures(passed: 29, failed: 11);

      final output = StringBuffer();
      GoldenSceneReportPrinter().printReport(
        report,
        output: output,
      );
      reporter.printSummary(output: output);

      expect(output.toString(), '''
Golden scene failed (✅ 2/4, ❌ 2/4):
Scene: Follower > preferred position aligner > not enough space on either side
Golden file: /project/test_goldens/preferred_position_aligner.png
Failure scenes:
  - /project/test_goldens/failures/failure_preferred_position_aligner_top.png
  - /project/test_goldens/failures/failure_preferred_position_aligner_right.png

✅ Left (Constrained)
❌ Top (Constrained) (240px, 2.40%)
❌ Right (Constrained) (220px, 2.20%)
✅ Bottom (Constrained)
Golden Tests: 34 Passed, 12 Failed
''');
    });
  });
}

GoldenImageMetadata _imageMetadata(String id) {
  return GoldenImageMetadata(
    id: id,
    metadata: GoldenScreenshotMetadata(
      description: id,
      simulatedPlatform: TargetPlatform.android,
    ),
    topLeft: ui.Offset.zero,
    size: const ui.Size(100, 100),
  );
}

GoldenSceneScreenshot _screenshot(String id) {
  return GoldenSceneScreenshot(
    id,
    GoldenScreenshotMetadata(
      description: id,
      simulatedPlatform: TargetPlatform.android,
    ),
    img.Image(width: 100, height: 100),
    Uint8List(0),
  );
}
