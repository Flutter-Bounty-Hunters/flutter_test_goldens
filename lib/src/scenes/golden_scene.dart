import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/src/goldens/golden_camera.dart';

class GoldenScene extends StatelessWidget {
  const GoldenScene({
    super.key,
    required this.direction,
    required this.renderablePhotos,
    this.background,
  });

  final Axis direction;
  final Map<GoldenPhoto, (Uint8List, GlobalKey)> renderablePhotos;
  final Widget? background;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF666666),
      child: Stack(
        children: [
          if (background != null) //
            Positioned.fill(
              child: ColoredBox(color: Colors.green),
            ),
          if (background != null) //
            Positioned.fill(
              child: background!,
            ),
          Padding(
            padding: const EdgeInsets.all(48),
            child: Flex(
              direction: direction,
              mainAxisSize: MainAxisSize.min,
              spacing: 48,
              children: [
                for (final entry in renderablePhotos.entries) //
                  SizedBox(
                    width: entry.key.pixels.width.toDouble(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ColoredBox(
                          // color: Color(0xFF222222),
                          color: Colors.white,
                          child: Image.memory(
                            key: entry.value.$2,
                            entry.value.$1,
                            width: entry.key.pixels.width.toDouble(),
                            height: entry.key.pixels.height.toDouble(),
                          ),
                        ),
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            entry.key.description,
                            style: TextStyle(
                              color: Colors.black,
                              fontFamily: "packages/flutter_test_goldens/OpenSans",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Scaffolds a golden image, such as building a `MaterialApp` with a `Scaffold`.
///
/// {@template golden_structure}
/// The structure of a golden is as follows:
///
///     Scaffold
///       GoldenImageBounds (the default repaint boundary)
///         Decorator
///           Content
/// {@endtemplate}
typedef GoldenScaffold = Widget Function(WidgetTester tester, Widget content);

/// Decorates a golden screenshot by wrapping the given [content] in a new widget tree.
///
/// {@macro golden_structure}
typedef GoldenDecorator = Widget Function(WidgetTester tester, Widget content);

/// Pumps a widget tree into the given [tester], wrapping its content within the given [decorator].
///
/// {@macro gallery_item_pumper_purpose}
///
/// {@macro golden_structure}
///
/// {@macro gallery_item_pumper_requirements}
typedef GoldenPumper = Future<Object?> Function(
  WidgetTester tester,
  GoldenScaffold scaffold,
  GoldenDecorator? decorator,
);

typedef GoldenSetup = FutureOr<void> Function(WidgetTester tester);
