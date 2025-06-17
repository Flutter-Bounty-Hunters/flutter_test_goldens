import 'dart:io';

import 'package:file/file.dart' show FileSystem;
import 'package:file/local.dart' show LocalFileSystem;
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:platform/platform.dart';

/// Loads the Material icons font into the [FontLoader], which doesn't happen by
/// default in widget tests.
///
/// In widget tests. icons render as empty squares. This is because in widget tests
/// the Material icons font isn't loaded by default. Unfortunately, Flutter doesn't
/// provide a first-class ability to load the font, so this method was copied from
/// Flutter to dig into implementation details and load it.
///
/// After loading this font into a widget test, Material icons should render normally.
Future<void> loadMaterialIconsFont() async {
  const FileSystem fs = LocalFileSystem();
  const Platform platform = LocalPlatform();
  final Directory flutterRoot = fs.directory(platform.environment['FLUTTER_ROOT']);

  final File iconFont = flutterRoot.childFile(
    fs.path.join(
      'bin',
      'cache',
      'artifacts',
      'material_fonts',
      'MaterialIcons-Regular.otf',
    ),
  );

  final Future<ByteData> bytes = Future<ByteData>.value(iconFont.readAsBytesSync().buffer.asByteData());

  await (FontLoader('MaterialIcons')..addFont(bytes)).load();
}

extension on Directory {
  File childFile(String basename) => File("$path$separator$basename");
}
