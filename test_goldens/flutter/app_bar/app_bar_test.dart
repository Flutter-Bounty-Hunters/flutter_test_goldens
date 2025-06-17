import 'package:flutter/material.dart';
import 'package:flutter_test_goldens/flutter_test_goldens.dart';
import 'package:golden_bricks/golden_bricks.dart';

void main() {
  testGoldenSceneOnAndroid("app bar", (tester) async {
    await SingleShot.fromWidget(
      fileName: "app_bar",
      description: "App Bar",
      itemScaffold: (tester, content) {
        return MaterialApp(
          home: Scaffold(
            body: content,
          ),
          debugShowCheckedModeBanner: false,
        );
      },
      itemDecorator: (tester, description, content) {
        return Center(
          child: GoldenImageBounds(
            child: content,
          ),
        );
      },
      widget: SizedBox(
        width: 600,
        child: IntrinsicHeight(
          child: AppBar(
            leading: Icon(Icons.adaptive.arrow_back),
            title: Text(
              "Hello",
              style: TextStyle(fontFamily: goldenBricks),
            ),
            backgroundColor: Colors.blue,
          ),
        ),
      ),
    ).renderOrCompareGolden(tester);
  });
}
