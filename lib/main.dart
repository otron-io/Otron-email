import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart'; // Add this import
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'firebase_options.dart';
import 'package:home/services/email_service.dart';
import 'package:home/services/vertex_ai_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:home/pages/podcast_creation_page.dart';
import 'package:home/theme/theme.dart';
import 'package:http/http.dart' as http;
import 'package:home/podcasts.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'package:xml/xml.dart';
import 'package:home/pages/customer_page.dart';
import 'package:home/routes.dart'; // New import for routes
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:home/pages/privacy_policy_page.dart'; // Add this import

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

    // Initialize Firebase Auth and Firestore
    FirebaseAuth.instance;
    FirebaseFirestore.instance;

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
    return MaterialApp(
      scrollBehavior: MyCustomScrollBehavior(),
      title: 'Otron Email',
      theme: appTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => CustomerPage(),
        '/admin': (context) => PodcastCreationPage(onAddPodcast: addPodcast),
        '/privacy-policy': (context) => PrivacyPolicyPage(), // Add this line
      },
      navigatorObservers: [MyRouteObserver()],
    );
  }

  void addPodcast(Map<String, dynamic> newPodcast) {
    setState(() {
      _podcasts.insert(0, newPodcast);
    });
  }
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

// Remove or comment out this HomePage class
// class HomePage extends StatelessWidget {
//   final List<Map<String, dynamic>> podcasts;
//   final Function(Map<String, dynamic>) onAddPodcast;
//
//   const HomePage({Key? key, required this.podcasts, required this.onAddPodcast}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return PodcastCreationPage(
//       onAddPodcast: onAddPodcast,
//     );
//   }
// }

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

class MyRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    print('Pushed route: ${route.settings.name}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    print('Replaced route: ${newRoute?.settings.name}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    print('Popped route: ${route.settings.name}');
  }
}
