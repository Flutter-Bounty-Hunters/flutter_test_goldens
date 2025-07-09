import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/flutter_test_goldens.dart';

void main() {
  group("Pixel snapping >", () {
    testWidgets("PixelSnapCenter", (tester) async {
      _configureWindow(tester);

      final contentKey = GlobalKey();

      // Show regular Center behavior.
      await _pumpScaffold(tester, _CenteredSquareAtPartialPixel(contentKey));
      expect(
        tester.getTopLeft(find.byKey(contentKey)),
        Offset(25.35, 25.35),
      );
      expect(tester.getSize(find.byKey(contentKey)), Size(49.3, 49.3));

      // Show PixelSnapCenter behavior (no size snapping).
      await _pumpScaffold(tester, _CenteredSquareAtPartialPixel(contentKey, snapOffset: true));

      // Ensure a whole-pixel offset, but fractional size.
      expect(
        tester.getTopLeft(find.byKey(contentKey)),
        Offset(25, 25),
      );
      expect(tester.getSize(find.byKey(contentKey)), Size(49.3, 49.3));

      // Show PixelSnapCenter behavior (with size snapping).
      await _pumpScaffold(tester, _CenteredSquareAtPartialPixel(contentKey, snapOffset: true, snapSize: true));

      // Ensure a whole-pixel offset, AND whole-pixel size.
      expect(
        tester.getTopLeft(find.byKey(contentKey)),
        Offset(25, 25),
      );
      expect(tester.getSize(find.byKey(contentKey)), Size(49, 49));
    });

    testWidgets("PixelSnapAlign", (tester) async {
      _configureWindow(tester);

      final contentKey = GlobalKey();

      // Show regular Align behavior.
      await _pumpScaffold(tester, _AlignedSquareAtPartialPixel(contentKey));
      expect(
        tester.getTopLeft(find.byKey(contentKey)),
        Offset(13.435500000000001, 13.435500000000001),
      );
      expect(tester.getSize(find.byKey(contentKey)), Size(49.3, 49.3));

      // Show PixelSnapCenter behavior (no size snapping).
      await _pumpScaffold(tester, _AlignedSquareAtPartialPixel(contentKey, snapOffset: true));

      // Ensure a whole-pixel offset.
      expect(
        tester.getTopLeft(find.byKey(contentKey)),
        Offset(13, 13),
      );
      expect(tester.getSize(find.byKey(contentKey)), Size(49.3, 49.3));

      // Show PixelSnapCenter behavior (with size snapping).
      await _pumpScaffold(tester, _AlignedSquareAtPartialPixel(contentKey, snapOffset: true, snapSize: true));

      // Ensure a whole-pixel offset, AND size snapping.
      expect(
        tester.getTopLeft(find.byKey(contentKey)),
        Offset(13, 13),
      );
      expect(tester.getSize(find.byKey(contentKey)), Size(49, 49));
    });

    testWidgets("PixelSnapRow", (tester) async {
      _configureWindow(tester);

      final item1Key = GlobalKey();
      final item2Key = GlobalKey();
      final item3Key = GlobalKey();

      // Show regular Align behavior.
      await _pumpScaffold(
        tester,
        _RowWithPartialPixels(item1Key: item1Key, item2Key: item2Key, item3Key: item3Key),
      );
      expect(tester.getTopLeft(find.byKey(item1Key)), Offset(7.524999999999999, 38.35));
      expect(tester.getSize(find.byKey(item1Key)), Size(23.3, 23.3));
      expect(tester.getTopLeft(find.byKey(item2Key)), Offset(38.349999999999994, 38.35));
      expect(tester.getSize(find.byKey(item2Key)), Size(23.3, 23.3));
      expect(tester.getTopLeft(find.byKey(item3Key)), Offset(69.175, 38.35));
      expect(tester.getSize(find.byKey(item3Key)), Size(23.3, 23.3));

      // Show PixelSnapAlign behavior.
      await _pumpScaffold(
        tester,
        _RowWithPartialPixels(snap: true, item1Key: item1Key, item2Key: item2Key, item3Key: item3Key),
      );

      // Ensure a whole-pixel offset.
      expect(tester.getTopLeft(find.byKey(item1Key)), Offset(7, 38));
      expect(tester.getSize(find.byKey(item1Key)), Size(23, 23));
      expect(tester.getTopLeft(find.byKey(item2Key)), Offset(38, 38));
      expect(tester.getSize(find.byKey(item2Key)), Size(23, 23));
      expect(tester.getTopLeft(find.byKey(item3Key)), Offset(69, 38));
      expect(tester.getSize(find.byKey(item3Key)), Size(23, 23));
    });

    testWidgets("PixelSnapColumn", (tester) async {
      _configureWindow(tester);

      final item1Key = GlobalKey();
      final item2Key = GlobalKey();
      final item3Key = GlobalKey();

      // Show regular Align behavior.
      await _pumpScaffold(
        tester,
        _ColumnWithPartialPixels(item1Key: item1Key, item2Key: item2Key, item3Key: item3Key),
      );
      expect(tester.getTopLeft(find.byKey(item1Key)), Offset(38.35, 7.524999999999999));
      expect(tester.getSize(find.byKey(item1Key)), Size(23.3, 23.3));
      expect(tester.getTopLeft(find.byKey(item2Key)), Offset(38.35, 38.349999999999994));
      expect(tester.getSize(find.byKey(item2Key)), Size(23.3, 23.3));
      expect(tester.getTopLeft(find.byKey(item3Key)), Offset(38.35, 69.175));
      expect(tester.getSize(find.byKey(item3Key)), Size(23.3, 23.3));

      // Show PixelSnapAlign behavior.
      await _pumpScaffold(
        tester,
        _ColumnWithPartialPixels(snap: true, item1Key: item1Key, item2Key: item2Key, item3Key: item3Key),
      );

      // Ensure a whole-pixel offset.
      expect(tester.getTopLeft(find.byKey(item1Key)), Offset(38, 7));
      expect(tester.getSize(find.byKey(item1Key)), Size(23, 23));
      expect(tester.getTopLeft(find.byKey(item2Key)), Offset(38, 38));
      expect(tester.getSize(find.byKey(item2Key)), Size(23, 23));
      expect(tester.getTopLeft(find.byKey(item3Key)), Offset(38, 69));
      expect(tester.getSize(find.byKey(item3Key)), Size(23, 23));
    });
  });
}

