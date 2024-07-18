// --IMPORTS--
import 'package:flutter/material.dart';
import 'package:m3_carousel/m3_carousel.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:home/widgets/offline_audio_player.dart';
import 'package:home/widgets/audio_player_widget.dart';
import 'package:home/widgets/generated_text_display.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_analytics/firebase_analytics.dart';

class PodcastCard extends StatefulWidget {
  final Map<String, dynamic> podcast;
  final bool isActive;
  final VoidCallback? onSetup;
  final VoidCallback? onTap;
  final VoidCallback? onStreamAudio;
  final bool initiallyExpanded;

  const PodcastCard({
    Key? key,
    required this.podcast,
    required this.isActive,
    this.onSetup,
    this.onTap,
    this.onStreamAudio,
    this.initiallyExpanded = false,
  }) : super(key: key);

  @override
  _PodcastCardState createState() => _PodcastCardState();
}

class _PodcastCardState extends State<PodcastCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  void _logPlayedPodcastEvent() async {
    await FirebaseAnalytics.instance.logEvent(
      name: 'played_podcast',
      parameters: {
        'podcast_title': widget.podcast['title'] ?? 'Unknown',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isPersonalNewsletter = widget.podcast['title'] == 'Your personal podcast';
    final String heroTag = 'podcast-${widget.podcast['title']}';

    // Widget for inactive podcasts
    if (!widget.isActive) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        elevation: 0,
        color: Theme.of(context).colorScheme.surfaceVariant,
        child: ListTile(
          leading: Hero(
            tag: heroTag,
            child: CircleAvatar(
              backgroundImage: NetworkImage('https://i.ibb.co/xHhxjms/podcast-icon.png'),
              radius: 25,
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
            ),
          ),
          title: Text(
            widget.podcast['title'] ?? 'No Title',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Text(
            widget.podcast['summary'] ?? 'No Summary',
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: isPersonalNewsletter ? FilledButton(
            onPressed: widget.onSetup,
            child: Text('Set up'),
          ) : null,
        ),
      );
    }

    // Widget for active podcasts
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 0,
      child: ExpansionPanelList(
        elevation: 0,
        expandedHeaderPadding: EdgeInsets.zero,
        expansionCallback: (int index, bool isExpanded) {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        children: [
          ExpansionPanel(
            headerBuilder: (BuildContext context, bool isExpanded) {
              return ListTile(
                leading: Hero(
                  tag: heroTag,
                  child: CircleAvatar(
                    backgroundImage: NetworkImage('https://i.ibb.co/xHhxjms/podcast-icon.png'),
                    radius: 25,
                  ),
                ),
                title: Text(
                  widget.podcast['title'] ?? 'No Title',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Text(
                  widget.podcast['summary'] ?? 'No Summary',
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.podcast['audioPath'] != null)
                    OfflineAudioPlayer(audioPath: 'assets/${widget.podcast['audioPath']}')
                  else if (widget.podcast['audioData'] != null)
                    AudioPlayerWidget(
                      audioData: widget.podcast['audioData'],
                      onPlayPressed: _logPlayedPodcastEvent,
                    )
                  else
                    Text('No audio available', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  Text(
                    widget.podcast['content'] ?? 'No content available',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  if (widget.podcast['urls'] != null && widget.podcast['urls'] is String) ...[
                    Text(
                      'Related Links',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (widget.podcast['urls'] as String).split(', ').map((url) =>
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
            isExpanded: _isExpanded,
          ),
        ],
      ),
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