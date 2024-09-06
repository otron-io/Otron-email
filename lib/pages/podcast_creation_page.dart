// --IMPORTS--
import 'package:flutter/material.dart';
import 'package:home/services/email_service.dart';
import 'package:home/services/vertex_ai_service.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:home/widgets/email_list.dart';
import 'package:home/prompt.dart';
// import 'package:home/widgets/podcast_card.dart'; // Removed
import 'package:home/podcasts.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:home/widgets/generate_sample_widget.dart';
// import 'package:home/widgets/audio_player_widget.dart'; // Removed
import 'package:home/widgets/newsletter_selection_widget.dart';
import 'package:home/newsletters.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:home/widgets/email_review_widget.dart';
import 'package:home/utils/storage_utils.dart';
import 'package:home/widgets/schedule_podcast_widget.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import 'dart:math';
import 'dart:async';
import 'package:home/sample_emails.dart';

// --PODCAST CREATION PAGE CLASS--
class PodcastCreationPage extends StatefulWidget {
  final Function(Map<String, dynamic>) onAddPodcast;

  const PodcastCreationPage({Key? key, required this.onAddPodcast}) : super(key: key);

  @override
  _PodcastCreationPageState createState() => _PodcastCreationPageState();
}

// --PODCAST CREATION PAGE STATE CLASS--
class _PodcastCreationPageState extends State<PodcastCreationPage> {
  final EmailService _emailService = EmailService();
  late VertexAIService _vertexAIService;
  bool _isLoading = false;
  String _loadingMessage = '';
  String _airDay = 'Sunday';
  List<Map<String, dynamic>> _fetchedEmails = [];
  Map<String, dynamic>? _generatedPodcast;
  List<String> _availableNewsletters = [];
  List<String> _selectedNewsletters = [];
  List<String> _customFilters = [];
  bool _isSignedIn = false;
  bool _useSampleData = false;
  DateTimeRange? _selectedDateRange;
  String _selectedLanguage = 'English'; // Default language
  String? _toEmail;
  bool _isFetchingEmails = false;
  Duration _emailFetchDuration = Duration.zero;
  Duration _generationDuration = Duration.zero;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _vertexAIService = VertexAIService(language: _selectedLanguage);
    _loadAvailableNewsletters();
  }

  Future<void> _loadAvailableNewsletters() async {
    setState(() {
      _isLoading = true;
      _availableNewsletters = availableNewsletters;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    print("Building PodcastCreationPage"); // Add this line
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Podcast'),
        actions: [
          _buildLanguageDropdown(),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/customer');
            },
            child: Text('Customer Page'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNewsletterSelection(),
              SizedBox(height: 16),
              _buildDataSourceSelection(),
              SizedBox(height: 16),
              _buildEmailReview(),
              SizedBox(height: 16),
              _buildGenerateSampleButton(),
              if (_isLoading) _buildLoadingIndicator(),
              if (_errorMessage != null) _buildErrorMessage(),
              if (_generatedPodcast != null) ...[
                SizedBox(height: 16),
                _buildGeneratedPodcastPreview(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageDropdown() {
    return DropdownButton<String>(
      value: _selectedLanguage,
      items: <String>['Lithuanian', 'English', 'Spanish']
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: _changeLanguage,
    );
  }

  Widget _buildNewsletterSelection() {
    return NewsletterSelectionWidget(
      availableNewsletters: _availableNewsletters,
      selectedNewsletters: _selectedNewsletters,
      onChanged: (List<String> selectedItems) {
        setState(() {
          _selectedNewsletters = selectedItems;
        });
      },
      onDateRangeChanged: (DateTimeRange? dateRange) {
        setState(() {
          _selectedDateRange = dateRange;
        });
      },
      onToEmailChanged: (String? toEmail) {
        setState(() {
          _toEmail = toEmail;
        });
      },
    );
  }

  Widget _buildDataSourceSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Choose Data Source'),
        SizedBox(height: 8),
        Text(
          'Do you want to use sample data or your Gmail account?',
          style: TextStyle(fontSize: 16),
        ),
        SizedBox(height: 8),
        Text(
          'To connect your Google account, you need to be added as a test user. Email arnoldas@otron.io to gain access.',
          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _useSampleData = true;
                });
                _proceedWithoutGoogleSignIn();
              },
              child: Text('Use Sample Data'),
            ),
            SizedBox(width: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _useSampleData = false;
                });
                _signInAndFetchEmails();
              },
              child: Text('Use Gmail Account'),
            ),
          ],
        ),
        if (_isFetchingEmails) _buildFetchingEmailsIndicator(),
      ],
    );
  }

  Widget _buildFetchingEmailsIndicator() {
    return Column(
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 8),
        Text('Fetching emails... $_loadingMessage'),
        Text('Duration: ${_emailFetchDuration.inSeconds} seconds'),
      ],
    );
  }

  Future<void> _signInAndFetchEmails() async {
    setState(() {
      _isFetchingEmails = true;
      _loadingMessage = 'Signing in...';
    });

    final stopwatch = Stopwatch()..start();

    try {
      bool isSignedIn = await _emailService.isSignedIn();
      if (!isSignedIn) {
        isSignedIn = await _emailService.signIn();
      }

      if (isSignedIn) {
        setState(() {
          _loadingMessage = 'Fetching emails...';
        });
        await _fetchEmails();
        if (_fetchedEmails.isNotEmpty) {
          setState(() {
            _isFetchingEmails = false;
            _emailFetchDuration = stopwatch.elapsed;
          });
        } else {
          _showSnackBar('No emails found. Please try again.');
          setState(() {
            _isFetchingEmails = false;
          });
        }
      } else {
        _showSignupDialog();
      }
    } catch (e) {
      print('Error signing in or fetching emails: $e');
      _showSignupDialog();
    } finally {
      stopwatch.stop();
    }
  }

  void _showSignupDialog() {
    setState(() {
      _isFetchingEmails = false;
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Proceed with Sample Newsletters'),
          content: Text('Since you\'re not signed in with Google, we\'ll use sample newsletters for demonstration purposes.'),
          actions: <Widget>[
            TextButton(
              child: Text('Proceed'),
              onPressed: () {
                Navigator.of(context).pop();
                _proceedWithoutGoogleSignIn();
              },
            ),
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _proceedWithoutGoogleSignIn() {
    setState(() {
      _fetchedEmails = getSampleEmails();
    });
  }

  Future<void> _fetchEmails() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Fetching emails (0/500)...';
    });

    try {
      final newsletters = _selectedNewsletters.contains('All newsletters') ? ['*@*'] : _selectedNewsletters;
      final fetchedEmails = await _emailService.fetchEmails(
        newsletters,
        _selectedDateRange,
        _toEmail,
        (progress) {
          setState(() {
            _loadingMessage = 'Fetching emails ($progress/500)...';
          });
        },
      );
      setState(() {
        _fetchedEmails = fetchedEmails ?? [];
        _isLoading = false;
      });

      print('Fetched ${_fetchedEmails.length} emails');
    } catch (e) {
      print('Error fetching emails: $e');
      _showSnackBar('Failed to fetch emails. Please try again.');
      setState(() {
        _fetchedEmails = [];
        _isLoading = false;
      });
    }
  }

  Widget _buildEmailReview() {
    return SizedBox(
      height: 400,
      child: _fetchedEmails.isEmpty
          ? Center(child: Text('No emails fetched. Please try again.'))
          : EmailReviewWidget(
              key: ValueKey(_selectedLanguage),
              emails: _fetchedEmails,
              emailService: _emailService,
              fetchDuration: _emailFetchDuration,
              onRefresh: _fetchEmails,
              selectedLanguage: _selectedLanguage,
            ),
    );
  }

  Widget _buildGenerateSampleButton() {
    return ElevatedButton(
      onPressed: _generateSamplePodcast,
      child: Text('Generate Sample Podcast'),
    );
  }

  Future<void> _generateSamplePodcast() async {
    if (_generatedPodcast != null) return;

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Analyzing your emails...';
    });

    final stopwatch = Stopwatch()..start();

    try {
      final fullPrompt = await _prepareEmailData();
      setState(() {
        _loadingMessage = 'Generating content...';
      });
      final generatedDescription = await _vertexAIService.generateContent(fullPrompt);
      final urls = _extractUrls(_fetchedEmails);
      setState(() {
        _loadingMessage = 'Generating summary...';
      });
      final generatedSummary = await _vertexAIService.generateSummary(generatedDescription, urls);

      final dateRangeString = _selectedDateRange != null
          ? '${DateFormat('MMMM d, yyyy').format(_selectedDateRange!.start)} - ${DateFormat('MMMM d, yyyy').format(_selectedDateRange!.end)}'
          : DateFormat('MMMM d, yyyy').format(DateTime.now());

      setState(() {
        _loadingMessage = 'Generating title...';
      });
      final generatedTitle = await _vertexAIService.generatePodcastTitle(generatedDescription, dateRangeString);

      setState(() {
        _loadingMessage = 'Generating image...';
      });
      final imagePrompt = await _vertexAIService.generateImagePrompt(generatedDescription);
      final imageUrl = await _generateImage(imagePrompt);

      setState(() {
        _loadingMessage = 'Preparing audio...';
      });

      final audioUrl = await _generateAudio(generatedDescription, generatedTitle);

      setState(() {
        if (mounted) {
          _generatedPodcast = {
            'title': generatedTitle,
            'subtitle': 'Daily Email Digest - ${DateFormat('MMMM d, yyyy').format(DateTime.now())}',
            'summary': generatedSummary,
            'description': generatedDescription,
            'audioUrl': audioUrl,
            'createdAt': DateTime.now().toIso8601String(),
            'urls': urls.join(', '),
            'imageUrl': imageUrl,
          };
          _isLoading = false;
          _generationDuration = stopwatch.elapsed;
        }
      });

      _logGeneratedPodcastData();
    } catch (e) {
      print('Error generating sample podcast: $e');
      _showSnackBar('Failed to generate daily digest. Please try again.');
      setState(() {
        _isLoading = false;
      });
    } finally {
      stopwatch.stop();
    }
  }

  Future<String> _prepareEmailData() async {
    final emailData = _fetchedEmails.map((email) => {
          'subject': email['subject'],
          'sender': email['from'],
          'body': email['body'],
        }).toList();

    final dateRangeString = _selectedDateRange != null
        ? 'for the period from ${DateFormat('MMMM d, yyyy').format(_selectedDateRange!.start)} to ${DateFormat('MMMM d, yyyy').format(_selectedDateRange!.end)}'
        : '';

    return efficientDailyEmailSummaryPrompt
        .replaceAll('{Placeholder for raw email data}', jsonEncode(emailData))
        .replaceAll('[current date]', dateRangeString);
  }

  List<String> _extractUrls(List<Map<String, dynamic>> emailData) {
    return emailData
        .map((email) => email['url'] as String?)
        .where((url) => url != null && url.isNotEmpty)
        .cast<String>()
        .toList();
  }

  Future<String> _generateImage(String prompt) async {
    final response = await http.post(
      Uri.parse('https://generate-image-2ghwz42v7q-uc.a.run.app'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'prompt': prompt}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['image_url'];
    } else {
      throw Exception('Failed to generate image: ${response.body}');
    }
  }

  Future<String> _generateAudio(String generatedDescription, String generatedTitle) async {
    final String apiUrl = 'https://tts-2ghwz42v7q-uc.a.run.app';
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'text': generatedDescription, 'service': 'openai'}),
    );

    if (response.statusCode == 200) {
      final dateFormat = DateFormat('yyyyMMdd');
      final timeFormat = DateFormat('HHmmss');
      final sanitizedTitle = generatedTitle.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase();
      final fileName = 'audio_${dateFormat.format(DateTime.now())}_${timeFormat.format(DateTime.now())}_${sanitizedTitle}.mp3';

      return await StorageUtils.uploadFile(response.bodyBytes, 'audio/$fileName');
    } else {
      throw Exception('Failed to generate audio');
    }
  }

  void _logGeneratedPodcastData() {
    print('Generated podcast data:');
    print('Title: ${_generatedPodcast!['title']}');
    print('Subtitle: ${_generatedPodcast!['subtitle']}');
    print('Summary length: ${_generatedPodcast!['summary'].length} characters');
    print('Description length: ${_generatedPodcast!['description'].length} characters');
    print('Audio URL: ${_generatedPodcast!['audioUrl']}');
    print('Created at: ${_generatedPodcast!['createdAt']}');
    print('URLs: ${_generatedPodcast!['urls']}');
    print('Image URL: ${_generatedPodcast!['imageUrl']}');
  }

  Widget _buildLoadingIndicator() {
    return Column(
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 8),
        Text(_loadingMessage),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Column(
      children: [
        SizedBox(height: 8),
        Text(
          _errorMessage!,
          style: TextStyle(color: Colors.red),
        ),
      ],
    );
  }

  Widget _buildGeneratedPodcastPreview() {
    final now = DateTime.now();
    final dateFormat = DateFormat('MMMM d, yyyy');
    final todayDate = dateFormat.format(now);
    
    final prefilledPodcastData = {
      ..._generatedPodcast ?? {},
      'author': 'Otron Daily',
      'subtitle': todayDate,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SchedulePodcastWidget(
          podcastData: prefilledPodcastData,
          onSchedule: _updateRssFeed,
          selectedDateRange: _selectedDateRange,
          language: _selectedLanguage,
        ),
      ],
    );
  }

  Future<void> _updateRssFeed(String selectedFeed, Map<String, dynamic> podcastData) async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Updating RSS feed...';
    });

    try {
      final feedUrl = await StorageUtils.getRssFeedUrl(selectedFeed);
      if (feedUrl == null) {
        throw Exception('Failed to get RSS feed URL');
      }

      if (_generatedPodcast != null && _generatedPodcast!['imageUrl'] != null) {
        podcastData['imageUrl'] = _generatedPodcast!['imageUrl'];
      }

      final response = await http.post(
        Uri.parse('https://update-rss-feed-2ghwz42v7q-uc.a.run.app'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'fileName': selectedFeed,
          'newItem': podcastData,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Podcast scheduled and RSS feed updated successfully!')),
        );

        widget.onAddPodcast(podcastData);

        Navigator.of(context).pop();
      } else {
        throw Exception('Failed to update RSS feed: ${response.body}');
      }
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

  Future<void> _schedulePodcast() async {
    final newPodcast = {
      'title': 'Weekly Podcast - ${DateTime.now().toIso8601String()}',
      'frequency': 'Weekly',
      'airDay': _airDay,
      'newsletters': _selectedNewsletters,
      'createdAt': DateTime.now().toIso8601String(),
      'nextGenerationDate': _calculateNextGenerationDate(),
      'type': 'upcoming',
    };

    widget.onAddPodcast(newPodcast);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Podcast scheduled successfully!')),
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  DateTime _calculateNextGenerationDate() {
    final now = DateTime.now();
    final daysUntilAirDay = _getDayNumber(_airDay) - now.weekday;
    return DateTime(now.year, now.month, now.day + (daysUntilAirDay <= 0 ? 7 + daysUntilAirDay : daysUntilAirDay));
  }

  int _getDayNumber(String day) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days.indexOf(day) + 1;
  }

  void _changeLanguage(String? newLanguage) {
    if (newLanguage != null) {
      setState(() {
        _selectedLanguage = newLanguage;
        _vertexAIService.updateLanguage(newLanguage);
      });
      // Add this line to regenerate the sample podcast when language changes
      if (_fetchedEmails.isNotEmpty) {
        _generateSamplePodcast();
      }
    }
  }

  // Add this method to show SnackBar messages
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class MyCustomSource extends StreamAudioSource {
  final Uint8List _audioData;

  MyCustomSource(this._audioData);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= _audioData.length;
    return StreamAudioResponse(
      sourceLength: _audioData.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(_audioData.sublist(start, end)),
      contentType: 'audio/mpeg',
    );
  }
}