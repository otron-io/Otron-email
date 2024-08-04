// --IMPORTS--
import 'package:flutter/material.dart';
import 'package:home/services/email_service.dart';
import 'package:home/services/vertex_ai_service.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:home/widgets/email_list.dart';
import 'package:home/prompt.dart';
import 'package:home/widgets/podcast_card.dart';
import 'package:home/podcasts.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:home/widgets/generate_sample_widget.dart';
import 'package:home/widgets/audio_player_widget.dart';
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
  late final VertexAIService _vertexAIService;
  int _currentStep = 0;
  bool _isLoading = false;
  String _loadingMessage = '';
  String _airDay = 'Sunday';
  List<Map<String, dynamic>> _fetchedEmails = [];
  final bool _enableLastTwoSteps = false;
  Map<String, dynamic>? _generatedPodcast;
  List<String> _availableNewsletters = [];
  List<String> _selectedNewsletters = [];
  List<String> _customFilters = [];
  bool _isSignedIn = false;
  bool _useSampleData = false;
  DateTimeRange? _selectedDateRange;
  String _selectedLanguage = 'English'; // Default language
  String? _toEmail;

  @override
  void initState() {
    super.initState();
    _vertexAIService = VertexAIService(language: _selectedLanguage);
    _loadAvailableNewsletters();
  }

  Future<void> _loadAvailableNewsletters() async {
    setState(() {
      _isLoading = true;
      _availableNewsletters = availableNewsletters; // Use the imported list from newsletters.dart
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Weekly Podcast'),
        centerTitle: true,
        actions: [
          DropdownButton<String>(
            value: _selectedLanguage,
            items: <String>['Lithuanian', 'English', 'Spanish'] // Add more languages as needed
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                _changeLanguage(newValue);
              }
            },
          ),
        ],
      ),
      body: _isLoading
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(_loadingMessage),
              ],
            ),
          )
        : SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 600),
                child: Stepper(
                  physics: ClampingScrollPhysics(),
                  type: StepperType.vertical,
                  currentStep: _currentStep,
                  onStepContinue: () async {
                    if (_currentStep == 0 && _selectedNewsletters.isNotEmpty) {
                      await _showDataSourceDialog();
                    } else if (_currentStep == 1) {
                      setState(() {
                        _currentStep += 1;
                      });
                      await _generateSamplePodcast();
                    } else if (_currentStep == 2) {
                      setState(() {
                        _currentStep += 1;
                      });
                    } else if (_currentStep == 3) {
                      await _updateRssFeed('default', _generatedPodcast!);
                    }
                  },
                  onStepCancel: () {
                    if (_currentStep > 0) {
                      setState(() {
                        _currentStep -= 1;
                      });
                    }
                  },
                  controlsBuilder: (BuildContext context, ControlsDetails details) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Row(
                        children: <Widget>[
                          ElevatedButton(
                            onPressed: details.onStepContinue,
                            child: Text(_currentStep == 3 ? 'Finish' : 'Continue'),
                          ),
                          if (_currentStep > 0)
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: TextButton(
                                onPressed: details.onStepCancel,
                                child: const Text('Back'),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                  steps: [
                    Step(
                      title: const Text('Select Newsletters'),
                      content: _buildNewsletterSelection(),
                      isActive: _currentStep >= 0,
                      state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                    ),
                    Step(
                      title: const Text('Review Emails'),
                      content: _buildEmailReview(),
                      isActive: _currentStep >= 1,
                      state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                    ),
                    Step(
                      title: const Text('Generate Sample'),
                      content: _buildGenerateSample(),
                      isActive: _currentStep >= 2,
                      state: _currentStep > 2 ? StepState.complete : StepState.indexed,
                    ),
                    Step(
                      title: const Text('Schedule Podcast'),
                      content: _buildSchedulePodcastUI(),
                      isActive: _currentStep >= 3,
                      state: _currentStep > 3 ? StepState.complete : StepState.indexed,
                    ),
                  ],
                ),
              ),
            ),
          ),
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
        if (dateRange != null) {
          // Ensure the time is set to the start and end of the day in local time
          final start = DateTime(dateRange.start.year, dateRange.start.month, dateRange.start.day);
          final end = DateTime(dateRange.end.year, dateRange.end.month, dateRange.end.day, 23, 59, 59);
          setState(() {
            _selectedDateRange = DateTimeRange(start: start, end: end);
          });
        } else {
          setState(() {
            _selectedDateRange = null;
          });
        }
      },
      onToEmailChanged: (String? toEmail) {
        setState(() {
          _toEmail = toEmail;
        });
      },
    );
  }

  Future<void> _showDataSourceDialog() async {
    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose Data Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Do you want to use sample data or your Gmail account?'),
              SizedBox(height: 16),
              Text(
                'To connect your Google account, you need to be added as a test user. Email arnoldas@otron.io to gain access.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Use Sample Data'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
            TextButton(
              child: Text('Use Gmail Account'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(null),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        _useSampleData = result;
        if (result) {
          _proceedWithoutGoogleSignIn();
        } else {
          _signInAndFetchEmails();
        }
      });
    } else {
      // User cancelled, reset to step 0
      setState(() {
        _currentStep = 0;
      });
    }
  }

  Future<void> _signInAndFetchEmails() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Signing in...';
    });

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
            _currentStep += 1;
            _isLoading = false;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No emails found. Please try again.')),
          );
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        _showSignupDialog();
      }
    } catch (e) {
      print('Error signing in or fetching emails: $e');
      _showSignupDialog();
    }
  }

  void _showSignupDialog() {
    setState(() {
      _isLoading = false;
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
    // Proceed to the next step with sample emails
    setState(() {
      _currentStep += 1;
      _fetchedEmails = [
        {
          'subject': 'This Week in Tech: AI Breakthroughs and Privacy Concerns',
          'from': 'techdigest@example.com',
          'body': '''
Dear Tech Enthusiasts,

This week has been a whirlwind in the tech world. Here are the highlights:

1. OpenAI's GPT-5 Announcement: The next generation of language models is here, promising even more human-like interactions. But what are the ethical implications?

2. Apple's New Privacy Features: iOS 18 will introduce groundbreaking privacy controls. We break down what this means for users and advertisers.

3. The Chip Shortage: Finally Easing? We analyze the latest industry reports and what they mean for consumer electronics prices.

Stay curious and keep innovating!

The TechDigest Team
''',
        },
        {
          'subject': 'Mindful Monday: Embracing Change and Growth',
          'from': 'dailyzen@example.com',
          'body': '''
Hello Mindful Ones,

As we start a new week, let's focus on embracing change and fostering personal growth:

1. Meditation of the Week: "Flowing with Change" - A 10-minute guided meditation to help you adapt to life's constant shifts.

2. Wisdom Quote: "The only way to make sense out of change is to plunge into it, move with it, and join the dance." - Alan Watts

3. Weekly Challenge: Try one new thing each day, no matter how small. Share your experiences in our community forum!

Remember, every moment is an opportunity for growth.

Breathe deeply and live fully,
Your DailyZen Team
''',
        },
        {
          'subject': 'Gourmet Gazette: Seasonal Delights and Culinary Trends',
          'from': 'tastebud@example.com',
          'body': '''
Greetings, Food Lovers!

Spring is in full swing, and so are our taste buds! Here's what's cooking:

1. Ingredient Spotlight: Fiddlehead Ferns - These curly greens are the talk of farmers' markets. We share three delicious recipes to try.

2. Restaurant Review: "The Humble Radish" in Portland is redefining farm-to-table dining. Our critic gives it 4.5/5 stars!

3. Trend Alert: Fermentation Station - From kombucha to kimchi, fermented foods are having a moment. We explore the health benefits and how to start fermenting at home.

Happy cooking and bon appétit!

The Gourmet Gazette Team
''',
        },
      ];
    });
  }

  Future<void> _fetchEmails() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Fetching emails (0/500)...';
    });

    try {
      final newsletters = _selectedNewsletters.contains('All newsletters') 
        ? ['*@*'] 
        : _selectedNewsletters;
      final fetchedEmails = await _emailService.fetchEmails(
        newsletters, 
        _selectedDateRange,
        _toEmail,
        (progress) {
          setState(() {
            _loadingMessage = 'Fetching emails ($progress/500)...';
          });
        }
      );
      setState(() {
        _fetchedEmails = fetchedEmails ?? [];
        _isLoading = false;
      });

      print('Fetched ${_fetchedEmails.length} emails'); // Add this line for debugging
    } catch (e) {
      print('Error fetching emails: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch emails. Please try again.')),
      );
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
        : EmailList(
            emails: _fetchedEmails,
            emailService: _emailService,
          ),
    );
  }

  Widget _buildGenerateSample() {
    return GenerateSampleWidget(
      isLoading: _isLoading,
      loadingMessage: _loadingMessage,
      generatedPodcast: _generatedPodcast,
      onStreamAudio: (audioPath) {
        setState(() {
          _generatedPodcast!['audioPath'] = audioPath;
        });
      },
    );
  }

  Future<void> _generateSamplePodcast() async {
    if (_generatedPodcast != null) return; // Skip if already generated

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Analyzing your emails...';
    });

    try {
      final fullPrompt = await _prepareEmailData();
      final generatedDescription = await _vertexAIService.generateContent(fullPrompt);
      final urls = _extractUrls(_fetchedEmails);
      final generatedSummary = await _vertexAIService.generateSummary(generatedDescription, urls);

      // Generate the dateRangeString
      String dateRangeString = '';
      if (_selectedDateRange != null) {
        final startDate = DateFormat('MMMM d, yyyy').format(_selectedDateRange!.start);
        final endDate = DateFormat('MMMM d, yyyy').format(_selectedDateRange!.end);
        dateRangeString = '$startDate - $endDate';
      } else {
        dateRangeString = DateFormat('MMMM d, yyyy').format(DateTime.now());
      }

      final generatedTitle = await _vertexAIService.generatePodcastTitle(generatedDescription, dateRangeString);

      // Generate image
      final imagePrompt = await _vertexAIService.generateImagePrompt(generatedDescription);
      final imageUrl = await _generateImage(imagePrompt);

      setState(() {
        _loadingMessage = 'Preparing audio...';
      });

      // Generate audio
      final String apiUrl = 'https://tts-2ghwz42v7q-uc.a.run.app';
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'text': generatedDescription,
          'service': 'openai'
        }),
      );

      if (response.statusCode == 200) {
        // Create a smart file name
        final dateFormat = DateFormat('yyyyMMdd');
        final timeFormat = DateFormat('HHmmss');
        final sanitizedTitle = generatedTitle.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase();
        final fileName = 'audio_${dateFormat.format(DateTime.now())}_${timeFormat.format(DateTime.now())}_${sanitizedTitle}.mp3';
        
        // Upload audio file to Firebase Storage
        final audioUrl = await StorageUtils.uploadFile(response.bodyBytes, 'audio/$fileName');

        setState(() {
          if (mounted) {
            _generatedPodcast = {
              'title': generatedTitle,
              'subtitle': 'Daily Email Digest - ${DateFormat('MMMM d, yyyy').format(DateTime.now())}',
              'summary': generatedSummary,
              'description': generatedDescription,
              'audioData': response.bodyBytes,
              'audioUrl': audioUrl,
              'audioFileName': fileName,
              'createdAt': DateTime.now().toIso8601String(),
              'urls': urls.join(', '),
              'imageUrl': imageUrl,
            };
            _isLoading = false;
          }
        });

        print('Generated podcast data:');
        print('Title: ${_generatedPodcast!['title']}');
        print('Subtitle: ${_generatedPodcast!['subtitle']}');
        print('Summary length: ${_generatedPodcast!['summary'].length} characters');
        print('Description length: ${_generatedPodcast!['description'].length} characters');
        print('Audio URL: ${_generatedPodcast!['audioUrl']}');
        print('Audio file name: ${_generatedPodcast!['audioFileName']}');
        print('Created at: ${_generatedPodcast!['createdAt']}');
        print('URLs: ${_generatedPodcast!['urls']}');
        print('Image URL: ${_generatedPodcast!['imageUrl']}');
      } else {
        throw Exception('Failed to generate audio');
      }
    } catch (e) {
      print('Error generating sample podcast: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate daily digest. Please try again.')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String> _prepareEmailData() async {
    final emailData = _fetchedEmails.map((email) => {
      'subject': email['subject'],
      'sender': email['from'],
      'body': email['body'],
    }).toList();

    // Format the date range
    String dateRangeString = '';
    if (_selectedDateRange != null) {
      final startDate = DateFormat('MMMM d, yyyy').format(_selectedDateRange!.start);
      final endDate = DateFormat('MMMM d, yyyy').format(_selectedDateRange!.end);
      dateRangeString = 'for the period from $startDate to $endDate';
    }

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
      Uri.parse('https://generate-image-2ghwz42v7q-uc.a.run.app'), // Updated generate_image URL
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

  Widget _buildSchedulePodcastUI() {
    final now = DateTime.now();
    final dateFormat = DateFormat('MMMM d, yyyy');
    final todayDate = dateFormat.format(now);
    
    final prefilledPodcastData = {
      ..._generatedPodcast ?? {},
      'author': 'Otron Daily',
      'subtitle': todayDate,
    };

    return SchedulePodcastWidget(
      podcastData: prefilledPodcastData,
      onSchedule: _updateRssFeed,
      selectedDateRange: _selectedDateRange,
      language: _selectedLanguage,
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

      // Ensure the imageUrl is included in the podcastData
      if (_generatedPodcast != null && _generatedPodcast!['imageUrl'] != null) {
        podcastData['imageUrl'] = _generatedPodcast!['imageUrl'];
      }

      final response = await http.post(
        Uri.parse('https://update-rss-feed-2ghwz42v7q-uc.a.run.app'), // Updated update_rss_feed URL
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

        // Call the onAddPodcast callback
        widget.onAddPodcast(podcastData);

        // Navigate back or to a confirmation screen
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

  void _changeLanguage(String newLanguage) {
    setState(() {
      _selectedLanguage = newLanguage;
      _vertexAIService = VertexAIService(language: _selectedLanguage);
    });
    // You might want to regenerate content or update other language-dependent components here
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