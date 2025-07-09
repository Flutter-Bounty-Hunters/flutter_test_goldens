import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/flutter_test_goldens.dart';

void main() {
  group("Known failure cases >", () {
    testGoldenScene("text layout with partial pixel", (tester) async {
      // I think the problem here is related to a partial pixel difference
      // between the action of generating goldens vs extracting goldens.
      //
      // When generating: Offset(100.7, 48.0), size: Size(126.0, 68.0)
      //
      // When comparing: Offset(1136.9, 866.0), size: Size(126.2, 68.0)
      //
      // This test uses a custom item scaffold, which is actually the same
      // as what the default item scaffold used to be. I found that the
      // specific thing leading to a partial pixel boundary was the use of
      // of `Center`, so I removed that from the default scaffold, and retained
      // it here for reference.
      //
      // The problem is that `Center` really is the desired layout for most
      // scenes, so forcing people to use top/left alignment results in less
      // desirable scene layouts.
      await SingleShot(
        "Text layout with partial pixel",
        fileName: "text_layout_with_partial_pixel",
      ) //
          .fromWidget(
            Padding(
              padding: EdgeInsets.all(24),
              child: Text("Hello, World!"),
            ),
          )
          .withLayout(ColumnSceneLayout(
            itemDecorator: _centeredItemDecorator,
          ))
          .run(tester);
    });
  });
}

Widget _centeredItemDecorator(
  BuildContext context,
  GoldenScreenshotMetadata metadata,
  Widget content,
) {
  return ColoredBox(
    // TODO: need this to be configurable, e.g., light vs dark
    color: Colors.white,
    child: IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PixelSnapCenter(
            child: content,
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              metadata.description,
              style: TextStyle(fontFamily: TestFonts.openSans),
            ),
          ),
        ],
      ),
    ),
  );
}
