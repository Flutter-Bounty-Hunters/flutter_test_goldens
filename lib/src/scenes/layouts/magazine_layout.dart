import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart' show Colors;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/src/fonts/fonts.dart';
import 'package:flutter_test_goldens/src/goldens/golden_collections.dart';
import 'package:flutter_test_goldens/src/goldens/golden_rendering.dart';
import 'package:flutter_test_goldens/src/scenes/golden_scene.dart';
import 'package:flutter_test_goldens/src/scenes/scene_layout.dart';

class MagazineGoldenSceneLayout implements SceneLayout {
  const MagazineGoldenSceneLayout({
    this.sceneBackground,
    this.featureBackground,
    this.featurePadding = defaultFeaturePadding,
    this.featureTitle = "",
    required this.featureFrameBuilder,
    this.gridBackground,
    this.gridSpacing = defaultGridSpacing,
  });

  /// Background (optional) that spans the entire scene, across both the featured
  /// section and grid section.
  ///
  /// Transparent when `null`.
  final GoldenSceneBackground? sceneBackground;

  /// Background (optional) that spans only the featured section.
  final GoldenSceneBackground? featureBackground;
  final EdgeInsets featurePadding;
  final String featureTitle;
  final MagazineFeatureBuilder featureFrameBuilder;

  /// Background (optional) that spans only the grid section.
  final GoldenSceneBackground? gridBackground;
  final GridSpacing gridSpacing;

  @override
  Widget build(
    WidgetTester tester,
    BuildContext context,
    Map<GoldenSceneScreenshot, GlobalKey<State<StatefulWidget>>> goldens,
  ) {
    final goldensList = goldens.entries.toList();

    return MagazineGoldenScene(
      sceneBackground: sceneBackground,
      featureBackground: featureBackground,
      featurePadding: featurePadding,
      featureTitle: featureTitle,
      featureFrameBuilder: featureFrameBuilder,
      featuredGolden: (goldensList.first.key, goldensList.first.value),
      gridBackground: gridBackground,
      gridSpacing: gridSpacing,
      gridGoldens: Map.fromEntries(goldensList.sublist(1)),
    );
  }
}

/// A "magazine layout" includes a single "featured" golden on the left side, kind of like
/// a full-page feature in a magazine, followed by a grid of other goldens to the right.
///
/// A magazine layout can be used, for example, to display one golden within a device frame,
/// showing where the widget lives in the real app, and then fill out a bunch of other variations
/// of that widget in a grid to the right.
class MagazineGoldenScene extends StatelessWidget {
  const MagazineGoldenScene({
    super.key,
    this.sceneBackground,
    this.featureBackground,
    this.featurePadding = defaultFeaturePadding,
    this.featureTitle = "",
    required this.featureFrameBuilder,
    required this.featuredGolden,
    this.gridBackground,
    this.gridSpacing = defaultGridSpacing,
    required this.gridGoldens,
  });

  /// Background (optional) that spans the entire scene, across both the featured
  /// section and grid section.
  ///
  /// Transparent when `null`.
  final GoldenSceneBackground? sceneBackground;

  /// Background (optional) that spans only the featured section.
  final GoldenSceneBackground? featureBackground;
  final EdgeInsets featurePadding;
  final String featureTitle;
  final MagazineFeatureBuilder featureFrameBuilder;
  final (GoldenSceneScreenshot, GlobalKey) featuredGolden;

  /// Background (optional) that spans only the grid section.
  final GoldenSceneBackground? gridBackground;
  final GridSpacing gridSpacing;
  final Map<GoldenSceneScreenshot, GlobalKey> gridGoldens;

  @override
  Widget build(BuildContext context) {
    return GoldenSceneBounds(
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                if (featureBackground != null) //
                  Positioned.fill(
                    child: featureBackground!.build(context),
                  ),
                Padding(
                  padding: featurePadding,
                  child: featureFrameBuilder(
                    context,
                    Center(
                      child: SizedBox.fromSize(
                        size: featuredGolden.$1.size,
                        child: Image.memory(
                          key: featuredGolden.$2,
                          featuredGolden.$1.pngBytes,
                          width: featuredGolden.$1.size.width,
                          height: featuredGolden.$1.size.height,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: featurePadding.bottom,
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                        child: Container(
                          color: Colors.white.withValues(alpha: 0.3),
                          padding: EdgeInsets.symmetric(horizontal: 72, vertical: 24),
                          child: Text(
                            featureTitle,
                            style: TextStyle(
                              color: Colors.black,
                              fontFamily: TestFonts.openSans,
                              fontSize: 72,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: featurePadding.bottom,
                  child: Center(
                    child: Text(
                      featuredGolden.$1.metadata.description,
                      style: TextStyle(
                        color: Colors.black,
                        fontFamily: TestFonts.openSans,
                        fontSize: 48,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            CustomPaint(
              painter: AngledLinePainter(
                angleDegrees: -45,
                gap: 32,
                thickness: 8,
                backgroundColor: Colors.white,
                lineColor: Color(0xFFFAFAFA),
              ),
              child: Container(
                padding: const EdgeInsets.all(175),
                child: Wrap(
                  direction: Axis.vertical,
                  // Center vertically.
                  alignment: WrapAlignment.center,
                  // Center horizontally in each column.
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 48,
                  children: [
                    for (final entry in gridGoldens.entries) //
                      IntrinsicWidth(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Image.memory(
                                key: entry.value,
                                entry.key.pngBytes,
                                width: entry.key.size.width,
                                height: entry.key.size.height,
                              ),
                              Container(
                                padding: const EdgeInsets.all(24),
                                color: Colors.white,
                                child: Text(
                                  entry.key.metadata.description,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontFamily: TestFonts.openSans,
                                    fontSize: 32,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AngledLinePainter extends CustomPainter {
  AngledLinePainter({
    required this.angleDegrees,
    required this.gap,
    required this.thickness,
    required this.lineColor,
    this.backgroundColor = Colors.transparent,
  });

  final double angleDegrees;
  final double gap;
  final double thickness;
  final Color lineColor;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas
      ..save()
      ..clipRect(rect);

    // Fill background.
    canvas.drawRect(rect, Paint()..color = backgroundColor);

    // Draw lines.
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = thickness;

    final angleRadians = angleDegrees * pi / 180;

    // Calculate line direction
    final dx = cos(angleRadians);
    final dy = sin(angleRadians);
    final direction = Offset(dx, dy);
    final perpendicular = Offset(-dy, dx); // unit perpendicular vector

    // Calculate diagonal length to cover the canvas
    final diagonal = sqrt(size.width * size.width + size.height * size.height);

    // Center of canvas
    final center = Offset(size.width / 2, size.height / 2);

    // Number of lines needed to cover the canvas
    final numLines = (diagonal / gap).ceil();

    for (int i = -numLines; i <= numLines; i++) {
      final offset = perpendicular * (i * gap);
      final start = center + offset - direction * diagonal;
      final end = center + offset + direction * diagonal;

      canvas.drawLine(start, end, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

typedef MagazineFeatureBuilder = Widget Function(BuildContext context, Widget featuredGolden);

const defaultFeaturePadding = EdgeInsets.symmetric(vertical: 250, horizontal: 500);
