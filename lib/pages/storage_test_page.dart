import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import '../utils/storage_utils.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class StorageTestPage extends StatefulWidget {
  const StorageTestPage({Key? key}) : super(key: key);

  @override
  _StorageTestPageState createState() => _StorageTestPageState();
}

class _StorageTestPageState extends State<StorageTestPage> {
  String _connectionStatus = 'Not tested';
  List<String> _rssFeedFiles = [];
  String? _selectedRssFeed;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _testConnection();
    _listRssFeeds();
  }

  Future<void> _testConnection() async {
    setState(() {
      _connectionStatus = 'Testing...';
    });

    try {
      await Firebase.initializeApp();
      await FirebaseStorage.instance.ref().listAll();
      setState(() {
        _connectionStatus = 'Connection successful!';
      });
    } catch (e) {
      setState(() {
        _connectionStatus = 'Connection failed: ${e.toString()}';
      });
    }
  }

  Future<void> _listRssFeeds() async {
    try {
      final files = await StorageUtils.getRssFeedFiles();
      setState(() {
        _rssFeedFiles = files;
      });
    } catch (e) {
      print('Error listing RSS feeds: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Storage Test'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Connection Status: $_connectionStatus'),
              SizedBox(height: 20),
              Text('Select RSS Feed:'),
              DropdownButton<String>(
                value: _selectedRssFeed,
                items: _rssFeedFiles.map((String file) {
                  return DropdownMenuItem<String>(
                    value: file,
                    child: Text(file),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedRssFeed = newValue;
                  });
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateRssFeed,
                child: _isLoading ? CircularProgressIndicator() : Text('Update RSS Feed'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _downloadRssFeed,
                child: _isLoading ? CircularProgressIndicator() : Text('Download RSS Feed'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateRssFeed() async {
    if (_selectedRssFeed == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final rssFeedUrl = await StorageUtils.getRssFeedUrl(_selectedRssFeed!);
      if (rssFeedUrl == null) throw Exception('RSS feed URL not found');

      final proxyUrl = 'https://proxy-rss-feed-2ghwz42v7q-uc.a.run.app?url=${Uri.encodeComponent(rssFeedUrl)}';

      print('Fetching RSS feed from: $proxyUrl');

      final response = await http.get(Uri.parse(proxyUrl));
      
      print('Response status code: ${response.statusCode}');
      print('Response body length: ${response.body.length}');

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch RSS feed. Status code: ${response.statusCode}');
      }

      final document = xml.XmlDocument.parse(response.body);
      final channel = document.findAllElements('channel').first;

      // Create a new item element
      final newItem = xml.XmlElement(xml.XmlName('item'), [], [
        xml.XmlElement(xml.XmlName('title'), [], [xml.XmlText('New Sample Episode ${DateTime.now().toIso8601String()}')]),
        xml.XmlElement(xml.XmlName('itunes:author'), [], [xml.XmlText('Your Name')]),
        xml.XmlElement(xml.XmlName('itunes:subtitle'), [], [xml.XmlText('This is a new sample episode')]),
        xml.XmlElement(xml.XmlName('itunes:summary'), [], [xml.XmlText('This is a summary of the new sample episode.')]),
        xml.XmlElement(xml.XmlName('enclosure'), [
          xml.XmlAttribute(xml.XmlName('url'), 'https://example.com/new-sample-episode.mp3'),
          xml.XmlAttribute(xml.XmlName('length'), '10000000'),
          xml.XmlAttribute(xml.XmlName('type'), 'audio/mpeg'),
        ], []),
        xml.XmlElement(xml.XmlName('guid'), [], [xml.XmlText('https://example.com/new-sample-episode-${DateTime.now().millisecondsSinceEpoch}.mp3')]),
        xml.XmlElement(xml.XmlName('pubDate'), [], [xml.XmlText(DateFormat('EEE, dd MMM yyyy HH:mm:ss Z').format(DateTime.now()))]),
        xml.XmlElement(xml.XmlName('itunes:duration'), [], [xml.XmlText('00:30:00')]),
      ]);

      // Add the new item to the channel
      channel.children.add(newItem);

      final updatedXml = document.toXmlString(pretty: true);
      print('Updated XML length: ${updatedXml.length}');
      print('Updated XML content: $updatedXml');

      // Upload the updated XML back to Firebase Storage
      print('Uploading updated XML to Firebase Storage...');
      final uploadResult = await StorageUtils.uploadFile(Uint8List.fromList(updatedXml.codeUnits), 'rss_feeds/${_selectedRssFeed!}');
      print('Upload result: $uploadResult');

      print('RSS feed updated successfully');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('RSS feed updated successfully!')),
      );
    } catch (e) {
      print('Error updating RSS feed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update RSS feed: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadRssFeed() async {
    if (_selectedRssFeed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an RSS feed first')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Request storage permission
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception('Storage permission not granted');
      }

      // Get the RSS feed URL
      final rssFeedUrl = await StorageUtils.getRssFeedUrl(_selectedRssFeed!);
      if (rssFeedUrl == null) throw Exception('RSS feed URL not found');

      // Fetch the RSS feed content
      final proxyUrl = 'https://proxy-rss-feed-2ghwz42v7q-uc.a.run.app?url=${Uri.encodeComponent(rssFeedUrl)}';
      final response = await http.get(Uri.parse(proxyUrl));

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch RSS feed. Status code: ${response.statusCode}');
      }

      // Get the downloads directory
      final directory = await getExternalStorageDirectory();
      if (directory == null) throw Exception('Unable to access external storage');

      // Create the file
      final file = File('${directory.path}/${_selectedRssFeed}');
      await file.writeAsBytes(response.bodyBytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('RSS feed downloaded successfully to ${file.path}')),
      );
    } catch (e) {
      print('Error downloading RSS feed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download RSS feed: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}