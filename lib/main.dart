import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:home/services/email_service.dart';
import 'package:home/services/vertex_ai_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:home/widgets/email_list.dart';
import 'package:home/widgets/generated_text_display.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Otron Email',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Otron Email'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final EmailService _emailService = EmailService();
  final VertexAIService _vertexAIService = VertexAIService();
  String? _userName;
  List<String>? _snippets;
  final List<String> _streamedContent = [];

  void _fetchEmails() async {
    try {
      final snippets = await _emailService.fetchEmails();
      setState(() {
        _snippets = snippets;
        _userName = _emailService.userName;
      });
    } catch (e) {
      print('Error fetching emails: $e');
    }
  }

  void _classify() async {
    setState(() {
      _streamedContent.clear();
    });

    if (_snippets == null || _snippets!.isEmpty) {
      print('No snippets available for classification');
      return;
    }

    final prompt = 'Classify the following email snippets. Try to determine if they could be called a Newsletter (something I would actively subscribe to to read).Simply return - Newsletter or Other:\n' + _snippets!.join('\n');

    try {
      await for (final chunk in _vertexAIService.generateContentStream(prompt)) {
        setState(() {
          _streamedContent.add(chunk);
        });
      }
    } catch (e) {
      print('Error classifying: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (_userName != null)
                Text('Hi $_userName', style: TextStyle(fontSize: 24)),
              ElevatedButton(
                onPressed: _fetchEmails,
                child: const Text('Fetch Emails'),
              ),
              if (_snippets != null)
                EmailList(emails: _snippets!),
              ElevatedButton(
                onPressed: _classify,
                child: const Text('Classify'),
              ),
              if (_streamedContent.isNotEmpty)
                GeneratedTextDisplay(streamedContent: _streamedContent),
            ],
          ),
        ),
      ),
    );
  }
}