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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          icon: Icon(Icons.refresh),
          label: Text('Fetch Emails'),
          onPressed: onFetchEmails,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        SizedBox(height: 16),
        if (isLoading)
          Center(child: CircularProgressIndicator())
        else if (fetchedEmails.isNotEmpty)
          Expanded(
            child: Container(
              height: 300, // Provide a fixed height or use Expanded
              child: EmailList(emails: fetchedEmails),
            ),
          )
        else
          Center(
            child: Text(
              'No emails fetched yet.\nClick "Fetch Emails" to load emails.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
      ],
    );
  }
}