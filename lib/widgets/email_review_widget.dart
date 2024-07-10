import 'package:flutter/material.dart';
import 'package:home/widgets/email_list.dart';

class EmailReviewWidget extends StatelessWidget {
  final bool isLoading;
  final List<Map<String, dynamic>> fetchedEmails;
  final VoidCallback onFetchEmails;

  const EmailReviewWidget({
    Key? key,
    required this.isLoading,
    required this.fetchedEmails,
    required this.onFetchEmails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilledButton.icon(
          icon: Icon(Icons.refresh),
          label: Text('Fetch Emails'),
          onPressed: onFetchEmails,
        ),
        SizedBox(height: 16),
        if (isLoading)
          CircularProgressIndicator()
        else if (fetchedEmails.isNotEmpty)
          EmailList(emails: fetchedEmails)
        else
          Text('No emails fetched yet. Click "Fetch Emails" to load emails.'),
      ],
    );
  }
}