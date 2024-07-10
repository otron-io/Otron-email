import 'package:flutter/material.dart';

class FeedbackDialog extends StatefulWidget {
  final Function(String, int, bool, String) onSubmitFeedback;
  final Map<String, dynamic>? generatedPodcast;

  const FeedbackDialog({
    Key? key,
    required this.onSubmitFeedback,
    required this.generatedPodcast,
  }) : super(key: key);

  @override
  _FeedbackDialogState createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  String feedback = '';
  bool includePodcast = false;
  String email = '';
  int satisfaction = 3;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Feedback'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Your Feedback (Required)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) => feedback = value,
            ),
            SizedBox(height: 16),
            Text('How satisfied are you? (Required)'),
            Slider(
              value: satisfaction.toDouble(),
              min: 0,
              max: 5,
              divisions: 5,
              label: satisfaction.toString(),
              onChanged: (double value) {
                setState(() {
                  satisfaction = value.round();
                });
              },
            ),
            SizedBox(height: 16),
            CheckboxListTile(
              title: Text('Include Podcast Content'),
              value: includePodcast,
              onChanged: (bool? value) {
                setState(() {
                  includePodcast = value ?? false;
                });
              },
            ),
            TextField(
              decoration: InputDecoration(
                labelText: 'Your Email (Optional)',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => email = value,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSubmitFeedback(feedback, satisfaction, includePodcast, email);
            Navigator.of(context).pop();
          },
          child: Text('Submit'),
        ),
      ],
    );
  }
}
