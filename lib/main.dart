// --IMPORTS--
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:home/services/email_service.dart';
import 'package:home/services/vertex_ai_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:home/pages/welcome_page.dart';
import 'package:home/pages/podcast_list_page.dart';
import 'package:home/pages/podcast_creation_page.dart';
import 'package:home/theme/theme.dart';
import 'package:http/http.dart' as http;
import 'package:home/podcasts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    final response = await callHelloWorldFunction();
    print('Hello World Function Response: $response');
  } catch (e) {
    print('Error: $e');
  }

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<Map<String, dynamic>> _podcasts = [];

  @override
  void initState() {
    super.initState();
    _podcasts = List.from(podcasts);
  }

  @override
  Widget build(BuildContext context) {
    return _buildApp();
  }

  Widget _buildApp() {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.android) {
      return _buildMaterialApp();
    } else {
      return _buildCupertinoApp();
    }
  }

Widget _buildMaterialApp() {
  return MaterialApp(
    title: 'Otron Email',
    theme: appTheme,
    home: HomePage(podcasts: _podcasts, onAddPodcast: addPodcast),
  );
}

  Widget _buildCupertinoApp() {
    return CupertinoApp(
      title: 'Otron Email',
      theme: CupertinoThemeData(
        primaryColor: appTheme.colorScheme.primary,
        brightness: appTheme.brightness,
      ),
      home: HomePage(podcasts: _podcasts, onAddPodcast: addPodcast),
    );
  }

  void addPodcast(Map<String, dynamic> newPodcast) {
    setState(() {
      _podcasts.insert(0, newPodcast);
    });
  }
}

Future<String> callHelloWorldFunction() async {
  final url = 'https://hello-world-2ghwz42v7q-uc.a.run.app';
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    return response.body;
  } else {
    throw Exception('Failed to call Hello World function');
  }
}

class HomePage extends StatefulWidget {
  final List<Map<String, dynamic>> podcasts;
  final Function(Map<String, dynamic>) onAddPodcast;

  const HomePage({Key? key, required this.podcasts, required this.onAddPodcast}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToPodcastList() {
    setState(() {
      _selectedIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          WelcomePage(onGetStarted: _navigateToPodcastList),
          PodcastListPage(
            onAddPodcast: widget.onAddPodcast,
            podcasts: widget.podcasts,
          ),
          PodcastCreationPage(
            onAddPodcast: (newPodcast) {
              widget.onAddPodcast(newPodcast);
              setState(() {
                _selectedIndex = 1;
              });
            },
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: _onItemTapped,
        selectedIndex: _selectedIndex,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home, color: appTheme.colorScheme.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.list, color: appTheme.colorScheme.primary),
            label: 'Podcasts',
          ),
        ],
      ),
    );
  }
}