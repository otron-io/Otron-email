import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:home/widgets/audio_player_widget.dart';
import 'package:home/widgets/generated_text_display.dart';

class PodcastCard extends StatelessWidget {
  final Map<String, String> podcast;
  final bool isActive;
  final VoidCallback? onSetup;

  const PodcastCard({
    Key? key,
    required this.podcast,
    required this.isActive,
    this.onSetup,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isPersonalNewsletter = podcast['title'] == 'Your personal newsletter';

    if (!isActive) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        elevation: 2,
        color: Theme.of(context).colorScheme.surfaceVariant,
        child: ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage('https://ibb.co/xHhxjms'),
            radius: 25,
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          ),
          title: Text(
            podcast['title'] ?? 'No Title',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          subtitle: Text(
            podcast['summary'] ?? 'No Summary',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: isPersonalNewsletter
              ? ElevatedButton(
                  onPressed: onSetup ?? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Coming soon')),
                    );
                  },
                  child: Text('Set up'),
                )
              : null,
        ),
      );
    }

    // For active podcasts
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Hero(
          tag: 'podcast-${podcast['id']}',
          child: CircleAvatar(
            backgroundImage: NetworkImage('https://ibb.co/xHhxjms'),
            radius: 30,
          ),
        ),
        title: Text(
          podcast['title'] ?? 'No Title',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          podcast['summary'] ?? 'No Summary',
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(Icons.play_arrow, color: Theme.of(context).colorScheme.primary),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AudioPlayerWidget(
                  audioPath: podcast['audioPath'] ?? '',
                ),
                const SizedBox(height: 16),
                if (podcast['urls'] != null && podcast['urls']!.isNotEmpty) ...[
                  Text(
                    'Related Links:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...podcast['urls']!.split(', ').map((url) => 
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: InkWell(
                        onTap: () => _launchUrl(url),
                        child: Text(
                          url,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                GeneratedTextDisplay(
                  streamedContent: [podcast['content'] ?? 'No content available'],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    print('Attempting to launch URL: $urlString');
    final Uri? url = Uri.tryParse(urlString);
    if (url != null) {
      try {
        if (kIsWeb) {
          final bool launched = await url_launcher.launchUrl(
            url,
            mode: url_launcher.LaunchMode.externalApplication,
          );
          if (!launched) {
            throw 'Could not launch $url';
          }
        } else {
          if (await url_launcher.canLaunchUrl(url)) {
            await url_launcher.launchUrl(url);
          } else {
            throw 'Could not launch $url';
          }
        }
      } catch (e) {
        print('Error launching URL: $e');
        // You might want to show a snackbar or dialog here to inform the user
      }
    } else {
      print('Invalid URL: $urlString');
      // Handle invalid URL case
    }
  }
}