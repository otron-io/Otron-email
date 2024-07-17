import 'package:flutter/material.dart';
import 'package:home/widgets/audio_player_widget.dart';
import 'package:home/widgets/access_request_dialog.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class GenerateSampleWidget extends StatelessWidget {
  final bool isLoading;
  final String loadingMessage;
  final Map<String, dynamic>? generatedPodcast;
  final Function(dynamic) onStreamAudio;

  const GenerateSampleWidget({
    Key? key,
    required this.isLoading,
    required this.loadingMessage,
    required this.generatedPodcast,
    required this.onStreamAudio,
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
    if (isLoading) {
      return Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(loadingMessage),
        ],
      );
    } else if (generatedPodcast != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            generatedPodcast!['title'],
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 8),
          Text(
            generatedPodcast!['subtitle'],
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: 16),
          if (generatedPodcast!['audioData'] != null)
            AudioPlayerWidget(
              audioData: generatedPodcast!['audioData'],
              onPlayPressed: _logPlayedSampleEvent,
            ),
          SizedBox(height: 16),
          Text(
            generatedPodcast!['content'],
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _showAccessRequestDialog(context),
            child: Text('Request Access'),
          ),
        ],
      );
    } else {
      return Text('No sample generated yet.');
    }
  }

  void _showAccessRequestDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AccessRequestDialog();
      },
    );
  }
}