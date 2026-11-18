import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
    providerAndroid: AndroidDebugProvider(),
    providerApple: AppleDebugProvider(),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ExplainScreen(),
  );
}

class ExplainScreen extends StatefulWidget {
  const ExplainScreen({super.key});
  @override
  State<ExplainScreen> createState() => _ExplainScreenState();
}

class _ExplainScreenState extends State<ExplainScreen> {
  final _controller = TextEditingController();
  final _model = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-3.5-flash-lite',
    systemInstruction: Content.system(
      'You explain Dart and Flutter code to beginners,  '
      'line by line, in simple words. Keep it short. '
      'If the question is not about code, say only '
      'explain code',
    ),
  );
  String _answer = '';
  String _error = '';
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _explain() async {
    final code = _controller.text.trim();
    if (_loading) return;
    if (code.isEmpty) {
      setState(() {
        _answer = '';
        _error = 'Please paste some code first.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _answer = '';
      _error = '';
    });
    try {
      final response = await _model.generateContent([
        Content.text('Explain this code;\n$code'),
      ]);
      setState(() => _answer = response.text ?? 'No answer.');
    } catch (e) {
      debugPrint('AI request failed: $e');
      setState(() => _error = 'Could not get explanation. Try again.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Code Explainer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              maxLines: 5,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Paste Dart or Flutter code',
                border: OutlineInputBorder(),
              ),
            ),
            ElevatedButton(
              onPressed: _loading ? null : _explain,
              child: const Text('Explain'),
            ),
            const SizedBox(height: 16),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (_error.isNotEmpty)
              Text(_error, style: const TextStyle(color: Colors.red)),
            if (_answer.isNotEmpty) ...[
              const Text(
                'AI-generated, may contain mistakes.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(_answer),
            ],
          ],
        ),
      ),
    );
  }
}
