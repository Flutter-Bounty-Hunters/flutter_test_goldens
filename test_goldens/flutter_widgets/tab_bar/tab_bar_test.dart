import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_goldens/flutter_test_goldens.dart';
import 'package:flutter_test_goldens/src/fonts/golden_toolkit_fonts.dart';

void main() {
  testWidgets("app bar - low fidelity", (tester) async {
    tester.view.physicalSize = Size(1600, 200);

    await tester.pumpWidget(_app());
    await expectLater(find.byType(BottomNavigationBar), matchesGoldenFile("tab_bar_low_fidelity.png"));
  });

  testWidgets("app bar - high fidelity", (tester) async {
    tester.view.physicalSize = Size(1600, 200);

    await loadMaterialIconsFont();
    await loadAppFonts();

    await tester.pumpWidget(_app());
    await expectLater(find.byType(BottomNavigationBar), matchesGoldenFile("tab_bar_high_fidelity.png"));
  });
}

Widget _app() => MaterialApp(
      theme: ThemeData(
        fontFamily: TestFonts.openSans,
      ),
      home: Scaffold(
        body: _pages[0],
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed, // Important for 5+ items
          currentIndex: 0,
          onTap: (index) {},
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline),
              label: 'Add',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              label: 'Alerts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );

final List<Widget> _pages = [
  Center(child: Text('Home')),
  Center(child: Text('Search')),
  Center(child: Text('Add')),
  Center(child: Text('Notifications')),
  Center(child: Text('Profile')),
];
