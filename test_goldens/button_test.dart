import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ButtonStyle, Colors, ElevatedButton, MaterialApp, Scaffold;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucid/lucid.dart';

void main() {
  testWidgets("button interactions", (tester) async {
    final goldenKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF222222),
          body: LucidBrightness(
            brightness: Brightness.dark,
            child: Center(
              child: RepaintBoundary(
                key: goldenKey,
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: ButtonSheet(
                    child: Text("Hello"),
                  ),

                  // child: ElevatedButton(
                  //   style: ButtonStyle(
                  //     backgroundColor: WidgetStateProperty.resolveWith((state) {
                  //       if (state.contains(WidgetState.pressed)) {
                  //         return Colors.red;
                  //       }
                  //       if (state.contains(WidgetState.hovered)) {
                  //         return Colors.blue;
                  //       }
                  //       return Colors.green;
                  //     }),
                  //   ),
                  //   onPressed: () {},
                  //   child: Text("Hello"),
                  // ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final boundary = goldenKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final screenshotIdle = await boundary.toImage(pixelRatio: 1.0);

    // Hover over button.
    final Offset hoverPosition = tester.getCenter(find.byType(ButtonSheet));
    // final Offset hoverPosition = tester.getCenter(find.byType(ElevatedButton));
    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.moveTo(Offset.zero);
    await tester.pump();
    await gesture.moveTo(hoverPosition); // Simulate hover
    await tester.pump(); // Rebuild UI after hover event

    final screenshotHover = await boundary.toImage(pixelRatio: 1.0);

    // Press on button.
    await gesture.down(hoverPosition);
    await tester.pump();

    final screenshotPressed = await boundary.toImage(pixelRatio: 1.0);

    late final Uint8List pixelsIdle;
    late final Uint8List pixelsHover;
    late final Uint8List pixelsPressed;
    await tester.runAsync(() async {
      final byteData = await screenshotIdle.toByteData(format: ImageByteFormat.png);
      pixelsIdle = byteData!.buffer.asUint8List();

      final hoverData = await screenshotHover.toByteData(format: ImageByteFormat.png);
      pixelsHover = hoverData!.buffer.asUint8List();

      final pressedData = await screenshotPressed.toByteData(format: ImageByteFormat.png);
      pixelsPressed = pressedData!.buffer.asUint8List();
    });

    tester.view
      ..physicalSize = Size(
        (screenshotIdle.width + screenshotHover.width + screenshotPressed.width).toDouble(),
        screenshotIdle.height.toDouble(),
      )
      ..devicePixelRatio = 1.0;

    final idleKey = GlobalKey();
    final hoverKey = GlobalKey();
    final pressedKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Color(0xFF222222),
          body: Center(
            child: Row(
              children: [
                Image.memory(
                  key: idleKey,
                  pixelsIdle,
                  width: screenshotIdle.width.toDouble(),
                  height: screenshotIdle.height.toDouble(),
                ),
                Image.memory(
                  key: hoverKey,
                  pixelsHover,
                  width: screenshotHover.width.toDouble(),
                  height: screenshotHover.height.toDouble(),
                ),
                Image.memory(
                  key: pressedKey,
                  pixelsPressed,
                  width: screenshotPressed.width.toDouble(),
                  height: screenshotPressed.height.toDouble(),
                ),
              ],
            ),
          ),
        ),
        debugShowCheckedModeBanner: false,
      ),
    );

    await tester.runAsync(() async {
      await precacheImage(
        MemoryImage(pixelsIdle),
        tester.element(find.byKey(idleKey)),
      );
      await precacheImage(
        MemoryImage(pixelsIdle),
        tester.element(find.byKey(hoverKey)),
      );
      await precacheImage(
        MemoryImage(pixelsIdle),
        tester.element(find.byKey(pressedKey)),
      );
    });

    await tester.runAsync(() async {
      // Without this delay, the screenshot loading is spotty. However, with
      // this delay, we seem to always get screenshots displayed in the widget tree.
      await Future.delayed(const Duration(milliseconds: 1));
    });

    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile("button.png"));
  });
}
