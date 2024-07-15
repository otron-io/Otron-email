import 'package:flutter/material.dart';
import 'package:home/widgets/offline_audio_player.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class ActivePodcastPlayer extends StatelessWidget {
  final Map<String, dynamic> podcast;

  const ActivePodcastPlayer({Key? key, required this.podcast}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              podcast['title'] ?? 'No Title',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              podcast['summary'] ?? 'No Summary',
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            if (podcast['audioPath'] != null)
              OfflineAudioPlayer(audioPath: 'assets/${podcast['audioPath']}')
            else
              Text('No audio available', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            if (podcast['urls'] != null && podcast['urls'] is String) ...[
              const SizedBox(height: 16),
              Text(
                'Related Links',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (podcast['urls'] as String).split(', ').map((url) =>
                  ElevatedButton(
                    onPressed: () => _launchUrl(url),
                    child: Text(
                      _truncateUrl(url),
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: TextStyle(fontSize: 12),
                    ),
                  ),
                ).toList(),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showFullContent(context),
              icon: Icon(Icons.article),
              label: Text('View Full Content'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 40),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullContent(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: double.maxFinite,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    podcast['title'] ?? 'No Title',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            podcast['content'] ?? 'No content available',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          SizedBox(height: 16),
                          if (podcast['urls'] != null && podcast['urls'] is String) ...[
                            Text(
                              'Related Links',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: (podcast['urls'] as String).split(', ').map((url) =>
                                ElevatedButton(
                                  onPressed: () => _launchUrl(url),
                                  child: Text(
                                    _truncateUrl(url),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    textStyle: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _truncateUrl(String url) {
    Uri uri = Uri.parse(url);
    String displayUrl = uri.host + uri.path;
    return displayUrl.length > 20 ? displayUrl.substring(0, 20) + '...' : displayUrl;
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await url_launcher.canLaunchUrl(url)) {
      await url_launcher.launchUrl(url);
    } else {
      throw 'Could not launch $urlString';
    }
  }
}