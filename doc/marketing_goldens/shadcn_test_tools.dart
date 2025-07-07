import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/flutter_test_goldens.dart';
import 'package:golden_bricks/golden_bricks.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

final shadcnWordmark = File("doc/marketing_goldens/single_shot/shadcn_wordmark.png").readAsBytesSync();
final shadcnWordmarkProvider = MemoryImage(shadcnWordmark);

/// An item scaffold that builds a Shadcn scaffold.
Widget shadcnItemScaffold(WidgetTester tester, Widget content) {
  return buildShadcnScaffold(content);
}

/// Builds a widget tree with Shadcn dependencies at the root, and [content] within
/// its subtree.
Widget buildShadcnScaffold(Widget content) {
  return ShadApp(
    theme: ShadThemeData(
      brightness: Brightness.dark,
      colorScheme: ShadBlueColorScheme.dark(),
      textTheme: ShadTextTheme(
        family: goldenBricks,
      ),
    ),
    home: Scaffold(
      body: Builder(builder: (context) {
        return DefaultTextStyle(
          style: DefaultTextStyle.of(context).style.copyWith(fontFamily: goldenBricks),
          child: GoldenImageBounds(
            child: content,
          ),
        );
      }),
    ),
    debugShowCheckedModeBanner: false,
  );
}

class ShadcnSingleShotSceneLayout implements SceneLayout {
  const ShadcnSingleShotSceneLayout({
    required this.shadcnWordmarkProvider,
    this.aspectRatio,
  });

  final ImageProvider shadcnWordmarkProvider;

  /// The desired aspect ratio of the final golden, which is useful when creating
  /// website header version.
  ///
  /// When `null`, no aspect ratio is enforced.
  final double? aspectRatio;

  @override
  Widget build(
    WidgetTester tester,
    BuildContext context,
    SceneLayoutContent content,
  ) {
    final golden = content.goldens.entries.first;

    return DefaultTextStyle(
      style: GoldenSceneTheme.current.defaultTextStyle.copyWith(
        color: ShadBlueColorScheme.dark().primary,
      ),
      child: IntrinsicWidth(
        child: IntrinsicHeight(
          child: GoldenSceneBounds(
            child: aspectRatio != null
                ? AspectRatio(
                    aspectRatio: aspectRatio!,
                    child: _buildContent(golden),
                  )
                : _buildContent(golden),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(MapEntry<GoldenSceneScreenshot, GlobalKey> golden) {
    return ShadcnBackground(
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(48),
          padding: const EdgeInsets.all(48),
          color: ShadBlueColorScheme.dark().background,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 24,
            children: [
              Image(
                image: shadcnWordmarkProvider,
                height: 30,
                fit: BoxFit.contain,
              ),
              Image.memory(
                key: golden.value,
                golden.key.pngBytes,
                width: golden.key.size.width.toDouble(),
                height: golden.key.size.height.toDouble(),
              ),
              Text(
                "Calendar - Current Month",
                style: TextStyle(
                  color: ShadBlueColorScheme.dark().primary,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShadcnGalleryLayout implements SceneLayout {
  const ShadcnGalleryLayout({
    required this.shadcnWordmarkProvider,
  });

  final ImageProvider shadcnWordmarkProvider;

  @override
  Widget build(
    WidgetTester tester,
    BuildContext context,
    SceneLayoutContent content,
  ) {
    final entries = content.goldens.entries.toList();

    return DefaultTextStyle(
      style: GoldenSceneTheme.current.defaultTextStyle.copyWith(
        color: ShadBlueColorScheme.dark().primary,
      ),
      child: GoldenSceneBounds(
        child: CustomPaint(
          painter: AngledLinePainter(
            angleDegrees: -45,
            gap: 50,
            thickness: 5,
            lineColor: ShadBlueColorScheme.dark().accent.withValues(alpha: 0.2),
            backgroundColor: ShadBlueColorScheme.dark().background,
          ),
          child: Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 24,
              children: [
                Image(
                  image: shadcnWordmarkProvider,
                  height: 30,
                  fit: BoxFit.contain,
                ),
                Table(
                  defaultColumnWidth: IntrinsicColumnWidth(),
                  children: _buildRows(entries),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<TableRow> _buildRows(List<MapEntry<GoldenSceneScreenshot, GlobalKey>> entries) {
    final rows = <TableRow>[];
    for (int row = 0; row < entries.length / 3; row += 1) {
      final items = <Widget>[];
      for (int col = 0; col < 3; col += 1) {
        final index = row * 3 + col;
        if (index >= entries.length) {
          items.add(const SizedBox());
          continue;
        }

        items.add(
          Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(48),
              color: ShadBlueColorScheme.dark().background,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 24,
                children: [
                  Image.memory(
                    key: entries[index].value,
                    entries[index].key.pngBytes,
                    width: entries[index].key.size.width,
                    height: entries[index].key.size.height,
                  ),
                  Text(
                    entries[index].key.metadata.description,
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      rows.add(
        TableRow(
          children: items,
        ),
      );
    }

    return rows;
  }
}

class ShadcnBackground extends StatelessWidget {
  const ShadcnBackground({
    super.key,
    this.child,
  });

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: AngledLinePainter(
        angleDegrees: -45,
        gap: 50,
        thickness: 5,
        lineColor: ShadBlueColorScheme.dark().accent.withValues(alpha: 0.2),
        backgroundColor: ShadBlueColorScheme.dark().background,
      ),
      child: child,
    );
  }
}

Widget shadcnItemDecorator(
  BuildContext context,
  GoldenScreenshotMetadata metadata,
  Widget content,
) {
  return ColoredBox(
    color: ShadBlueColorScheme.dark().background,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        content,
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            metadata.description,
            style: TextStyle(fontFamily: TestFonts.openSans),
          ),
        ),
      ],
    ),
  );
}
