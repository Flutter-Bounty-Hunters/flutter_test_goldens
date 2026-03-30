import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/flutter_test_goldens.dart';

void main() {
  group("Scene types > gallery >", () {
    testGoldenScene(
      "uses custom camera instance",
      (tester) async {
        final camera = _CustomCamera();
        final itemWidget = FlutterLogo();

        await Gallery(
          "Custom Camera",
          directory: Directory("."),
          fileName: "gallery_custom_camera",
          layout: ColumnSceneLayout(),
        )
            .itemFromWidget(
              id: "1",
              description: "first",
              widget: itemWidget,
            )
            .itemFromWidget(
              id: "2",
              description: "second",
              widget: itemWidget,
            )
            .run(tester, camera: camera);

        expect(camera._photoCount, equals(2));
      },
    );
  });
}

class _CustomCamera extends FlutterCamera {
  int _photoCount = 0;

  @override
  Future<void> takePhoto(String id, [Finder? finder]) async {
    _photoCount++;
    await super.takePhoto(id, finder);
  }
}
