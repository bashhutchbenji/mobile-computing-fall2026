import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AddItemScreen(),
    );
  }
}

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});
  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _detailController = TextEditingController();
  String _message = '';
  bool snackbarTitleEmpty = false;
  bool snackbarDetailEmpty = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Item')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    snackbarTitleEmpty = true;
                    return '';
                  }
                  snackbarTitleEmpty = false;
                  return null;
                },
              ),
              TextFormField(
                controller: _detailController,
                decoration: const InputDecoration(labelText: 'Detail'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    snackbarDetailEmpty = true;
                    return '';
                  }
                  snackbarDetailEmpty = false;
                  return null;
                },
              ),
              ElevatedButton(
                onPressed: () {
                  final isValid = _formKey.currentState!.validate();
                  if (!isValid && snackbarTitleEmpty && !snackbarDetailEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Title cannot be empty')),
                    );
                    return;
                  } else if (!isValid &&
                      snackbarDetailEmpty &&
                      !snackbarTitleEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Detail cannot be empty')),
                    );
                  } else if (!isValid &&
                      snackbarTitleEmpty &&
                      snackbarDetailEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Title and Detail cannot be empty'),
                      ),
                    );
                  }
                  setState(() {
                    _message =
                        '${_titleController.text}: ${_detailController.text}';
                    //print(_message);
                  });
                },
                child: const Text('Add'),
              ),
              //Text(_message),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.greenAccent,
                  border: Border.all(
                    color:  Colors.teal,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text( _message, style: TextStyle(fontWeight: FontWeight.bold))
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailController.dispose();
    super.dispose();
  }
}