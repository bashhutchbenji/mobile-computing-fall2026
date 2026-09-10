import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome back', style: TextStyle(fontSize: 16)),
              Text(
                'Sebastian',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(
                height: 140,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _card('Top bread'),
                    _card('Peanut butter'),
                    _card('Jelly'),
                    _card('Nutella chocolate'),
                    _card('Bottom bread'),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    final _name = [
                      'Top bread',
                      'Peanut butter',
                      'Jelly',
                      'Nutella chocolate',
                      'Bottom bread',
                    ];
                    final _description = [
                      'It goes last on the sandwich',
                      'It must be apply to one piece of bread',
                      'best to put on top of Nutella chocolate of Peanut butter',
                      'It must be applied to other piece of bread',
                      'It is the bread that touches the napkin or plate',
                    ];
                    return ListTile(
                      title: Text('${_name[index]}'),
                      subtitle: Text('${_description[index]}'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(String label) => Container(
    width: 120,
    margin: EdgeInsets.all(8),
    color: Colors.deepPurple.shade50,
    child: Center(child: Text(label)),
  );
}