import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/src/png/png_metadata.dart';

void main() {
  group("PNG metadata >", () {
    // To inspect a PNG's metadata, you can use `exiftool`, which is a CLI app.
    // > exiftool my_image.png

    // To **add** a tEXt key/value pair to a PNG, use pngcrush
    // > pngcrush -text b "my key" "my value" original_image.png new_image.png

    test("can read tEXt", () {
      final pngData = File("test/png/reference_pngs/example_with_tEXt.png").readAsBytesSync();
      final metadata = pngData.readTextMetadata();

      expect(
        metadata,
        {
          // Note: It seems that encoding converts keys to lowercase and replaces spaces with "_".
          "flutter_test_goldens": "This is plain text stored as PNG metadata",
          "second_chunk": "This is the 2nd tEXt chunk in this PNG",
        },
      );
    });

    test("can write tEXt", () {
      final pngData = File("test/png/reference_pngs/example_without_tEXt.png").readAsBytesSync();
      var metadata = pngData.readTextMetadata();

      // Ensure original PNG data has no tEXt, before we try to add some.
      expect(metadata, isEmpty);

      // Add a couple tEXt chunks.
      var newData = pngData.copyWithTextMetadata("key1", "This is the first value");
      newData = newData.copyWithTextMetadata("key2", "This is the second value");

      // Read the data back out.
      metadata = newData.readTextMetadata();

      // Ensure our added chunks were read back out.
      expect(
        metadata,
        {
          "key1": "This is the first value",
          "key2": "This is the second value",
        },
      );
    });
  });
}
