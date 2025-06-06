import 'dart:io';

/// The standard path to where goldens are saved.
///
/// The default path is a `/goldens/` directory, which sits in the same parent directory as
/// the test file that's running the test.
final defaultGoldenDirectory = Directory("./goldens/");
