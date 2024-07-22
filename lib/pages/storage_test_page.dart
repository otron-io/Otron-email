//--IMPORTS--
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import '../utils/storage_utils.dart';

//--CLASS--
class StorageTestPage extends StatefulWidget {
  const StorageTestPage({Key? key}) : super(key: key);

  @override
  _StorageTestPageState createState() => _StorageTestPageState();
}

class _StorageTestPageState extends State<StorageTestPage> {
  String _connectionStatus = 'Not tested';
  List<String> _fileNames = [];
  List<String> _rssFeedFiles = [];
  String? _selectedFeedUrl;

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

  Future<void> _listFiles() async {
    setState(() {
      _fileNames = ['Loading...'];
    });

    try {
      final files = await StorageUtils.getAllFileNames();
      setState(() {
        _fileNames = files;
      });
    } catch (e) {
      setState(() {
        _fileNames = ['Error: ${e.toString()}'];
      });
    }
  }

  Future<void> _listRssFeeds() async {
    setState(() {
      _rssFeedFiles = ['Loading...'];
    });

    try {
      final files = await StorageUtils.getRssFeedFiles();
      setState(() {
        _rssFeedFiles = files;
      });
    } catch (e) {
      setState(() {
        _rssFeedFiles = ['Error: ${e.toString()}'];
      });
    }
  }

  Future<void> _getFeedUrl(String fileName) async {
    final url = await StorageUtils.getRssFeedUrl(fileName);
    setState(() {
      _selectedFeedUrl = url;
    });
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
              ElevatedButton(
                onPressed: _testConnection,
                child: Text('Test Firebase Storage Connection'),
              ),
              SizedBox(height: 20),
              Text('Connection Status: $_connectionStatus'),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _listFiles,
                child: Text('List All Files'),
              ),
              SizedBox(height: 20),
              Text('All Files:'),
              ..._fileNames.map((file) => ListTile(title: Text(file))),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _listRssFeeds,
                child: Text('List RSS Feeds'),
              ),
              SizedBox(height: 20),
              Text('RSS Feeds:'),
              ..._rssFeedFiles.map((file) => ListTile(
                    title: Text(file),
                    onTap: () => _getFeedUrl(file),
                  )),
              if (_selectedFeedUrl != null) ...[
                SizedBox(height: 20),
                Text('Selected Feed URL:'),
                SelectableText(_selectedFeedUrl!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}