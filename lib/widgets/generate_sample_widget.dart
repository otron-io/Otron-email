import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class GenerateSampleWidget extends StatelessWidget {
  final bool isLoading;
  final String loadingMessage;
  final Map<String, dynamic>? generatedPodcast;
  final String generationDuration;

  const GenerateSampleWidget({
    Key? key,
    required this.isLoading,
    required this.loadingMessage,
    required this.generatedPodcast,
    required this.generationDuration,
  }) : super(key: key);

  void _logPlayedSampleEvent() async {
    await FirebaseAnalytics.instance.logEvent(
      name: 'played_sample',
      parameters: {
        'podcast_title': generatedPodcast?['title'] ?? 'Unknown',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLoading)
            Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(loadingMessage),
                Text('Duration: $generationDuration'),
              ],
            )
          else if (generatedPodcast != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  generatedPodcast!['title'] ?? 'No Title',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(height: 8),
                Text(
                  generatedPodcast!['subtitle'] ?? 'No Subtitle',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: 16),
                Text(
                  'Summary:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SelectableText(
                  generatedPodcast!['summary'] ?? 'No summary available',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: 16),
                Text(
                  'Description:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SelectableText(
                  generatedPodcast!['description'] ?? 'No description available',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: 16),
                Text('Generation time: $generationDuration'),
              ],
            )
          else
            Text('Failed to generate sample. Please try again.'),
        ],
      ),
    );
  }
}