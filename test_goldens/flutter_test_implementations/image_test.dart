import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/flutter_test_goldens.dart';

void main() {
  testWidgets("show an in-memory image", (tester) async {
    // We load the image from a file, but beyond this point, we treat it as in-memory.
    final backgroundImageBytes = File("test_goldens/assets/flutter_background.png").readAsBytesSync();
    final imageProvider = MemoryImage(backgroundImageBytes);

    await tester.runAsync(() async {
      await precacheImage(imageProvider, tester.binding.rootElement!);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.expand(
            child: Image(
              image: imageProvider,
            ),
          ),
        ),
        debugShowCheckedModeBanner: false,
      ),
    );

    // Note: This test produces slightly different pixels between Ubuntu Docker and GitHub Ubuntu runner.
    await expectLater(find.byType(MaterialApp), matchesGoldenFileWithPixelAllowance("image_memory_test.png", 5));
  });

  testWidgets("show a file image", (tester) async {
    final imageFile = File("test_goldens/assets/flutter_background.png");
    final imageProvider = FileImage(imageFile);

    await tester.runAsync(() async {
      await precacheImage(imageProvider, tester.binding.rootElement!);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.expand(
            child: Image.file(imageFile),
          ),
        ),
        debugShowCheckedModeBanner: false,
      ),
    );

    // Note: This test produces slightly different pixels between Ubuntu Docker and GitHub Ubuntu runner.
    await expectLater(find.byType(MaterialApp), matchesGoldenFileWithPixelAllowance("image_file_test.png", 5));
  });

  testWidgets("show a network image", (tester) async {
    const imageUrl =
        "https://upload.wikimedia.org/wikipedia/commons/b/b3/Vista_Satelital_de_Nohyaxch%C3%A9_y_Edzn%C3%A1%2C_Campeche.png";

    // Normally, Flutter forcibly prevents HTTP calls. Turn that off by null'ing out
    // the HttpOverrides.
    final testOverride = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = testOverride);

    // Load the image from the internet. This must be done in `runAsync` because
    // network communication is a real asynchronous behavior.
    await tester.runAsync(() async {
      await precacheImage(NetworkImage(imageUrl), tester.binding.rootElement!);
    });

    // Display the image in the widget tree.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Image.network(imageUrl),
          ),
        ),
        debugShowCheckedModeBanner: false,
      ),
    );

    await expectLater(find.byType(MaterialApp), matchesGoldenFileWithPixelAllowance("image_network_test.png", 0));
  });
}
