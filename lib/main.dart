// --IMPORTS--
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
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
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'package:xml/xml.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: "assets/.env");
    print('Loaded .env file successfully');
  } catch (e) {
    print('Error loading .env file: $e');
    // You might want to handle this error more gracefully,
    // depending on how critical the .env variables are for your app
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');

    // Initialize Firebase Analytics
    FirebaseAnalytics analytics = FirebaseAnalytics.instance;

    // Rest of your initialization code...
  } catch (e) {
    print('Error during initialization: $e');
    if (e is FirebaseException) {
      print('Firebase error code: ${e.code}');
      print('Firebase error message: ${e.message}');
    }
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
    return MaterialApp(
      title: 'Otron Email',
      theme: appTheme,
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

class RssGenerator {
  static String generateRssFeed(List<Map<String, String>> items) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0"');
    builder.element('rss', nest: () {
      builder.attribute('version', '2.0');
      builder.element('channel', nest: () {
        builder.element('title', nest: 'My RSS Feed');
        builder.element('description', nest: 'A sample RSS feed');
        builder.element('link', nest: 'https://example.com');
        
        for (var item in items) {
          builder.element('item', nest: () {
            builder.element('title', nest: item['title']);
            builder.element('description', nest: item['description']);
            builder.element('link', nest: item['link']);
            builder.element('pubDate', nest: item['pubDate']);
          });
        }
      });
    });

    return builder.buildDocument().toXmlString(pretty: true);
  }
}

class StorageUtils {
  static Future<String> uploadRssFeed(String rssFeedContent, String fileName) async {
    final bytes = Uint8List.fromList(rssFeedContent.codeUnits);
    final ref = FirebaseStorage.instance.ref().child('rss_feeds/$fileName');
    final uploadTask = ref.putData(bytes, SettableMetadata(contentType: 'application/rss+xml'));
    final snapshot = await uploadTask.whenComplete(() {});
    return await snapshot.ref.getDownloadURL();
  }
}

class RssUploadWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      child: Text('Generate and Upload RSS Feed'),
      onPressed: () async {
        final items = [
          {
            'title': 'First Item',
            'description': 'This is the first item in our RSS feed.',
            'link': 'https://example.com/first-item',
            'pubDate': 'Mon, 06 Sep 2021 12:00:00 GMT',
          },
          {
            'title': 'Second Item',
            'description': 'This is the second item in our RSS feed.',
            'link': 'https://example.com/second-item',
            'pubDate': 'Tue, 07 Sep 2021 12:00:00 GMT',
          },
        ];

        final rssFeedContent = RssGenerator.generateRssFeed(items);
        
        try {
          final downloadURL = await StorageUtils.uploadRssFeed(rssFeedContent, 'feed.xml');
          print('RSS feed uploaded successfully. Download URL: $downloadURL');
        } catch (e) {
          print('Error uploading RSS feed: $e');
        }
      },
    );
  }
}