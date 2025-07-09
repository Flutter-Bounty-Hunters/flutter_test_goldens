import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/src/flutter/flutter_pixel_alignment.dart';

void main() {
  testWidgets("failing test", (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          // body: _buildVersion1(),
          body: _buildVersion2(),
        ),
      ),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile("failure_example.png"),
    );
  });
}

// ignore: unused_element
Widget _buildVersion1() {
  return Center(
    child: PixelSnapColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.greenAccent, width: 4),
            ),
          ),
        ),
        Text(
          "Hello, world!",
          textAlign: TextAlign.center,
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey, width: 4),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildVersion2() {
  return Center(
    child: PixelSnapColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red, width: 4),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
        Text(
          "Some other text",
          textAlign: TextAlign.center,
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey, width: 4),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      ],
    ),
  );
}
