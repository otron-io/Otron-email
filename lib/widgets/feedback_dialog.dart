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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Feedback',
              style: Theme.of(context).textTheme.headline6,
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Your Feedback (Required)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 3,
              onChanged: (value) => feedback = value,
            ),
            SizedBox(height: 16),
            Text('How satisfied are you?', style: Theme.of(context).textTheme.subtitle1),
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
            CheckboxListTile(
              title: Text('Include Podcast Content'),
              value: includePodcast,
              onChanged: (bool? value) {
                setState(() {
                  includePodcast = value ?? false;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                labelText: 'Your Email (Optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) => email = value,
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    widget.onSubmitFeedback(feedback, satisfaction, includePodcast, email);
                    Navigator.of(context).pop();
                  },
                  child: Text('Submit'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}