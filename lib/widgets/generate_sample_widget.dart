import 'package:flutter/material.dart';
import 'package:home/widgets/podcast_card.dart';

class GenerateSampleWidget extends StatelessWidget {
  final bool isLoading;
  final Map<String, dynamic>? generatedPodcast;
  final VoidCallback onGenerateSample;
  final VoidCallback onShowFeedbackDialog;

  const GenerateSampleWidget({
    Key? key,
    required this.isLoading,
    required this.generatedPodcast,
    required this.onGenerateSample,
    required this.onShowFeedbackDialog,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Generate a sample podcast from the last seven days',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: onGenerateSample,
          child: Text('Generate Sample'),
        ),
        SizedBox(height: 16),
        if (isLoading)
          CircularProgressIndicator()
        else if (generatedPodcast != null)
          Column(
            children: [
              PodcastCard(
                podcast: generatedPodcast!,
                isActive: true,
                onSetup: () {},
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: onShowFeedbackDialog,
                child: Text('Submit Feedback'),
              ),
            ],
          ),
      ],
    );
  }
}