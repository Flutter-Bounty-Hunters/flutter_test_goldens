---
title: Overview
navOrder: 0
---
Flutter golden tests are widget tests that choose to compare pixels instead of other things.
Therefore, the golden test execution path is essentially the same as the standard widget
test execution path.

The following are some noteworthy details about goldens:

 * [How to write and run a test](/flutters-implementation/write-and-run-a-test)
 * [How Flutter finds the test directory](/flutters-implementation/find-the-test-directory)
 * [How Flutter compares screenshots](/flutters-implementation/compare-screenshots)

Flutter golden tests are implemented via the following packages, all of which are defined
within the Dart SDK, or Flutter SDK:

 * [flutter_tools](https://github.com/flutter/flutter/tree/master/packages/flutter_tools) - The Flutter CLI tool, e.g., `flutter test`.
 * [flutter_test](https://github.com/flutter/flutter/tree/master/packages/flutter_test) - Test runner for Flutter widget tests.
 * [test_core](https://pub.dev/packages/test_core) - The foundational test runner for all Dart and Flutter tests.
