---
title: Load Fonts and Icons
navOrder: 32 
---
By default, in golden tests, Flutter replaces all fonts with a big blocky font called
Ahem. Flutter also chooses not to load the standard Material and Cupertino icon sets.

## Load Fonts
The easiest way to load your real app fonts in golden tests is to use the `loadAppFonts()`
function in `flutter_test_goldens`. This method is a port from the discontinued `golden_toolkit`
package.

```dart
await loadAppFonts();
```

The `loadAppFonts()` method can be called from anywhere. However, it's important to know
that once you load app fonts, they remain loaded for the remainder of the test execution.
Therefore, app fonts are typically loaded for all tests. This can be done from a special
file that Flutter automatically looks for, called `flutter_test_config.dart`. Place that
file at the root of your test directory.

```dart
import 'package:flutter_test_goldens/flutter_test_goldens.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await loadAppfonts();

  return testMain();
}
```

### How Font Loading Works
The `loadAppFonts()` isn't magic. It may be helpful to understand what it's doing
internally.

At a high level loading app fonts requires the following steps:
 * Load the font manifest, which lists all the app's fonts
 * Iterate through each font
   * Determine the appropriate name to load the font
   * Load the font into Flutter's `FontLoader`

The following code replicates the implementation of `loadAppFonts`, which was
originally shipped with `golden_toolkit`. Educational comments have been added.

```dart
Future<void> loadAppFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Flutter stores the font manifest in a JSON file within the root app
  // asset bundle. Load it and parse it.
  final fontManifest = await rootBundle.loadStructuredData<Iterable<dynamic>>(
    'FontManifest.json',
    (string) async => json.decode(string),
  );

  // Iterate through each font data entry in the JSON and try to load the font.
  for (final Map<String, dynamic> font in fontManifest) {
    // Create a `FontLoader` for this font family (which may include multiple fonts,
    // e.g., normal, bold, italic).
    //
    // Special steps need to be taken to load default fonts like Roboto and SF Pro.
    // Those steps are taken by `derivedFontFamily()`.
    final fontLoader = FontLoader(derivedFontFamily(font));
    
    for (final Map<String, dynamic> fontType in font['fonts']) {
      // Add each font file for this font family, e.g., normal, bold, italic.
      fontLoader.addFont(rootBundle.load(fontType['asset']));
    }
    
    // Load the font.
    await fontLoader.load();
  }
}

/// There is no way to easily load the Roboto or Cupertino fonts.
/// To make them available in tests, a package needs to include their own copies of them.
///
/// GoldenToolkit supplies Roboto because it is free to use.
///
/// However, when a downstream package includes a font, the font family will be prefixed with
/// `/packages/<package name>/<fontFamily>` in order to disambiguate when multiple packages include
/// fonts with the same name.
///
/// Ultimately, the font loader will load whatever we tell it, so if we see a font that looks like
/// a Material or Cupertino font family, let's treat it as the main font family
String derivedFontFamily(Map<String, dynamic> fontDefinition) {
  if (!fontDefinition.containsKey('family')) {
    return '';
  }

  final String fontFamily = fontDefinition['family'];

  if (_overridableFonts.contains(fontFamily)) {
    return fontFamily;
  }

  if (fontFamily.startsWith('packages/')) {
    final fontFamilyName = fontFamily.split('/').last;
    if (_overridableFonts.any((font) => font == fontFamilyName)) {
      return fontFamilyName;
    }
  } else {
    for (final Map<String, dynamic> fontType in fontDefinition['fonts']) {
      final String? asset = fontType['asset'];
      if (asset != null && asset.startsWith('packages')) {
        final packageName = asset.split('/')[1];
        return 'packages/$packageName/$fontFamily';
      }
    }
  }
  return fontFamily;
}

const List<String> _overridableFonts = [
  'Roboto',
  '.SF UI Display',
  '.SF UI Text',
  '.SF Pro Text',
  '.SF Pro Display',
];
```

## Load Material Icons
Material icons aren't available in golden tests because they come from a font, and
Flutter doesn't load any fonts in golden tests.

The easiest way to load Material icons is to use the `loadMaterialIconsFont()` function
in `flutter_test_goldens`. Once loaded, the icons appear in all subsequent tests,
therefore, most developers choose to load icons for all tests. To do this, you
can load icons in a `flutter_test_config.dart` file at the root of your test suite.

```dart
import 'package:flutter_test_goldens/flutter_test_goldens.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await loadMaterialIconsFont();

  return testMain();
}
```

### How Material Icon Loading Works
It may be helpful to know how Material icons are loaded by `loadMaterialIconsFont()`.

The following code is a copy of `loadMaterialIconsFont()` for reference.

```dart
Future<void> loadMaterialIconsFont() async {
  const FileSystem fs = LocalFileSystem();
  const Platform platform = LocalPlatform();
  final Directory flutterRoot = fs.directory(platform.environment['FLUTTER_ROOT']);

  // The following path locates the Material icons within Flutter's cache.
  // This is a magical path that's not publicly exposed by Flutter, but this
  // is the best that the Flutter team has given us.
  final File iconFont = flutterRoot.childFile(
    fs.path.join(
      'bin',
      'cache',
      'artifacts',
      'material_fonts',
      'MaterialIcons-Regular.otf',
    ),
  );

  // Load the Material icon font.
  final Future<ByteData> bytes = Future<ByteData>.value(iconFont.readAsBytesSync().buffer.asByteData());

  // Load the Material icon font into Flutter's `FontLoader`.
  await (FontLoader('MaterialIcons')..addFont(bytes)).load();
}

extension on Directory {
  File childFile(String basename) => File("$path$separator$basename");
}
```
