import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/flutter_test_goldens.dart';

void main() {
  testGoldenSceneOnIOS('iPhone keyboard', (tester) async {
    await Timeline(
      "iPhone Keyboard",
      fileName: "iphone_simulated-keyboard",
      layout: RowSceneLayout(),
    )
        .setupWithWidget(
          FakeScreen(
            // iPhone 16 point resolution
            size: const Size(393, 852),
            renderSimulatedKeyboard: true,
            animateKeyboard: true,
            child: Material(
              color: Colors.white,
              child: Center(
                child: TextField(
                  onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                ),
              ),
            ),
          ),
        )
        .takePhoto('Start')
        .modifyScene(
          (tester, TimelineTestContext testContext) async {
            await tester.tap(find.byType(TextField));
            await tester.pump();
          },
        )
        .takePhotos(5, const Duration(milliseconds: 125))
        .modifyScene(
          (tester, TimelineTestContext testContext) async {
            // Tap outside the field to close keyboard.
            await tester.tapAt(Offset(1, 1));
            await tester.pump();
          },
        )
        .takePhotos(5, const Duration(milliseconds: 125))
        .run(tester);
  });
}
