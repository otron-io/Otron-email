
// --IMPORTS--
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home/widgets/podcast_card.dart';

class GenerateSampleWidget extends StatelessWidget {
  final bool isLoading;
  final String loadingMessage;
  final Map<String, dynamic>? generatedPodcast;
  final Function(String) onStreamAudio;
  final VoidCallback onShowFeedbackDialog;

  const GenerateSampleWidget({
    Key? key,
    required this.isLoading,
    required this.loadingMessage,
    required this.generatedPodcast,
    required this.onStreamAudio,
    required this.onShowFeedbackDialog,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingIndicator(context);
    } else if (generatedPodcast != null) {
      return _buildPodcastCard(context);
    }
    return SizedBox.shrink();
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text(
          loadingMessage,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildPodcastCard(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PodcastCard(
              podcast: generatedPodcast!,
              isActive: true,
              onStreamAudio: () => onStreamAudio(generatedPodcast!['content']),
              initiallyExpanded: true,
            ),
            SizedBox(height: 16),
            _buildCopyContentButton(context),
            SizedBox(height: 16),
            _buildFeedbackButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCopyContentButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _copyContentToClipboard(context),
      icon: Icon(Icons.copy),
      label: Text('Copy Content'),
    );
  }

  void _copyContentToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: generatedPodcast!['content']));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Content copied to clipboard')),
    );
  }

  Widget _buildFeedbackButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onShowFeedbackDialog,
      icon: Icon(Icons.feedback),
      label: Text('Submit Feedback'),
    );
  }
}