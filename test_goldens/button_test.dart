import 'dart:ui';

import 'package:flutter/material.dart' show MaterialApp, Scaffold;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/flutter_test_goldens.dart';
import 'package:lucid/lucid.dart';

void main() {
  testWidgets("button interactions", (tester) async {
    final goldenKey = GlobalKey();

    await FilmStrip(tester)
        .setupWithPump(() {
          return MaterialApp(
            home: Scaffold(
              backgroundColor: const Color(0xFF222222),
              body: LucidBrightness(
                brightness: Brightness.dark,
                child: Center(
                  child: Padding(
                    key: goldenKey,
                    padding: const EdgeInsets.all(48),
                    child: ButtonSheet(
                      child: Text("Hello"),
                    ),
                  ),
                ),
              ),
            ),
          );
        })
        .takePhoto(find.byKey(goldenKey), "idle")
        .modifyScene((tester, scratchPad) async {
          // Hover over button.
          final Offset hoverPosition = tester.getCenter(find.byType(ButtonSheet));
          final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
          await gesture.moveTo(Offset.zero);
          await tester.pump();
          await gesture.moveTo(hoverPosition); // Simulate hover
          await tester.pump(); // Rebuild UI after hover event

          scratchPad["gesture"] = gesture;
          scratchPad["hoverPosition"] = hoverPosition;
        })
        .takePhoto(find.byKey(goldenKey), "hover")
        .modifyScene((tester, scratchPad) async {
          // Press on button.
          final gesture = scratchPad["gesture"] as TestGesture;
          await gesture.down(scratchPad["hoverPosition"] as Offset);
          await tester.pump();
        })
        .takePhoto(find.byKey(goldenKey), "pressed")
        .renderOrCompareGolden("button", FilmStripLayout.row);
  });
}
