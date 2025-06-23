import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/flutter_test_goldens.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../shadcn_test_tools.dart';

void main() {
  group("Marketing >", () {
    testGoldenScene("gallery", (tester) async {
      FtgLog.initAllLogs();

      // The following code is broken up so it can spread across multiple slides.
      final gallery = Gallery(
        "Gallery",
        fileName: "gallery",
        itemScaffold: shadcnItemScaffold,
        layout: ShadcnGalleryLayout(
          shadcnWordmarkProvider: shadcnWordmarkProvider,
        ),
      );

      gallery
          .itemFromWidget(
            id: "1",
            description: "Primary",
            widget: ShadButton(
              child: const Text('Primary'),
              onPressed: () {},
            ),
          )
          .itemFromWidget(
            id: "2",
            description: "Secondary",
            widget: ShadButton.secondary(
              child: const Text('Secondary'),
              onPressed: () {},
            ),
          )
          .itemFromWidget(
            id: "3",
            description: "Destructive",
            widget: ShadButton.destructive(
              child: const Text('Destructive'),
              onPressed: () {},
            ),
          )
          .itemFromWidget(
            id: "4",
            description: "Ghost",
            widget: ShadButton.ghost(
              child: const Text('Ghost'),
              onPressed: () {},
            ),
          )
          .itemFromWidget(
            id: "5",
            description: "Link",
            widget: ShadButton.ghost(
              child: const Text('Link'),
              onPressed: () {},
            ),
          )
          .itemFromWidget(
            id: "6",
            description: "Icon + Label",
            widget: ShadButton(
              onPressed: () {},
              leading: const Icon(LucideIcons.mail),
              child: const Text('Login with Email'),
            ),
          )
          .itemFromBuilder(
            id: "7",
            description: "Loading",
            builder: (context) {
              return ShadButton(
                onPressed: () {},
                leading: SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: ShadTheme.of(context).colorScheme.primaryForeground,
                  ),
                ),
                child: const Text('Please wait'),
              );
            },
          )
          .itemFromWidget(
            id: "8",
            description: "Gradient + Shadow",
            widget: ShadButton(
              onPressed: () {},
              gradient: const LinearGradient(colors: [
                Colors.cyan,
                Colors.indigo,
              ]),
              shadows: [
                BoxShadow(
                  color: Colors.blue.withOpacity(.4),
                  spreadRadius: 4,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
              child: const Text('Gradient with Shadow'),
            ),
          );

      await gallery.run(tester);
    });
  });
}
