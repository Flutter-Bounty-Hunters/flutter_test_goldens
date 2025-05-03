import 'package:flutter/material.dart';
import 'package:golden_bricks/golden_bricks.dart';

class FlutterWidgetScaffold extends StatelessWidget {
  const FlutterWidgetScaffold({
    super.key,
    required this.goldenKey,
    required this.child,
  });

  final GlobalKey goldenKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        fontFamily: goldenBricks,
      ),
      home: Scaffold(
        backgroundColor: const Color(0xFF222222),
        body: Padding(
          key: goldenKey,
          padding: const EdgeInsets.all(48),
          child: child,
        ),
      ),
    );
  }
}
