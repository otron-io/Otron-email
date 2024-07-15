import 'package:flutter/material.dart';
import 'package:home/widgets/audio_player_widget.dart';
import 'package:home/widgets/access_request_dialog.dart'; // Add this import

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
            AudioPlayerWidget(audioData: generatedPodcast!['audioData']),
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
      barrierDismissible: true, // Allow dismissing by tapping outside
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false, // Prevent closing with back button
          child: AccessRequestDialog(),
        );
      },
    );
  }
}