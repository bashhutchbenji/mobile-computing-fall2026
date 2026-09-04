import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('My Profile')),
        body: Center(
          child: Container(
            color: Colors.deepPurple.shade50,
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(radius: 50 /* backgroundImage */),
                SizedBox(height: 12),
                Text(
                  'Sebastian',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text('I like video games'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _statBox('128', 'Followers'),
                    _statBox('12', 'Projects'),
                    _statBox('340', 'Likes'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statBox(String number, String label) {
    return Column(children: [Text(number), Text(label)]);
  }
}
