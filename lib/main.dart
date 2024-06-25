import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:home/services/auth_services.dart';
import 'package:home/services/email_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:home/widgets/email_list.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  final AuthService _authService = AuthService();
  final EmailService _emailService = EmailService();
  String? _userName;
  List<dynamic>? _emails;

  void _signIn() async {
    try {
      User? user = await _authService.signInWithGoogle();
      if (user != null) {
        setState(() {
          _userName = user.displayName;
        });
        print('Signed in as ${user.displayName}');
        _fetchEmails();
      }
    } catch (e) {
      print('Sign in error: $e');
    }
  }

  void _fetchEmails() async {
    final emails = await _emailService.fetchEmails();
    setState(() {
      _emails = emails;
    });
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
              onPressed: _signIn,
              child: const Text('Sign in with Google'),
            ),
            if (_emails != null)
              EmailList(emails: _emails!),
          ],
        ),
      ),
    );
  }
}