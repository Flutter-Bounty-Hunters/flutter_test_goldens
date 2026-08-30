import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test_goldens/src/png/png_metadata.dart';
import 'package:image/image.dart';
import 'package:path/path.dart' as path;

/// Extracts every golden image within the golden scene [sceneFile] to its own
/// PNG file, written next to [sceneFile].
///
/// Each extracted file name begins with the scene file's name, followed by the
/// golden's order within the scene and the golden's ID, e.g., a scene called
/// `my_scene.png` produces `my_scene.01_first.png`, `my_scene.02_second.png`,
/// and so on. This naming keeps the extracted files grouped next to their scene
/// in a file listing, and preserves the visual order of the goldens.
///
/// Returns the files that were written. If [sceneFile] carries no golden scene
/// metadata then no files are written and an empty list is returned.
///
/// When [overwrite] is `false`, an existing file with the same name is left
/// untouched and included in the returned list.
List<File> extractSceneFileToImages(File sceneFile, {bool overwrite = true}) {
  final goldens = extractGoldensFromSceneBytes(sceneFile.readAsBytesSync());
  if (goldens.isEmpty) {
    return const [];
  }

  final sceneName = path.basenameWithoutExtension(sceneFile.path);
  final directory = sceneFile.parent.path;

  final writtenFiles = <File>[];
  for (final golden in goldens) {
    final fileName = _extractedFileName(sceneName, golden, goldens.length);
    final file = File(path.join(directory, fileName));

    if (!file.existsSync() || overwrite) {
      file.writeAsBytesSync(encodePng(golden.image));
    }

    writtenFiles.add(file);
  }

  return writtenFiles;
}

/// Crops every golden image out of the golden scene encoded in [sceneBytes] and
/// returns them in the order that they appear within the scene metadata.
///
/// Returns an empty list if [sceneBytes] carries no golden scene metadata, which
/// is how a regular (non-scene) PNG is distinguished from a golden scene.
List<ExtractedGolden> extractGoldensFromSceneBytes(Uint8List sceneBytes) {
  final sceneMetadataJson = sceneBytes.readTextMetadata()[_sceneMetadataKey];
  if (sceneMetadataJson == null) {
    return const [];
  }

  final sceneImage = decodePng(sceneBytes);
  if (sceneImage == null) {
    throw const FormatException("Golden scene is not a decodable PNG.");
  }

  final sceneMetadata = jsonDecode(sceneMetadataJson) as Map<String, dynamic>;
  final imagesMetadata = sceneMetadata["images"] as List<dynamic>;

  final goldens = <ExtractedGolden>[];
  for (var index = 0; index < imagesMetadata.length; index += 1) {
    final imageMetadata = imagesMetadata[index] as Map<String, dynamic>;
    final topLeft = imageMetadata["topLeft"] as Map<String, dynamic>;
    final size = imageMetadata["size"] as Map<String, dynamic>;

    final goldenImage = copyCrop(
      sceneImage,
      x: (topLeft["x"] as num).round(),
      y: (topLeft["y"] as num).round(),
      width: (size["width"] as num).round(),
      height: (size["height"] as num).round(),
    );

    goldens.add(
      ExtractedGolden(
        order: index + 1,
        id: imageMetadata["id"] as String,
        image: goldenImage,
      ),
    );
  }

  return goldens;
}

String _extractedFileName(String sceneName, ExtractedGolden golden, int goldenCount) {
  final orderDigitCount = goldenCount.toString().length.clamp(2, 3);
  final order = golden.order.toString().padLeft(orderDigitCount, "0");
  return "$sceneName.${order}_${_toSafeFileName(golden.id)}.png";
}

String _toSafeFileName(String id) => id.replaceAll(RegExp(r"[\\/\s]+"), "_");

const _sceneMetadataKey = "flutter_test_goldens";

/// A single golden image cropped out of a golden scene, along with the
/// information needed to name its extracted file.
///
/// [ExtractedGolden] does not carry any of the scene's metadata within its
/// [image] - it holds only the golden's cropped pixels.
class ExtractedGolden {
  const ExtractedGolden({
    required this.order,
    required this.id,
    required this.image,
  });

  /// The 1-based position of this golden within its scene, following the order
  /// of the scene metadata (which matches the visual layout order).
  final int order;

  /// The golden's ID, as recorded in the scene metadata.
  final String id;

  /// The cropped pixels of this golden.
  final Image image;
}
