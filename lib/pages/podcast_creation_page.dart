// --IMPORTS--
import 'package:flutter/material.dart';
import 'package:home/services/email_service.dart';
import 'package:home/services/vertex_ai_service.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:home/widgets/email_list.dart';
import 'package:home/prompt.dart';

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
  List<String> _selectedDomains = ['buildspace.so'];
  String _airDay = 'Sunday';
  List<Map<String, dynamic>> _fetchedEmails = [];

  List<String> _availableDomains = [
    'buildspace.so',
    'peterattiamd.com',
    'diamandis.com',
    // ... (rest of the domains)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Schedule Weekly Podcast'),
        centerTitle: true,
      ),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 3) {
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
            content: _buildDomainSelection(),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: Text('Set Air Day'),
            content: _buildAirDaySelection(),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: Text('Review Emails'),
            content: _buildEmailReview(),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: Text('Schedule Podcast'),
            content: _buildSchedulePodcast(),
            isActive: _currentStep >= 3,
            state: _currentStep == 3 ? StepState.complete : StepState.indexed,
          ),
        ],
      ),
    );
  }

  // --DOMAIN SELECTION WIDGET--
  Widget _buildDomainSelection() {
    return DropdownSearch<String>.multiSelection(
      items: _availableDomains,
      selectedItems: _selectedDomains,
      onChanged: (List<String> selectedItems) {
        setState(() {
          _selectedDomains = selectedItems;
        });
      },
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: "Select Newsletters",
          hintText: "Choose newsletter domains",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // --AIR DAY SELECTION WIDGET--
  Widget _buildAirDaySelection() {
    return DropdownButtonFormField<String>(
      value: _airDay,
      decoration: InputDecoration(
        labelText: 'Air Day',
        border: OutlineInputBorder(),
      ),
      onChanged: (String? newValue) {
        setState(() {
          _airDay = newValue!;
        });
      },
      items: <String>['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }

  // --EMAIL REVIEW WIDGET--
  Widget _buildEmailReview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilledButton.icon(
          icon: Icon(Icons.refresh),
          label: Text('Fetch Emails'),
          onPressed: _fetchEmails,
        ),
        SizedBox(height: 16),
        if (_isLoading)
          CircularProgressIndicator()
        else if (_fetchedEmails.isNotEmpty)
          EmailList(emails: _fetchedEmails)
        else
          Text('No emails fetched yet. Click "Fetch Emails" to load emails.'),
      ],
    );
  }

  // --SCHEDULE PODCAST WIDGET--
  Widget _buildSchedulePodcast() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Schedule Weekly Podcast',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        SizedBox(height: 16),
        Text(
          'This will schedule a weekly podcast to be generated on $_airDay.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        SizedBox(height: 16),
        FilledButton.icon(
          icon: Icon(Icons.schedule),
          label: Text('Schedule'),
          onPressed: _schedulePodcast,
        ),
      ],
    );
  }

  Future<void> _fetchEmails() async {
    if (!mounted) return;  // Add this check at the beginning of the method

    setState(() {
      _isLoading = true;
      _fetchedEmails = [];
    });

    try {
      final emails = await _emailService.fetchEmails(_selectedDomains);
      if (!mounted) return;  // Add this check before setting state after async operation
      setState(() {
        _fetchedEmails = emails ?? [];
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching emails: $e');
      if (!mounted) return;  // Add this check before showing SnackBar
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
      'type': 'upcoming',  // Add this line to distinguish between active and upcoming podcasts
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
}