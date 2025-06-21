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
    buffer.write("Golden scene failed (");
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
    buffer.writeln("):");

    if (report.totalFailed > 0) {
      for (final item in report.items) {
        if (item.status == GoldenTestStatus.success) {
          buffer.writeln("✅ ${item.metadata.id}");
          continue;
        }

        // This item has a failed check.
        final mismatch = item.mismatch;
        switch (mismatch) {
          case WrongSizeGoldenMismatch():
            buffer.writeln('❌ ${item.metadata.id} (wrong size)');
            buffer.writeln('  - Golden size: (${mismatch.golden.size.width}, ${mismatch.golden.size.height})');
            buffer
                .writeln('  - Candidate size: (${mismatch.screenshot.size.width}, ${mismatch.screenshot.size.height})');
            buffer.write('  - ');
            // Print the width comparison.
            if (mismatch.golden.size.width > mismatch.screenshot.size.width) {
              buffer.write("Candidate is ${mismatch.golden.size.width - mismatch.screenshot.size.width}px too narrow.");
            } else if (mismatch.golden.size.width < mismatch.screenshot.size.width) {
              buffer.write("Candidate is ${mismatch.screenshot.size.width - mismatch.golden.size.width}px too wide.");
            } else {
              buffer.write("Candidate has correct width.");
            }
            // Print the height comparison.
            if (mismatch.golden.size.height > mismatch.screenshot.size.height) {
              buffer
                  .write(" Candidate is ${mismatch.golden.size.height - mismatch.screenshot.size.height}px too short.");
            } else if (mismatch.golden.size.height < mismatch.screenshot.size.height) {
              buffer
                  .write(" Candidate is ${mismatch.screenshot.size.height - mismatch.golden.size.height}px too tall.");
            } else {
              buffer.write(" Candidate has correct height.");
            }
            buffer.writeln("");
            break;
          case PixelGoldenMismatch():
            buffer.writeln(
                '❌ ${item.metadata.id} (${mismatch.mismatchPixelCount}px, ${(mismatch.percent * 100).toStringAsFixed(2)}%)');
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
