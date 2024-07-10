// --IMPORTS--
import 'package:flutter/material.dart';
import 'package:home/services/email_service.dart';
import 'package:home/services/vertex_ai_service.dart';
import 'package:home/widgets/domain_selection_widget.dart';
import 'package:home/widgets/air_day_selection_widget.dart';
import 'package:home/widgets/email_review_widget.dart';
import 'package:home/widgets/schedule_podcast_widget.dart';
import 'package:home/widgets/generate_sample_widget.dart';
import 'package:home/widgets/feedback_dialog.dart';
import 'package:home/prompt.dart';
import 'package:home/domains.dart';
import 'package:home/podcasts.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

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
  List<String> _selectedDomains = [];
  String _airDay = 'Sunday';
  List<Map<String, dynamic>> _fetchedEmails = [];
  List<String> _availableDomains = [];
  final bool _enableLastTwoSteps = false;
  Map<String, dynamic>? _generatedPodcast;

  @override
  void initState() {
    super.initState();
    _loadAvailableDomains();
  }

  Future<void> _loadAvailableDomains() async {
    setState(() {
      _isLoading = true;
      _availableDomains = availableDomains;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Schedule Weekly Podcast'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Stepper(
            type: StepperType.vertical,
            currentStep: _currentStep,
            onStepContinue: () async {
              if (_currentStep == 0 && _selectedDomains.isNotEmpty) {
                await _fetchEmails();
              }
              if (_currentStep < 2 || (_enableLastTwoSteps && _currentStep < 4)) {
                setState(() {
                  _currentStep += 1;
                });
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
                title: Text('Select Newsletters'),
                content: DomainSelectionWidget(
                  availableDomains: _availableDomains,
                  selectedDomains: _selectedDomains,
                  onChanged: (selectedItems) {
                    setState(() {
                      _selectedDomains = selectedItems;
                    });
                  },
                ),
                isActive: _currentStep >= 0,
                state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              ),
              Step(
                title: Text('Review Emails'),
                content: EmailReviewWidget(
                  isLoading: _isLoading,
                  fetchedEmails: _fetchedEmails,
                  onFetchEmails: _fetchEmails,
                ),
                isActive: _currentStep >= 1,
                state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              ),
              Step(
                title: Text('Generate Sample'),
                content: GenerateSampleWidget(
                  isLoading: _isLoading,
                  generatedPodcast: _generatedPodcast,
                  onGenerateSample: _generateSamplePodcast,
                  onShowFeedbackDialog: _showFeedbackDialog,
                ),
                isActive: _currentStep >= 2,
                state: _currentStep > 2 ? StepState.complete : StepState.indexed,
              ),
              Step(
                title: Text('Set Air Day'),
                content: AirDaySelectionWidget(
                  airDay: _airDay,
                  onChanged: (newValue) {
                    setState(() {
                      _airDay = newValue!;
                    });
                  },
                ),
                isActive: _currentStep >= 3 && _enableLastTwoSteps,
                state: _enableLastTwoSteps 
                    ? (_currentStep > 3 ? StepState.complete : StepState.indexed)
                    : StepState.disabled,
              ),
              Step(
                title: Text('Schedule Podcast'),
                content: SchedulePodcastWidget(
                  airDay: _airDay,
                  onSchedulePodcast: _schedulePodcast,
                ),
                isActive: _currentStep >= 4 && _enableLastTwoSteps,
                state: _enableLastTwoSteps 
                    ? (_currentStep == 4 ? StepState.complete : StepState.indexed)
                    : StepState.disabled,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _fetchEmails() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _fetchedEmails = [];
    });

    try {
      final emails = await _emailService.fetchEmails(_selectedDomains);
      if (!mounted) return;
      setState(() {
        _fetchedEmails = emails ?? [];
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching emails: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch emails. Please try again.')),
      );
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
      'domains': _selectedDomains,
      'createdAt': DateTime.now().toIso8601String(),
      'nextGenerationDate': _calculateNextGenerationDate(),
      'type': 'upcoming',
    };

    widget.onAddPodcast(newPodcast);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Podcast scheduled successfully!')),
    );

    Navigator.pop(context);
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

  Future<void> _generateSamplePodcast() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(Duration(days: 7));
      final dateFormat = DateFormat('MMM d, yyyy');
      final title = 'Your Personal Podcast: Last Seven Days';
      final subtitle = '${dateFormat.format(sevenDaysAgo)} - ${dateFormat.format(now)}';

      final emailData = _fetchedEmails.map((email) => {
        'subject': email['subject'],
        'sender': email['from'],
        'body': email['body'],
      }).toList();

      final prompt = emailSummaryPrompt.replaceAll('{Placeholder for raw email data}', jsonEncode(emailData));
      final generatedContent = await _vertexAIService.generateContent(prompt);

      final extractedUrls = await _extractUrls(_fetchedEmails);
      print('Extracted URLs: $extractedUrls');

      final audioPath = podcasts.isNotEmpty ? podcasts[0]['audioPath'] : 'audio/default.mp3';

      setState(() {
        _generatedPodcast = {
          'title': title,
          'subtitle': subtitle,
          'content': generatedContent,
          'audioUrl': audioPath,
          'createdAt': now.toIso8601String(),
          'extractedUrls': extractedUrls,
        };
        _isLoading = false;
      });
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

  Future<List<Map<String, String>>> _extractUrls(List<Map<String, dynamic>> emails) async {
    final emailData = emails.map((email) => {
      'subject': email['subject'],
      'sender': email['from'],
      'body': email['body'],
    }).toList();

    final prompt = emailUrlExtractionPrompt.replaceAll('{Placeholder for raw email data}', jsonEncode(emailData));
    final generatedContent = await _vertexAIService.generateContent(prompt);

    print('Generated content for URL extraction: $generatedContent');

    final urlRegex = RegExp(r'"url":\s*"(https?://[^"]+)"');
    final descriptionRegex = RegExp(r'"description":\s*"([^"]+)"');

    final urls = urlRegex.allMatches(generatedContent).map((m) => m.group(1)!).toList();
    final descriptions = descriptionRegex.allMatches(generatedContent).map((m) => m.group(1)!).toList();

    final extractedUrls = List<Map<String, String>>.generate(
      urls.length,
      (index) => {
        'url': urls[index],
        'description': index < descriptions.length ? descriptions[index] : 'Link ${index + 1}',
      },
    );

    print('Extracted URLs: $extractedUrls');

    return extractedUrls;
  }

  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FeedbackDialog(
          onSubmitFeedback: _submitFeedback,
          generatedPodcast: _generatedPodcast,
        );
      },
    );
  }

  void _submitFeedback(String feedback, int satisfaction, bool includePodcast, String email) {
    print('Feedback: $feedback');
    print('Satisfaction: $satisfaction');
    print('Include Podcast: $includePodcast');
    print('Email: $email');
    if (includePodcast) {
      print('Podcast Content: ${_generatedPodcast!['content']}');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Thank you for your feedback!')),
    );
  }
}