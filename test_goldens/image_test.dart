import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
      ),
    );

    await tester.pump();

    await expectLater(find.byType(MaterialApp), matchesGoldenFile("image_test.png"));
  });
}
