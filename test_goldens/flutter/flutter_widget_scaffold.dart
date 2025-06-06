import 'package:flutter/material.dart';
import 'package:flutter_test_goldens/flutter_test_goldens.dart';
import 'package:golden_bricks/golden_bricks.dart';

class FlutterWidgetScaffold extends StatelessWidget {
  const FlutterWidgetScaffold({
    super.key,
    this.goldenKey,
    required this.child,
  });

  final GlobalKey? goldenKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        fontFamily: goldenBricks,
      ),
      home: Scaffold(
        backgroundColor: const Color(0xFF222222),
        body: Center(
          child: GoldenImageBounds(
            key: goldenKey,
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: child,
            ),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
