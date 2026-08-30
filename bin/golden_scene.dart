import 'dart:io';

import 'package:flutter_test_goldens/src/scenes/scene_file_extractor.dart';

/// Command line tool for working with golden scene files.
///
/// Once this package is globally activated, run it as:
///
///     golden-scene <command> [arguments]
///
/// Without global activation, run it through the Dart tool:
///
///     dart run flutter_test_goldens:golden_scene <command> [arguments]
///
/// Available commands:
///
///  * `extract` - extracts each golden image within a scene to its own file.
void main(List<String> arguments) {
  if (arguments.isEmpty) {
    _printUsage();
    exit(64);
  }

  final command = arguments.first;
  final commandArguments = arguments.sublist(1);
  switch (command) {
    case _commandExtract:
      _runExtract(commandArguments);
    case "help":
    case "--help":
    case "-h":
      _printUsage();
    default:
      stderr.writeln("Unknown command: $command");
      _printUsage();
      exit(64);
  }
}

const _commandExtract = "extract";

void _printUsage() {
  stdout.writeln("""
Tool for working with golden scene files.

Usage: golden-scene <command> [arguments]

Commands:
  extract [--dry-run] <scene.png|directory>...
      Extracts each golden image within a scene to its own PNG file, written
      next to the scene. Directories are searched recursively for scenes.
""");
}

/// Runs the `extract` command, which extracts each golden image within one or
/// more golden scene files to standalone PNG files, written next to each scene.
void _runExtract(List<String> arguments) {
  final request = _parseExtractArguments(arguments);
  if (request == null) {
    stderr.writeln("Usage: golden-scene extract [--dry-run] <scene.png|directory>...");
    exit(64);
  }

  for (final sceneFile in _findSceneFiles(request.inputPaths)) {
    if (request.isDryRun) {
      final goldens = extractGoldensFromSceneBytes(sceneFile.readAsBytesSync());
      _reportResult(sceneFile, goldens.length);
      continue;
    }

    final writtenFiles = extractSceneFileToImages(sceneFile);
    _reportResult(sceneFile, writtenFiles.length);
  }
}

_ExtractRequest? _parseExtractArguments(List<String> arguments) {
  var isDryRun = false;
  final inputPaths = <String>[];
  for (final argument in arguments) {
    if (argument == _argDryRun) {
      isDryRun = true;
    } else {
      inputPaths.add(argument);
    }
  }

  if (inputPaths.isEmpty) {
    return null;
  }

  return _ExtractRequest(inputPaths: inputPaths, isDryRun: isDryRun);
}

const _argDryRun = "--dry-run";

void _reportResult(File sceneFile, int goldenCount) {
  if (goldenCount == 0) {
    stdout.writeln("skipped (no scene metadata): ${sceneFile.path}");
  } else {
    stdout.writeln("${sceneFile.path} -> $goldenCount images");
  }
}

/// Expands the given [inputPaths] into golden scene files, searching any
/// directories recursively for PNG files.
Iterable<File> _findSceneFiles(List<String> inputPaths) sync* {
  for (final inputPath in inputPaths) {
    final entityType = FileSystemEntity.typeSync(inputPath);
    if (entityType == FileSystemEntityType.directory) {
      final pngFiles = Directory(inputPath) //
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.toLowerCase().endsWith(".png"));
      yield* pngFiles;
    } else {
      yield File(inputPath);
    }
  }
}

class _ExtractRequest {
  const _ExtractRequest({
    required this.inputPaths,
    required this.isDryRun,
  });

  final List<String> inputPaths;
  final bool isDryRun;
}
