import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:home/services/auth_services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  final AuthService _authService = AuthService();
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
        _fetchEmails(user);
      }
    } catch (e) {
      print('Sign in error: $e');
    }
  }

  void _fetchEmails(User user) async {
    try {
      final response = await http.post(
        Uri.parse('https://fetch-emails-2ghwz42v7q-uc.a.run.app'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'accessToken': await user.getIdToken()}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _emails = jsonDecode(response.body); // Parse the JSON response
        });
      } else {
        print('Failed to fetch emails: ${response.statusCode}');
      }
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
              onPressed: _signIn,
              child: const Text('Sign in with Google'),
            ),
            if (_emails != null)
              Expanded(
                child: ListView.builder(
                  itemCount: _emails?.length ?? 0,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(_emails![index]['snippet'] ?? 'No snippet'),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}