import 'package:flutter/material.dart';
import 'package:home/widgets/email_list.dart';
import 'package:home/services/email_service.dart';

class EmailReviewWidget extends StatelessWidget {
  final List<Map<String, dynamic>> emails;
  final EmailService emailService;
  final Duration fetchDuration;

  const EmailReviewWidget({
    Key? key,
    required this.emails,
    required this.emailService,
    required this.fetchDuration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      child: emails.isEmpty
          ? Center(child: Text('No emails fetched. Please try again.'))
          : EmailList(
              emails: emails,
              emailService: emailService,
              fetchDuration: fetchDuration,
            ),
    );
  }
}