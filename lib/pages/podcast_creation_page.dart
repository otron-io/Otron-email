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
  final VertexAIService _vertexAIService = VertexAIService();
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

  @override
  void initState() {
    super.initState();
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
        : Column(
            children: [
              Expanded(
                child: Stepper(
                  type: StepperType.vertical,
                  currentStep: _currentStep,
                  onStepContinue: () async {
                    if (_currentStep == 0 && _selectedNewsletters.isNotEmpty) {
                      await _signInAndFetchEmails();
                    } else if (_currentStep == 1) {
                      setState(() {
                        _currentStep += 1;
                      });
                      await _generateSamplePodcast();
                    } else if (_currentStep == 2) {
                      _showComingSoonMessage();
                    }
                  },
                  onStepCancel: () {
                    if (_currentStep > 0) {
                      setState(() {
                        _currentStep -= 1;
                      });
                    }
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
                      content: Container(
                        height: 400, // Adjust this value as needed
                        child: _buildEmailReview(),
                      ),
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
                      title: const Text('Set Air Day'),
                      content: _buildComingSoon(),
                      isActive: false,
                      state: StepState.disabled,
                    ),
                    Step(
                      title: const Text('Schedule Podcast'),
                      content: _buildComingSoon(),
                      isActive: false,
                      state: StepState.disabled,
                    ),
                  ],
                ),
              ),
            ],
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
    );
  }

  Future<void> _signInAndFetchEmails() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Signing in...';
    });

    try {
      bool isSignedIn = await _emailService.isSignedIn();
      if (!isSignedIn) {
        await _emailService.signIn();
        isSignedIn = await _emailService.isSignedIn();
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
          // Show a message if no emails were fetched
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No emails found. Please try again.')),
          );
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        // Show Airtable signup form if Google sign-in fails
        _showSignupDialog();
      }
    } catch (e) {
      print('Error signing in or fetching emails: $e');
      // Show Airtable signup form if there's an error
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
      _loadingMessage = 'Fetching emails...';
    });

    try {
      final fetchedEmails = await _emailService.fetchEmails(_selectedNewsletters);
      setState(() {
        _fetchedEmails = fetchedEmails ?? [];
        _isLoading = false;
      });
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
    return EmailReviewWidget(
      isLoading: _isLoading,
      fetchedEmails: _fetchedEmails,
      onFetchEmails: _fetchEmails,
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
      _loadingMessage = 'Reading your email...';
    });

    try {
      // Generate podcast title and subtitle
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(Duration(days: 7));
      final dateFormat = DateFormat('MMM d, yyyy');
      final title = 'Your Personal Podcast: Last Seven Days';
      final subtitle = '${dateFormat.format(sevenDaysAgo)} - ${dateFormat.format(now)}';

      // Prepare email data for the prompt
      final emailData = _fetchedEmails.map((email) => {
        'subject': email['subject'],
        'sender': email['from'],
        'body': email['body'],
      }).toList();

      // Generate podcast content using VertexAI
      final prompt = emailSummaryPrompt.replaceAll('{Placeholder for raw email data}', jsonEncode(emailData));
      
      setState(() {
        _loadingMessage = 'Writing the script...';
      });

      final generatedContent = await _vertexAIService.generateContent(prompt);

      // Trim the generated content to the first 40 words
      final List<String> words = generatedContent.split(' ');
      final String trimmedContent = words.take(40).join(' ');

      // Set loading message for audio generation
      setState(() {
        _loadingMessage = 'Voicing over...';
      });

      // Generate audio
      final String apiUrl = 'https://tts-2ghwz42v7q-uc.a.run.app'; // Your TTS API URL
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'text': trimmedContent}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _generatedPodcast = {
            'title': title,
            'subtitle': subtitle,
            'content': generatedContent,
            'audioData': response.bodyBytes, // Store as 'audioData' instead of 'audioPath'
            'createdAt': now.toIso8601String(),
          };
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to generate audio');
      }
    } catch (e) {
      print('Error generating sample podcast: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate sample podcast. Please try again.')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildComingSoon() {
    return Center(
      child: Text(
        'Coming Soon!',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
  }

  void _showComingSoonMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('This feature is coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
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
}