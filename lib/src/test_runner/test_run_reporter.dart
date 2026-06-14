/// Writes a report for an entire golden test run, which might include any
/// number of golden scenes and golden test files.
class GoldenTestRunReporter {
  static final instance = GoldenTestRunReporter();

  var _passed = 0;
  var _failed = 0;

  void recordGoldenPassesAndFailures({
    required int passed,
    required int failed,
  }) {
    _passed += passed;
    _failed += failed;
  }

  void printSummary({StringSink? output}) {
    if (_passed == 0 && _failed == 0) {
      return;
    }

    final summary = "Golden Tests: $_passed Passed, $_failed Failed";
    if (output != null) {
      output.writeln(summary);
    } else {
      // ignore: avoid_print
      print(summary);
    }
  }
}
