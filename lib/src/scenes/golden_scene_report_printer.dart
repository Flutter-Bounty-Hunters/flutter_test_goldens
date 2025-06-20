import 'package:flutter_test_goldens/flutter_test_goldens.dart';

class GoldenSceneReportPrinter {
  void printReport(GoldenSceneReport report) {
    if (report.totalFailed == 0 && //
        report.missingCandidates.isEmpty &&
        report.extraCandidates.isEmpty) {
      // All checks passed. Don't print anything.
      return;
    }

    final buffer = StringBuffer();

    // Report the summary of passed/failed tests and missing/extra candidates.
    buffer.write("Golden scene has failures: ${report.metadata.description} (");
    buffer.write("✅ ${report.totalPassed}/${report.items.length}, ");
    buffer.write("❌ ${report.totalFailed}/${report.items.length}");
    if (report.missingCandidates.isNotEmpty || report.extraCandidates.isNotEmpty) {
      buffer.write(", ❓");

      if (report.missingCandidates.isNotEmpty) {
        buffer.write(" -${report.missingCandidates.length}");
      }

      if (report.extraCandidates.isNotEmpty) {
        if (report.missingCandidates.isNotEmpty) {
          buffer.write(" /");
        }
        buffer.write(" +${report.extraCandidates.length}");
      }
    }
    buffer.writeln(")");

    if (report.totalFailed > 0) {
      buffer.writeln("");
      for (final item in report.items) {
        if (item.status == GoldenTestStatus.success) {
          buffer.writeln("✅ ${item.metadata.id}");
          continue;
        }

        // This item has a failed check.
        final mismatch = item.mismatch;
        switch (mismatch) {
          case WrongSizeGoldenMismatch():
            buffer.writeln(
                '"❌ ${item.metadata.id}" has an unexpected size (expected: ${mismatch.golden.size}, actual: ${mismatch.screenshot.size})');
            break;
          case PixelGoldenMismatch():
            buffer.writeln(
                '"❌ ${item.metadata.id}" has a ${(mismatch.percent * 100).toStringAsFixed(2)}% (${mismatch.mismatchPixelCount}px) mismatch');
            break;
          case MissingGoldenMismatch():
          case MissingCandidateMismatch():
            // Don't print anything, missing goldens are reported at the end.
            break;
          default:
            buffer.writeln('"❌ ${item.metadata.id}": ${mismatch!.describe}');
            break;
        }
      }
    }

    if (report.missingCandidates.isNotEmpty) {
      buffer.writeln("");
      buffer.writeln("Missing goldens:");
      for (final mismatch in report.missingCandidates) {
        buffer.writeln('❓ "${mismatch.golden!.id}"');
      }
    }

    if (report.extraCandidates.isNotEmpty) {
      buffer.writeln("");
      buffer.writeln("Extra (unexpected) candidates:");
      for (final mismatch in report.extraCandidates) {
        buffer.writeln('❓ "${mismatch.screenshot!.id}"');
      }
    }

    // ignore: avoid_print
    print(buffer.toString());
  }
}
