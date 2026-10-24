import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ItemListModel extends ChangeNotifier {
  final List<String> _items = [];
  int get itemCount => _items.length;
  String itemAt(int index) => _items[index];

  void addItem(String item) {
    _items.add(item);
    notifyListeners();
  }

  void removeItem(int index) {
    _items.removeAt(index);
    notifyListeners();
  }
}

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ItemListModel(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: Center(child: HomeScreen())),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ItemListModel>();
    final count = model.itemCount;

    return Scaffold(
      appBar: AppBar(title: Text('My Items ($count)')),
      body: count == 0
          ? const Center(child: Text('No items yet.'))
          : ListView.builder(
              itemCount: count,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(model.itemAt(index)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      context.read<ItemListModel>().removeItem(index);
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddScreen extends StatefulWidget {
  const AddScreen({super.key});
  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  final _controller = TextEditingController();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Item')),
      body: Column(
        children: [
          TextField(controller: _controller),
          ElevatedButton(
            onPressed: () {
              context.read<ItemListModel>().addItem(_controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
