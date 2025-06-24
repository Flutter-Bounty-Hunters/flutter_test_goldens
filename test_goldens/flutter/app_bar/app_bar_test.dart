import 'package:flutter/material.dart';
import 'package:flutter_test_goldens/flutter_test_goldens.dart';
import 'package:flutter_test_goldens/src/fonts/golden_toolkit_fonts.dart';

void main() {
  testGoldenSceneOnAndroid("app bar", (tester) async {
    await loadMaterialIconsFont();
    await loadAppFonts();

    await SingleShot("App Bar", fileName: "app_bar")
        .fromWidget(
      SizedBox(
        width: 500,
        child: IntrinsicHeight(
          child: AppBar(
            leading: Icon(Icons.adaptive.arrow_back),
            title: Text(
              "Hello",
              style: TextStyle(fontFamily: TestFonts.openSans),
            ),
            backgroundColor: Colors.blue,
          ),
        ),
      ),
    )
        .inScaffold(
      (tester, content) {
        return MaterialApp(
          home: Scaffold(
            body: GoldenImageBounds(
              child: content,
            ),
          ),
          debugShowCheckedModeBanner: false,
        );
      },
    ).run(tester);
  });
}
