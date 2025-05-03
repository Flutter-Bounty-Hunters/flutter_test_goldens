import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/flutter_test_goldens.dart';

extension FlutterTestGoldens on WidgetTester {
  /// Pumps a [widgetTree] and then adjusts the test window size to exactly match the
  /// intrinsic size of the [widgetTree].
  ///
  /// The [widgetTree] must have an intrinsic size. If it attempts to fill all width or
  /// height, an exception is thrown.
  ///
  /// The end result is accomplished by pumping the tree twice. First, the tree is pumped
  /// such that [widgetTree] is unbounded. The size of [widgetTree] is inspected. The size
  /// of the test window is changed to match [widgetTree]. Finally, [widgetTree] is pumped
  /// again with the final window size.
  Future<void> pumpWidgetAndAdjustWindow(Widget widgetTree) async {
    FtgLog.pipeline.fine("Pumping a widget tree and adjusting window size.");
    final contentKey = GlobalKey();

    await pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: OverflowBox(
          maxWidth: double.infinity,
          minWidth: 0,
          maxHeight: double.infinity,
          minHeight: 0,
          alignment: Alignment.topLeft,
          child: KeyedSubtree(
            key: contentKey,
            child: widgetTree,
          ),
        ),
      ),
    );

    // Look up the natural content dimensions.
    final contentSize = contentKey.currentContext!.size!;
    FtgLog.pipeline.fine("Final content and window size: $contentSize");

    // Change test window to exactly fit widget tree.
    view.physicalSize = contentSize;

    // Pump again so that the widget tree settles within the final window bounds.
    await pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: widgetTree,
      ),
    );
  }

  Future<(TestGesture, Offset)> hoverOver(Finder finder) async {
    final Offset hoverPosition = getCenter(finder);
    final TestGesture gesture = await createGesture(kind: PointerDeviceKind.mouse);

    // Start the gesture away from the destination, so we trigger a mouse enter event.
    await gesture.moveTo(Offset.zero);
    await pump();

    // Simulate a hover.
    await gesture.moveTo(hoverPosition);

    return (gesture, hoverPosition);
  }
}