Future<void> _pumpScaffold(WidgetTester tester, Widget content) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: content,
      ),
      debugShowCheckedModeBanner: false,
    ),
  );
}

void _configureWindow(WidgetTester tester) {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = Size(100, 100);
}

class _CenteredSquareAtPartialPixel extends StatelessWidget {
  const _CenteredSquareAtPartialPixel(this.contentKey, {this.snapOffset = false, this.snapSize = false});

  final Key contentKey;
  final bool snapOffset;
  final bool snapSize;

  @override
  Widget build(BuildContext context) {
    final square = Container(
      key: contentKey,
      width: 49.3,
      height: 49.3,
      color: Colors.red,
    );

    return snapOffset //
        ? PixelSnapCenter(
            snapSize: snapSize,
            child: square,
          )
        : Center(child: square);
  }
}

class _AlignedSquareAtPartialPixel extends StatelessWidget {
  const _AlignedSquareAtPartialPixel(
    this.contentKey, {
    this.snapOffset = false,
    this.snapSize = false,
  });

  final Key contentKey;
  final bool snapOffset;
  final bool snapSize;

  @override
  Widget build(BuildContext context) {
    final square = Container(
      key: contentKey,
      width: 49.3,
      height: 49.3,
      color: Colors.red,
    );

    return snapOffset
        ? PixelSnapAlign(
            alignment: Alignment(-0.47, -0.47),
            snapSize: snapSize,
            child: square,
          )
        : Align(
            alignment: Alignment(-0.47, -0.47),
            child: square,
          );
  }
}

class _RowWithPartialPixels extends StatelessWidget {
  const _RowWithPartialPixels({
    this.snap = false,
    required this.item1Key,
    required this.item2Key,
    required this.item3Key,
  });

  final bool snap;
  final Key item1Key;
  final Key item2Key;
  final Key item3Key;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: double.infinity,
      child: snap
          ? PixelSnapRow(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: _buildItems(),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: _buildItems(),
            ),
    );
  }

  List<Widget> _buildItems() {
    return [
      Container(key: item1Key, width: 23.3, height: 23.3, color: Colors.red),
      Container(key: item2Key, width: 23.3, height: 23.3, color: Colors.red),
      Container(key: item3Key, width: 23.3, height: 23.3, color: Colors.red),
    ];
  }
}

class _ColumnWithPartialPixels extends StatelessWidget {
  const _ColumnWithPartialPixels({
    this.snap = false,
    required this.item1Key,
    required this.item2Key,
    required this.item3Key,
  });

  final bool snap;
  final Key item1Key;
  final Key item2Key;
  final Key item3Key;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: snap
          ? PixelSnapColumn(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: _buildItems(),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: _buildItems(),
            ),
    );
  }

  List<Widget> _buildItems() {
    return [
      Container(key: item1Key, width: 23.3, height: 23.3, color: Colors.red),
      Container(key: item2Key, width: 23.3, height: 23.3, color: Colors.red),
      Container(key: item3Key, width: 23.3, height: 23.3, color: Colors.red),
    ];
  }
}
