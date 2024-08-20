import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home/services/email_service.dart';
import 'package:html/parser.dart' as htmlparser;
import 'dart:convert';
import 'package:home/prompt.dart';
import 'dart:async';
import 'package:flutter/scheduler.dart';

class EmailList extends StatefulWidget {
  final List<Map<String, dynamic>> emails;
  final EmailService emailService;
  final Duration fetchDuration;

  const EmailList({
    Key? key,
    required this.emails,
    required this.emailService,
    required this.fetchDuration,
  }) : super(key: key);

  @override
  _EmailListState createState() => _EmailListState();
}

class _EmailListState extends State<EmailList> {
  static const int _pageSize = 20;
  int _currentPage = 0;
  List<Map<String, dynamic>> _displayedEmails = [];

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _loadMoreEmails();
    });
  }

  void _loadMoreEmails() {
    setState(() {
      final start = _currentPage * _pageSize;
      final end = (start + _pageSize).clamp(0, widget.emails.length);
      _displayedEmails.addAll(widget.emails.sublist(start, end));
      _currentPage++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fullPrompt = _generateFullPrompt();
    final wordCount = _countWords(fullPrompt);

    return Column(
      children: [
        _buildStatistics(context, wordCount),
        ElevatedButton(
          onPressed: () => _copyPromptToClipboard(context, fullPrompt),
          child: Text('Copy Prompt with Emails'),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _displayedEmails.length + 1,
            itemBuilder: (context, index) {
              if (index == _displayedEmails.length) {
                if (_displayedEmails.length < widget.emails.length) {
                  SchedulerBinding.instance.addPostFrameCallback((_) {
                    _loadMoreEmails();
                  });
                  return Center(child: CircularProgressIndicator());
                } else {
                  return SizedBox.shrink();
                }
              }
              return _buildEmailListItem(context, _displayedEmails[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatistics(BuildContext context, int wordCount) {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Prompt Statistics:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 8),
          Text('Number of emails: ${widget.emails.length}'),
          Text('Total word count: $wordCount'),
          Text('Fetch duration: ${widget.fetchDuration.inSeconds} seconds'),
        ],
      ),
    );
  }

  String _generateFullPrompt() {
    final emailData = widget.emails.map((email) => {
      'subject': email['subject'],
      'sender': email['from'],
      'body': _cleanEmailContent(email['body']),
    }).toList();

    return efficientDailyEmailSummaryPrompt.replaceAll(
      '{Placeholder for raw email data}',
      jsonEncode(emailData)
    );
  }

  int _countWords(String text) {
    return text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
  }

  Future<void> _copyPromptToClipboard(BuildContext context, String fullPrompt) async {
    try {
      await Clipboard.setData(ClipboardData(text: fullPrompt));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Full prompt copied to clipboard')),
      );
    } catch (e) {
      print('Error copying to clipboard: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to copy full prompt. The data might be too large.')),
      );
    }
  }

  String _cleanEmailContent(String htmlContent) {
    final document = htmlparser.parse(htmlContent);
    String textContent = document.body?.text ?? '';
    
    textContent = textContent
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'[-—=_]{3,}'), '')
      .replaceAll(RegExp(r'https?://\S+'), '')
      .replaceAll(RegExp(r'\S+@\S+'), '')
      .replaceAll(RegExp(r'[^\w\s.,!?]'), '')
      .trim();
    
    return textContent.length > 2000 ? textContent.substring(0, 1997) + '...' : textContent;
  }

  Widget _buildEmailListItem(BuildContext context, Map<String, dynamic> email) {
    return ExpansionTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Text(
          email['from']?.substring(0, 1).toUpperCase() ?? '?',
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        ),
      ),
      title: Text(
        email['subject'] ?? 'No Subject',
        style: Theme.of(context).textTheme.titleMedium,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        email['from'] ?? 'Unknown',
        style: Theme.of(context).textTheme.bodyMedium,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Content:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                _cleanEmailContent(email['body'] ?? 'No content'),
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 10,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}