import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/src/fonts/golden_toolkit_fonts.dart' as golden_toolkit;

/// Tools for working with fonts in tests.
abstract class TestFonts {
  /// Load all fonts registered with the app and make them available
  /// to widget tests.
  static Future<void> loadAppFonts() async {
    await golden_toolkit.loadAppFonts();
  }

  static const openSans = "packages/flutter_test_goldens/OpenSans";
}
