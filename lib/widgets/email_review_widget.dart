import 'package:flutter/material.dart';
import 'package:home/widgets/email_list.dart';
import 'package:home/services/email_service.dart';

class EmailReviewWidget extends StatelessWidget {
  final List<Map<String, dynamic>> emails;
  final EmailService emailService;
  final Duration fetchDuration;
  final Function onRefresh;
  final String selectedLanguage; // Add this line

  const EmailReviewWidget({
    Key? key,
    required this.emails,
    required this.emailService,
    required this.fetchDuration,
    required this.onRefresh,
    required this.selectedLanguage, // Add this line
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmailList(
      emails: emails,
      emailService: emailService,
      fetchDuration: fetchDuration,
      selectedLanguage: selectedLanguage, // Add this line
    );
  }
}