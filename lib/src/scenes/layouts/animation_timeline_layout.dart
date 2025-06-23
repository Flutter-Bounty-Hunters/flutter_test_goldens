import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/src/fonts/fonts.dart';
import 'package:flutter_test_goldens/src/goldens/golden_collections.dart';
import 'package:flutter_test_goldens/src/goldens/golden_rendering.dart';
import 'package:flutter_test_goldens/src/scenes/golden_scene.dart';
import 'package:flutter_test_goldens/src/scenes/scene_layout.dart';

class AnimationTimelineSceneLayout implements SceneLayout {
  const AnimationTimelineSceneLayout({
    this.background = const GoldenSceneBackground.color(Color(0xff020817)),
    this.spacing = defaultGridSpacing,
    this.itemDecorator,
  });

  final GoldenSceneBackground? background;

  final GridSpacing spacing;

  /// A decoration built around each screenshot in the final scene.
  ///
  /// This decorator has no impact when building new screenshot widget trees, it
  /// only impacts the final painted scene, after the screenshots have been taken.
  final GoldenSceneItemDecorator? itemDecorator;

  @override
  Widget build(
    WidgetTester tester,
    BuildContext context,
    Map<GoldenSceneScreenshot, GlobalKey<State<StatefulWidget>>> goldens,
  ) {
    return AnimationTimelineGoldenScene(
      background: background,
      spacing: spacing,
      itemDecorator: itemDecorator,
      goldens: goldens,
    );
  }
}

class AnimationTimelineGoldenScene extends StatelessWidget {
  const AnimationTimelineGoldenScene({
    super.key,
    this.background,
    this.spacing = defaultGridSpacing,
    this.itemDecorator,
    required this.goldens,
  });

  final GridSpacing spacing;

  final GoldenSceneBackground? background;

  /// A decoration built around each screenshot in the final scene.
  ///
  /// This decorator has no impact when building new screenshot widget trees, it
  /// only impacts the final painted scene, after the screenshots have been taken.
  final GoldenSceneItemDecorator? itemDecorator;

  final Map<GoldenSceneScreenshot, GlobalKey> goldens;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: GoldenSceneTheme.current.defaultTextStyle.copyWith(
        color: _accentColor,
      ),
      child: GoldenSceneBounds(
        child: IntrinsicWidth(
          child: IntrinsicHeight(
            child: Stack(
              children: [
                Positioned.fill(
                  child: _buildBackground(context),
                ),
                _buildGoldens(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoldens() {
    return Padding(
      padding: spacing.around,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "ANIMATION TIMELINE",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: spacing.between,
            children: [
              for (final entry in goldens.entries) //
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IntrinsicWidth(
                      // ^ Intrinsic width is needed in case the following decorator has a `Column`, to not blow up
                      //   when the `Flex` above is a row.
                      child: Builder(builder: (context) {
                        return _decorator(
                          context,
                          entry.key.metadata,
                          Image.memory(
                            key: entry.value,
                            entry.key.pngBytes,
                            width: entry.key.size.width.toDouble(),
                            height: entry.key.size.height.toDouble(),
                          ),
                        );
                      }),
                    ),
                    Center(
                      child: Container(
                        width: 2,
                        height: 20,
                        color: _accentColor,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Divider(height: 2, thickness: 2, color: _accentColor),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                "Start >",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Spacer(),
              Text(
                "> End",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _decorator(BuildContext context, GoldenScreenshotMetadata metadata, Widget child) {
    // TODO: bring back configurable item decorator
    final itemDecorator = _itemDecorator; // this.itemDecorator ?? GoldenSceneTheme.current.itemDecorator;
    return itemDecorator(context, metadata, child);
  }

  Widget _buildBackground(BuildContext context) {
    return (background ?? GoldenSceneTheme.current.background).build(context);
  }
}

const _accentColor = Color(0xff1e293b);

Widget _itemDecorator(
  BuildContext context,
  GoldenScreenshotMetadata metadata,
  Widget content,
) {
  return ColoredBox(
    color: const Color(0xff020817),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        content,
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            metadata.description,
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: TestFonts.openSans, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}
