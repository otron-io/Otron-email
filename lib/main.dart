import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:home/services/email_service.dart';
import 'package:home/services/vertex_ai_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:home/widgets/email_list.dart';
import 'package:home/widgets/generated_text_display.dart';
import 'package:home/widgets/audio_player_widget.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:home/prompt.dart';

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
        primaryColor: Color(0xFF3A86FF),
        scaffoldBackgroundColor: Colors.white,
        textTheme: TextTheme(
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
          bodyMedium: TextStyle(fontSize: 16, color: Color(0xFF333333)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF3A86FF),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
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
  List<Map<String, String>>? _emails;
  final List<String> _streamedContent = [];
  bool _isLoading = false;

  void _fetchEmails() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final emails = await _emailService.fetchEmails();
      setState(() {
        _emails = emails;
        _userName = _emailService.userName;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching emails: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _generatePodcast() async {
    if (_emails == null || _emails!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fetch emails first')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _streamedContent.clear();
    });

    final prompt = emailSummaryPrompt.replaceFirst(
      '{Placeholder for raw email data}',
      jsonEncode(_emails),
    );

    try {
      await for (final chunk in _vertexAIService.generateContentStream(prompt)) {
        setState(() {
          _streamedContent.add(chunk);
        });
      }
    } catch (e) {
      print('Error generating podcast: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 800),
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Otron Email',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  if (_emails == null) 
                    ElevatedButton(
                      onPressed: _isLoading ? null : _fetchEmails,
                      child: _isLoading 
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          )
                        : Text('Fetch Emails'),
                    ),
                  if (_emails != null) ...[
                    EmailList(emails: _emails!),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _generatePodcast,
                      child: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          )
                        : Text('Generate Podcast'),
                    ),
                  ],
                  SizedBox(height: 24),
                  if (_streamedContent.isNotEmpty) ...[
                    AudioPlayerWidget(audioPath: 'audio/Joseph.mp3'),
                    SizedBox(height: 24),
                    GeneratedTextDisplay(streamedContent: _streamedContent),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }}