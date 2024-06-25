import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:home/services/email_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:home/widgets/email_list.dart';

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
  String? _userName;
  List<dynamic>? _emails;

  void _fetchEmails() async {
    try {
      final emails = await _emailService.fetchEmails();
      setState(() {
        _emails = emails;
        _userName = _emailService.userName;
      });
    } catch (e) {
      print('Error fetching emails: $e');
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_userName != null)
              Text('Hi $_userName', style: TextStyle(fontSize: 24)),
            ElevatedButton(
              onPressed: _fetchEmails,
              child: const Text('Fetch Emails'),
            ),
            if (_emails != null)
              EmailList(emails: _emails!),
          ],
        ),
      ),
    );
  }
}