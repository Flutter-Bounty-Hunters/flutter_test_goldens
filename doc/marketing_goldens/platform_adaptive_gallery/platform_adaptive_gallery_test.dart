import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/flutter_test_goldens.dart';
import 'package:flutter_test_goldens/golden_bricks.dart';
import 'package:super_editor/super_editor.dart';
import 'package:super_editor/super_editor_test.dart';

void main() {
  group("Marketing > gallery > platform adaptive >", () {
    testGoldenScene("text editor", (tester) async {
      FtgLog.initLoggers({FtgLog.pipeline});

      await Gallery(
        "Platform Adaptive Gallery",
        fileName: "platform_adaptive_gallery",
        layout: GridGoldenSceneLayout(
          itemDecorator: _itemDecorator,
        ),
      )
          .itemFromPumper(
            id: "selected-text",
            description: "Selected Text",
            forEachPlatform: true,
            pumper: _pumpEditor,
          )
          .run(tester);
    });
  });
}

Future<void> _pumpEditor(
  WidgetTester tester,
  GoldenSceneItemScaffold scaffold,
  String description,
) async {
  final editor = _createEditor();

  await tester.pumpWidget(
    scaffold(
      tester,
      DefaultTextStyle(
        style: TextStyle(fontFamily: goldenBricks),
        child: SizedBox(
          width: 600,
          child: SuperEditor(
            editor: editor,
            stylesheet: defaultStylesheet.copyWith(inlineTextStyler: (attributions, style) {
              style = defaultInlineTextStyler(attributions, style);
              return style.copyWith(fontFamily: goldenBricks);
            }),
            shrinkWrap: true,
          ),
        ),
      ),
    ),
  );

  await tester.doubleTapInParagraph("1", 25);
}

Editor _createEditor() {
  return createDefaultDocumentEditor(
    document: _createDocument(),
    composer: MutableDocumentComposer(),
  );
}

MutableDocument _createDocument() {
  return MutableDocument(
    nodes: [
      ParagraphNode(
        id: "0",
        text: AttributedText("Multi Platform!"),
        metadata: {
          NodeMetadata.blockType: header1Attribution,
        },
      ),
      ParagraphNode(
        id: "1",
        text: AttributedText("Hello, world! This is a document editor built with Flutter."),
      ),
      ParagraphNode(
        id: "2",
        text: AttributedText("You can place the caret, type text, delete text, select text, etc."),
      ),
    ],
  );
}

Widget _itemDecorator(
  BuildContext context,
  GoldenScreenshotMetadata metadata,
  Widget content,
) {
  return Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        content,
        Divider(),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            SvgPicture.file(
              _getIconFileForPlatform(metadata.simulatedPlatform),
              // ignore: deprecated_member_use
              color: Colors.black,
              width: 24,
              height: 24,
            ),
            Text(metadata.description),
          ],
        ),
      ],
    ),
  );
}

File _getIconFileForPlatform(TargetPlatform platform) => switch (platform) {
      TargetPlatform.android => File("doc/marketing_goldens/platform_adaptive_gallery/icons/android-brands.svg"),
      TargetPlatform.iOS => File("doc/marketing_goldens/platform_adaptive_gallery/icons/apple-brands.svg"),
      TargetPlatform.macOS => File("doc/marketing_goldens/platform_adaptive_gallery/icons/laptop-solid.svg"),
      TargetPlatform.windows => File("doc/marketing_goldens/platform_adaptive_gallery/icons/windows-brands.svg"),
      TargetPlatform.linux => File("doc/marketing_goldens/platform_adaptive_gallery/icons/ubuntu-brands.svg"),
      TargetPlatform.fuchsia => throw UnimplementedError(),
    };
