import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("Regular goldens >", () {
    testWidgets("blocky font and no icons", (tester) async {
      tester.view
        ..devicePixelRatio = 1.0
        ..physicalSize = Size(500, 100);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              leading: Icon(Icons.adaptive.arrow_back),
              title: Text("Hello"),
              backgroundColor: Colors.blue,
            ),
          ),
        ),
      );

      await expectLater(find.byType(AppBar), matchesGoldenFile("blocky_font_no_icons.png"));
    });
  });
}
