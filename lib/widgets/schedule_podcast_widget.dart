import 'package:flutter/material.dart';

class SchedulePodcastWidget extends StatelessWidget {
  final String airDay;
  final VoidCallback onSchedulePodcast;

  const SchedulePodcastWidget({
    Key? key,
    required this.airDay,
    required this.onSchedulePodcast,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Schedule Weekly Podcast',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        SizedBox(height: 16),
        Text(
          'This will schedule a weekly podcast to be generated on $airDay.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        SizedBox(height: 16),
        FilledButton.icon(
          icon: Icon(Icons.schedule),
          label: Text('Schedule'),
          onPressed: onSchedulePodcast,
        ),
      ],
    );
  }
}