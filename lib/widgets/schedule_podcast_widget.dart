import 'package:flutter/material.dart';
import 'package:home/utils/storage_utils.dart';
import 'package:intl/intl.dart';
import 'package:xml/xml.dart' as xml;
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:home/services/vertex_ai_service.dart';

// Add these constants at the top of the file
const String PROXY_RSS_FEED_URL = 'https://proxy-rss-feed-2ghwz42v7q-uc.a.run.app';
const String PROXY_UPLOAD_URL = 'https://proxy-upload-2ghwz42v7q-uc.a.run.app';

class SchedulePodcastWidget extends StatefulWidget {
  final Map<String, dynamic> podcastData;
  final Function(String, Map<String, dynamic>) onSchedule;
  final DateTimeRange? selectedDateRange;
  final String language; // Add this line

  const SchedulePodcastWidget({
    Key? key,
    required this.podcastData,
    required this.onSchedule,
    this.selectedDateRange,
    required this.language, // Add this line
  }) : super(key: key);

  @override
  _SchedulePodcastWidgetState createState() => _SchedulePodcastWidgetState();
}

class _SchedulePodcastWidgetState extends State<SchedulePodcastWidget> {
  List<String> _rssFeedFiles = [];
  String? _selectedRssFeed;
  bool _isLoading = false;

  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _audioUrlController = TextEditingController();
  final _durationController = TextEditingController();

  String? _imageUrl;
  bool _isUploadingImage = false;
  bool _isGeneratingImage = false;

  late final VertexAIService _vertexAIService;

  @override
  void initState() {
    super.initState();
    _vertexAIService = VertexAIService(language: widget.language);
    _loadRssFeeds();
    _populateFields();

    // Update the subtitle with the selected date range
    if (widget.selectedDateRange != null) {
      final startDate = DateFormat('MMM d').format(widget.selectedDateRange!.start);
      final endDate = DateFormat('MMM d, yyyy').format(widget.selectedDateRange!.end);
      _subtitleController.text = 'Email Digest $startDate - $endDate';
    } else {
      _subtitleController.text = 'Daily Email Digest - ${DateFormat('MMMM d, yyyy').format(DateTime.now())}';
    }
  }

