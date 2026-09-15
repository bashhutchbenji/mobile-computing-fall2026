import 'package:flutter/material.dart';

void main() {
  runApp(const WrestlingApp());
}

class WrestlingApp extends StatelessWidget {
  const WrestlingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wrestling App',
      debugShowCheckedModeBanner: false,
      // One shared theme for the whole app -- change the color here
      // and every AppBar, button, etc. updates everywhere automatically.
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFB71C1C), // deep red
        fontFamily: 'Roboto',
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Responsive basics: grab the screen width so we can size things
    // as a fraction of the screen instead of hardcoding a fixed number.
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wrestling App'),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Header section ----
          Container(
            padding: const EdgeInsets.all(20),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome back', style: TextStyle(fontSize: 16)),
                Text(
                  'Wrestling App',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // ---- Horizontally scrolling news section ----
          SizedBox(
            height: 140,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _newsCard('News 1', screenWidth),
                _newsCard('News 2', screenWidth),
                _newsCard('News 3', screenWidth),
                _newsCard('News 4', screenWidth),
                _newsCard('News 5', screenWidth),
              ],
            ),
          ),

          // ---- Vertical list section: the app's main pages ----
          // Expanded makes this section fill whatever space is left
          // after the header and the news row above it.
          Expanded(
            child: ListView(
              children: [
                _navTile(Icons.timer, 'Score Board / Clock'),
                _navTile(Icons.groups, 'Team Roster'),
                _navTile(Icons.play_circle_fill, 'Videos'),
                _navTile(Icons.bar_chart, 'Stats'),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }
}

// A single square news box. Its width is a fraction of the screen
// width (responsive) instead of one fixed pixel number for every phone.
Widget _newsCard(String label, double screenWidth) {
  return Container(
    width: screenWidth * 0.3,
    margin: const EdgeInsets.symmetric(horizontal: 8),
    color: Colors.grey.shade300,
    padding: const EdgeInsets.all(8),
    alignment: Alignment.bottomLeft,
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
  );
}

// One row in the vertical list of pages. Does nothing yet -- just a
// placeholder tap, same as the news cards and bottom bar icons.
Widget _navTile(IconData icon, String label) {
  return ListTile(
    leading: Icon(icon),
    title: Text(label),
    onTap: () {
      // will navigate to this page later
    },
  );
}

// One icon + label pair for the bottom bar.
Widget _bottomIcon(IconData icon, String label, Color color) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(icon, color: color),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 12, color: color)),
    ],
  );
}

// The bottom ribbon: a plain Row of icons inside a black Container.
// (Row arranges its children left-to-right, same as Concept 1 in the slides.)
Widget _buildBottomBar() {
  return Container(
    height: 70,
    color: Colors.black,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _bottomIcon(Icons.quiz, 'Trivia', Colors.green),
        _bottomIcon(Icons.event, 'Events', Colors.green),
        _bottomIcon(Icons.local_fire_department, 'Streak', Colors.white),
        _bottomIcon(Icons.forum, 'Forum', Colors.red),
        _bottomIcon(Icons.settings, 'Account', Colors.red),
      ],
    ),
  );
}