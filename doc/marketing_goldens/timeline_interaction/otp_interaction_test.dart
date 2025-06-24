import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/flutter_test_goldens.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../shadcn_test_tools.dart';

void main() {
  group("Marketing > timeline > interaction", () {
    testGoldenScene("OTP", (tester) async {
      FtgLog.initAllLogs();

      GoldenSceneTheme.useForTest(GoldenSceneTheme.current.copyWith(
        defaultTextStyle: TextStyle(
          color: ShadBlueColorScheme.dark().primary,
        ),
      ));

      // The following code is broken apart so we can include pieces across slides.
      final timeline = Timeline(
        "OTP - Digit Entry",
        fileName: 'otp',
        itemScaffold: shadcnItemScaffold,
        layout: ColumnSceneLayout(
          background: GoldenSceneBackground.widget(ShadcnBackground()),
          itemDecorator: shadcnItemDecorator,
        ),
      );

      timeline.setupWithWidget(Padding(
        padding: const EdgeInsets.all(48),
        child: ShadInputOTP(
          onChanged: (v) {},
          maxLength: 6,
          children: [
            const ShadInputOTPGroup(
              children: [
                ShadInputOTPSlot(key: ValueKey("1")),
                ShadInputOTPSlot(key: ValueKey("2")),
                ShadInputOTPSlot(key: ValueKey("3")),
              ],
            ),
            Icon(size: 24, LucideIcons.dot),
            const ShadInputOTPGroup(
              children: [
                ShadInputOTPSlot(key: ValueKey("4")),
                ShadInputOTPSlot(key: ValueKey("5")),
                ShadInputOTPSlot(key: ValueKey("6")),
              ],
            ),
          ],
        ),
      ));

      await timeline
          .takePhoto("Idle")
          .tap(find.byType(ShadInputOTPSlot).first)
          .settle()
          .takePhoto("Initial focus")
          .modifyScene(_insertOtpAt("1", "a"))
          .takePhoto("Type first character")
          .modifyScene(_insertOtpAt("2", "b"))
          .takePhoto("Type 2nd character")
          .modifyScene(_insertOtpAt("3", "c"))
          .takePhoto("Type 3rd character")
          .modifyScene(_insertOtpAt("4", "1"))
          .takePhoto("Type 4th character")
          .modifyScene(_insertOtpAt("5", "2"))
          .takePhoto("Type 5th character")
          .modifyScene(_insertOtpAt("6", "3"))
          .takePhoto("Type last character")
          .run(tester);
    });
  });
}

TimelineModifySceneDelegate _insertOtpAt(String key, String character) {
  return (tester, testContext) async {
    await tester.enterText(find.byKey(ValueKey(key)), character);
    await tester.pumpAndSettle();
  };
}
