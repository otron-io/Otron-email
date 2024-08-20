import 'package:flutter/material.dart';
import 'package:home/utils/storage_utils.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class SchedulePodcastWidget extends StatefulWidget {
  final Map<String, dynamic> podcastData;
  final Function(String, Map<String, dynamic>) onSchedule;
  final DateTimeRange? selectedDateRange;
  final String language;

  const SchedulePodcastWidget({
    Key? key,
    required this.podcastData,
    required this.onSchedule,
    this.selectedDateRange,
    required this.language,
  }) : super(key: key);

  @override
  _SchedulePodcastWidgetState createState() => _SchedulePodcastWidgetState();
}

class _SchedulePodcastWidgetState extends State<SchedulePodcastWidget> {
  List<String> _rssFeedFiles = [];
  String? _selectedRssFeed;
  bool _isLoading = false;
  bool _mounted = true;

  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _audioUrlController = TextEditingController();
  final _durationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRssFeeds();
    _populateFields();
  }

  @override
  void dispose() {
    _mounted = false;
    _titleController.dispose();
    _authorController.dispose();
    _subtitleController.dispose();
    _summaryController.dispose();
    _descriptionController.dispose();
    _audioUrlController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _loadRssFeeds() async {
    if (!_mounted) return;
    try {
      final feeds = await StorageUtils.getRssFeedFiles();
      if (!_mounted) return;
      setState(() {
        _rssFeedFiles = feeds;
        _selectedRssFeed = feeds.contains('personal_podcast_feed.xml') 
            ? 'personal_podcast_feed.xml' 
            : (feeds.isNotEmpty ? feeds.first : null);
      });
    } catch (e) {
      print('Error loading RSS feeds: $e');
    }
  }

  void _populateFields() {
    _titleController.text = widget.podcastData['title'] ?? '';
    _authorController.text = widget.podcastData['author'] ?? '';
    _subtitleController.text = widget.podcastData['subtitle'] ?? '';
    _summaryController.text = widget.podcastData['summary'] ?? '';
    _descriptionController.text = widget.podcastData['description'] ?? '';
    _audioUrlController.text = widget.podcastData['audioUrl'] ?? '';
    _durationController.text = widget.podcastData['duration'] ?? '';
  }

  Future<void> _schedulePodcast() async {
    if (!_mounted) return;
    if (_selectedRssFeed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an RSS feed')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final newItem = {
        'title': _titleController.text,
        'author': _authorController.text,
        'subtitle': _subtitleController.text,
        'summary': _summaryController.text,
        'description': _descriptionController.text,
        'audioUrl': _audioUrlController.text,
        'duration': _durationController.text,
        'imageUrl': widget.podcastData['imageUrl'],
        'pubDate': DateFormat('EEE, dd MMM yyyy HH:mm:ss Z').format(DateTime.now()),
      };

      final updateResponse = await http.post(
        Uri.parse('https://update-rss-feed-2ghwz42v7q-uc.a.run.app'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fileName': _selectedRssFeed,
          'newItem': newItem,
        }),
      );

      if (updateResponse.statusCode != 200) {
        throw Exception('Failed to update RSS feed: ${updateResponse.statusCode}');
      }

      if (!_mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('RSS feed updated successfully!')),
      );

      await widget.onSchedule(_selectedRssFeed!, newItem);
    } catch (e) {
      print('Error scheduling podcast: $e');
      if (!_mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to schedule podcast: ${e.toString()}')),
      );
    } finally {
      if (!_mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schedule Podcast',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
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
              decoration: InputDecoration(
                labelText: 'Select RSS Feed',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            _buildTextField(_titleController, 'Episode Title'),
            _buildTextField(_authorController, 'Author'),
            _buildTextField(_subtitleController, 'Subtitle'),
            _buildTextField(_summaryController, 'Summary', maxLines: 3),
            _buildTextField(_descriptionController, 'Description', maxLines: 3),
            _buildTextField(_audioUrlController, 'Audio URL'),
            _buildTextField(_durationController, 'Duration (HH:MM:SS)'),
            if (widget.podcastData['imageUrl'] != null) ...[
              SizedBox(height: 16),
              Text('Generated Image:'),
              SizedBox(height: 8),
              CachedNetworkImage(
                imageUrl: widget.podcastData['imageUrl'],
                placeholder: (context, url) => CircularProgressIndicator(),
                errorWidget: (context, url, error) => InkWell(
                  onTap: () async {
                    final url = widget.podcastData['imageUrl'];
                    if (await canLaunch(url)) {
                      await launch(url);
                    }
                  },
                  child: Text(
                    'Failed to load image. Click here to view.',
                    style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                  ),
                ),
              ),
              SizedBox(height: 8),
              SelectableText(
                widget.podcastData['imageUrl'],
                style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                onTap: () async {
                  final url = widget.podcastData['imageUrl'];
                  if (await canLaunch(url)) {
                    await launch(url);
                  }
                },
              ),
            ],
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _schedulePodcast,
              child: _isLoading ? CircularProgressIndicator() : Text('Schedule and Update RSS'),
            ),
          ],
        ),
      ),
    );
  }
}