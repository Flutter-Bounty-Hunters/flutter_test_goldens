import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/src/flutter/pixel_boundary_box.dart';

void main() {
  group("Pixel boundary box >", () {
    testWidgets("does not modify incoming integer constraints", (tester) async {
      final pixelBoundaryKey = GlobalKey(debugLabel: "pixel-boundary");
      final childKey = GlobalKey(debugLabel: "child");

      await _pumpScaffold(
        tester,
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 100, maxHeight: 75),
          child: PixelBoundaryBox(
            key: pixelBoundaryKey,
            child: Container(
              key: childKey,
              width: double.infinity,
              height: double.infinity,
              color: Colors.red,
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byKey(pixelBoundaryKey)), Size(100, 75));
      expect(tester.getSize(find.byKey(childKey)), Size(100, 75));
    });

    testWidgets("adjusts incoming non-integer constraints", (tester) async {
      final pixelBoundaryKey = GlobalKey(debugLabel: "pixel-boundary");
      final childKey = GlobalKey(debugLabel: "child");

      await _pumpScaffold(
        tester,
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 100.7, maxHeight: 75.8),
          child: PixelBoundaryBox(
            key: pixelBoundaryKey,
            child: Container(
              key: childKey,
              width: double.infinity,
              height: double.infinity,
              color: Colors.red,
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byKey(pixelBoundaryKey)), Size(100, 75));
      expect(tester.getSize(find.byKey(childKey)), Size(100, 75));
    });

    testWidgets("adjusts non-integer child size", (tester) async {
      final pixelBoundaryKey = GlobalKey(debugLabel: "pixel-boundary");
      final childKey = GlobalKey(debugLabel: "child");

      // First, try a bounded size that's larger than the child.
      await _pumpScaffold(
        tester,
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 100, maxHeight: 75),
          child: PixelBoundaryBox(
            key: pixelBoundaryKey,
            child: Container(
              key: childKey,
              width: 88.5,
              height: 48.2,
              color: Colors.red,
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byKey(pixelBoundaryKey)), Size(89, 49));
      expect(tester.getSize(find.byKey(childKey)), Size(89, 49));

      // Second, try an unbounded parent.
      await _pumpScaffold(
        tester,
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: double.infinity, maxHeight: double.infinity),
          child: PixelBoundaryBox(
            key: pixelBoundaryKey,
            child: Container(
              key: childKey,
              width: 88.5,
              height: 48.2,
              color: Colors.red,
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byKey(pixelBoundaryKey)), Size(89, 49));
      expect(tester.getSize(find.byKey(childKey)), Size(89, 49));
    });
  });
}

Future<void> _pumpScaffold(WidgetTester tester, Widget content) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: content,
        ),
      ),
    ),
  );
}