  Future<void> _loadRssFeeds() async {
    try {
      final feeds = await StorageUtils.getRssFeedFiles();
      setState(() {
        _rssFeedFiles = feeds;
        _selectedRssFeed = feeds.contains('personal_podcast_feed.xml') 
            ? 'personal_podcast_feed.xml' 
            : (feeds.isNotEmpty ? feeds.first : null);
      });
    } catch (e, stackTrace) {
      print('Error loading RSS feeds: $e');
      print('Stack trace: $stackTrace');
      // You might want to show an error message to the user here
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

  Future<void> _uploadImage() async {
    setState(() {
      _isUploadingImage = true;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null) {
        Uint8List fileBytes = result.files.first.bytes!;
        String fileName = result.files.first.name;

        // Upload to Firebase Storage
        Reference ref = FirebaseStorage.instance.ref('web_assets/$fileName');
        UploadTask uploadTask = ref.putData(fileBytes);
        TaskSnapshot taskSnapshot = await uploadTask;

        // Get the download URL
        String downloadUrl = await taskSnapshot.ref.getDownloadURL();

        setState(() {
          _imageUrl = downloadUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image uploaded successfully')),
        );
      }
    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  Future<void> _generateImage() async {
    setState(() {
      _isGeneratingImage = true;
    });

    try {
      // Use the full description as the transcript for generating the image prompt
      final fullDescription = widget.podcastData['description'];
      final imagePrompt = await _vertexAIService.generateImagePrompt(fullDescription);

      final response = await http.post(
        Uri.parse('https://generate-image-2ghwz42v7q-uc.a.run.app'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'prompt': imagePrompt}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        String originalImageUrl = responseData['image_url'];
        
        // Use the proxy_image function to get a proxied URL
        setState(() {
          _imageUrl = 'https://proxy-image-2ghwz42v7q-uc.a.run.app?url=${Uri.encodeComponent(originalImageUrl)}';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image generated successfully')),
        );
      } else {
        throw Exception('Failed to generate image');
      }
    } catch (e) {
      print('Error generating image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate image: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isGeneratingImage = false;
      });
    }
  }

  Widget _buildImageDisplay() {
    if (_imageUrl != null) {
      return Image.network(
        _imageUrl!,
        height: 100,
        width: 100,
        fit: BoxFit.cover,
        loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('Error loading image: $error');
          return Text('Failed to load image');
        },
      );
    } else if (_isGeneratingImage) {
      return CircularProgressIndicator();
    } else {
      return Text('No image uploaded or generated');
    }
  }

  Future<void> _schedulePodcast() async {
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
        'imageUrl': _imageUrl, // Make sure this is included
        'pubDate': DateFormat('EEE, dd MMM yyyy HH:mm:ss Z').format(DateTime.now()),
      };

      // Use the update_rss_feed function to update the RSS feed
      final updateResponse = await http.post(
        Uri.parse('https://update-rss-feed-2ghwz42v7q-uc.a.run.app'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fileName': _selectedRssFeed,
          'newItem': newItem,
        }),
      );

      if (updateResponse.statusCode != 200) {
        throw Exception('Failed to update RSS feed: ${updateResponse.statusCode}. Response: ${updateResponse.body}');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('RSS feed updated successfully!')),
      );

      await widget.onSchedule(_selectedRssFeed!, newItem);

    } catch (e) {
      print('Error scheduling podcast: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to schedule podcast: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Schedule Podcast',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 16),
          Text(
            'Select an RSS feed to update:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
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
          SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(labelText: 'Episode Title'),
          ),
          TextField(
            controller: _authorController,
            decoration: InputDecoration(labelText: 'Author'),
          ),
          TextField(
            controller: _subtitleController,
            decoration: InputDecoration(labelText: 'Subtitle'),
          ),
          TextField(
            controller: _summaryController,
            maxLines: 3,
            decoration: InputDecoration(labelText: 'Summary'),
          ),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(labelText: 'Description'),
          ),
          TextField(
            controller: _audioUrlController,
            decoration: InputDecoration(labelText: 'Audio URL'),
          ),
          TextField(
            controller: _durationController,
            decoration: InputDecoration(
              labelText: 'Duration (HH:MM:SS, optional)',
              hintText: 'Leave empty if unknown',
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton(
                onPressed: _isUploadingImage ? null : _uploadImage,
                child: _isUploadingImage
                    ? CircularProgressIndicator()
                    : Text('Upload Image'),
              ),
              SizedBox(width: 16),
              ElevatedButton(
                onPressed: _isGeneratingImage ? null : _generateImage,
                child: _isGeneratingImage
                    ? CircularProgressIndicator()
                    : Text('Generate Image'),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildImageDisplay(),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : _schedulePodcast,
            child: _isLoading ? CircularProgressIndicator() : Text('Schedule and Update RSS'),
          ),
          SizedBox(height: 16),
          TextField(
            readOnly: true,
            maxLines: null,
            decoration: InputDecoration(
              labelText: 'Podcast Data',
              border: OutlineInputBorder(),
            ),
            controller: TextEditingController(
              text: '''
Title: ${_titleController.text}
Author: ${_authorController.text}
Subtitle: ${_subtitleController.text}
Summary: ${_summaryController.text}
Description: ${_descriptionController.text}
Audio URL: ${_audioUrlController.text}
Duration: ${_durationController.text}
RSS Feed: $_selectedRssFeed
              ''',
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _subtitleController.dispose();
    _summaryController.dispose();
    _descriptionController.dispose();
    _audioUrlController.dispose();
    _durationController.dispose();
    super.dispose();
  }
}