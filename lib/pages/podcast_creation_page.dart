import 'package:flutter/material.dart';
import 'package:home/services/email_service.dart';
import 'package:home/services/vertex_ai_service.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:home/widgets/audio_player_widget.dart';
import 'package:home/widgets/generated_text_display.dart';
import 'package:home/widgets/email_list.dart';
import 'package:home/prompt.dart'; // Import the prompt template

class PodcastCreationPage extends StatefulWidget {
  final Function(Map<String, String>) onAddPodcast;

  const PodcastCreationPage({Key? key, required this.onAddPodcast}) : super(key: key);

  @override
  _PodcastCreationPageState createState() => _PodcastCreationPageState();
}

class _PodcastCreationPageState extends State<PodcastCreationPage> {
  final EmailService _emailService = EmailService();
  final VertexAIService _vertexAIService = VertexAIService();
  bool _isLoading = false;
  List<String> _selectedDomains = ['buildspace.so'];
  List<Map<String, dynamic>> _fetchedEmails = [];
  String _generatedContent = '';

  List<String> _availableDomains = [
    'buildspace.so',
    'peterattiamd.com',
    'diamandis.com',
    'theseattledataguy.com',
    'pragmaticengineer.com',
    'mail.cardealershipguy.org',
    'asmartbear.com',
    'substack.com',
    'spyglass.org',
    'lethain.com',
    'bensbites.co',
    'amediaoperator.com',
    'ventureinsecurity.net',
    'copyrevival.co',
    'zerotomastery.io',
    'morningbrew.com',
    'tldr.tech',
    'mail.beehiiv.com'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Podcast'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDomainSelection(),
                if (_isLoading) ...[
                  SizedBox(height: 16),
                  CircularProgressIndicator(),
                ],
                if (_fetchedEmails.isNotEmpty) ...[
                  SizedBox(height: 16),
                  _buildFetchEmails(),
                ],
                if (_generatedContent.isNotEmpty) ...[
                  SizedBox(height: 16),
                  _buildGeneratePodcast(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDomainSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 1: Select Domains',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 16),
        DropdownSearch<String>.multiSelection(
          items: _availableDomains,
          selectedItems: _selectedDomains,
          onChanged: (List<String> selectedItems) {
            setState(() {
              _selectedDomains = selectedItems;
            });
          },
          dropdownDecoratorProps: DropDownDecoratorProps(
            dropdownSearchDecoration: InputDecoration(
              labelText: "Select Domains",
              hintText: "Choose email domains",
            ),
          ),
        ),
        SizedBox(height: 16),
        ElevatedButton(
          child: Text('Fetch Emails'),
          onPressed: _fetchEmails,
        ),
      ],
    );
  }

  Widget _buildFetchEmails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 2: Fetch Emails',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (_fetchedEmails.isNotEmpty) ...[
          SizedBox(height: 16),
          Text('Fetched ${_fetchedEmails.length} emails'),
          SizedBox(height: 16),
          EmailList(
            emails: _fetchedEmails,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            child: Text('Generate Podcast'),
            onPressed: _generatePodcast,
          ),
        ],
      ],
    );
  }

  Widget _buildGeneratePodcast() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 3: Podcast Ready',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (_generatedContent.isNotEmpty) ...[
          SizedBox(height: 16),
          AudioPlayerWidget(audioPath: 'audio/Josephv2.mp3'),
          SizedBox(height: 16),
          GeneratedTextDisplay(streamedContent: [_generatedContent]),
          SizedBox(height: 16),
          ElevatedButton(
            child: Text('Save Podcast'),
            onPressed: () {
              final newPodcast = {
                'title': 'New Podcast ${DateTime.now()}',
                'content': _generatedContent,
                'summary': _generatedContent.substring(0, _generatedContent.length > 100 ? 100 : _generatedContent.length),
                'audioPath': 'assets/audio/default.mp3', // Default audio path
              };
              print('Adding new podcast: $newPodcast'); // Debugging statement
              widget.onAddPodcast(newPodcast);
              Navigator.pop(context);
            },
          ),
        ],
      ],
    );
  }

Future<void> _fetchEmails() async {
  setState(() {
    _isLoading = true;
    _fetchedEmails = [];
    _generatedContent = '';
  });

  try {
    final emails = await _emailService.fetchEmails(_selectedDomains);
    setState(() {
      _fetchedEmails = emails ?? [];
      _isLoading = false;
    });
  } catch (e) {
    print('Error fetching emails: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to fetch emails. Please try again.')),
    );
    setState(() {
      _isLoading = false;
    });
  }
}

Future<void> _generatePodcast() async {
  setState(() {
    _isLoading = true;
    _generatedContent = '';
  });

  try {
    final emailData = _fetchedEmails.map((email) {
      return {
        'subject': email['subject'] ?? '',
        'sender': email['from'] ?? '', // Changed from 'sender' to 'from' to match EmailService
        'body': email['body'] ?? '',
        'urls': (email['urls'] as List<String>?)?.join(', ') ?? '', // Added URLs
      };
    }).toList();

    final prompt = emailSummaryPrompt.replaceFirst(
      '{Placeholder for raw email data}',
      emailData.toString()
    );

    final generatedContent = await _vertexAIService.generateContent(prompt);
    setState(() {
      _generatedContent = generatedContent;
      _isLoading = false;
    });
  } catch (e) {
    print('Error generating podcast: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to generate podcast. Please try again.')),
    );
    setState(() {
      _isLoading = false;
    });
  }
}}