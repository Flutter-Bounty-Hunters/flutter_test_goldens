import 'dart:async';
import 'dart:io';

import 'package:flutter_test_goldens/flutter_test_goldens.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Adjust the theme that's applied to all golden tests in this suite.
  GoldenTestConfig.push(GoldenTestConfig.standard.copyWith(
    directory: Directory("."),
  ));

  return testMain();
}
