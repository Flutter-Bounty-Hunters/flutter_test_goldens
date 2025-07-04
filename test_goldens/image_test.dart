import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/flutter_test_goldens.dart';

void main() {
  testWidgets("show an image", (tester) async {
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
              fit: BoxFit.cover,
            ),
          ),
        ),
        debugShowCheckedModeBanner: false,
      ),
    );

    await tester.pump();

    // Note: This test produces slightly different pixels between Ubuntu Docker and GitHub Ubuntu runner.
    await expectLater(find.byType(MaterialApp), matchesGoldenFileWithPixelAllowance("image_test.png", 5));
  });
}
