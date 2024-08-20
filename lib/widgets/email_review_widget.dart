import 'package:flutter/material.dart';
import 'package:home/widgets/email_list.dart';
import 'package:home/services/email_service.dart';

class EmailReviewWidget extends StatelessWidget {
  final List<Map<String, dynamic>> emails;
  final EmailService emailService;
  final Duration fetchDuration;
  final VoidCallback onRefresh;

  const EmailReviewWidget({
    Key? key,
    required this.emails,
    required this.emailService,
    required this.fetchDuration,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      child: emails.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('No emails fetched.'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: onRefresh,
                    child: Text('Refresh'),
                  ),
                ],
              ),
            )
          : EmailList(
              emails: emails,
              emailService: emailService,
              fetchDuration: fetchDuration,
            ),
    );
  }
}