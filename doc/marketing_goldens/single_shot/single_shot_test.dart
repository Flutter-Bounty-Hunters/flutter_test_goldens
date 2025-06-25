import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/flutter_test_goldens.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../shadcn_test_tools.dart';

Future<void> main() async {
  group("Marketing >", () {
    testGoldenScene("single shot", (tester) async {
      await tester.runAsync(() async {
        await precacheImage(shadcnWordmarkProvider, tester.binding.rootElement!);
      });

      await SingleShot("Standalone", fileName: "single_shot_standalone") //
          .fromWidget(ShadCalendar())
          .inScaffold(shadcnItemScaffold)
          .withLayout(ShadcnSingleShotSceneLayout(
            shadcnWordmarkProvider: shadcnWordmarkProvider,
          ))
          .run(tester);

      await SingleShot("Header", fileName: "single_shot_website_header") //
          .fromWidget(ShadCalendar())
          .inScaffold(shadcnItemScaffold)
          .withLayout(ShadcnSingleShotSceneLayout(
            shadcnWordmarkProvider: shadcnWordmarkProvider,
            aspectRatio: 3 / 1,
          ))
          .run(tester);
    });
  });
}
