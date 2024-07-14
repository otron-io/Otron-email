// --IMPORTS--
import 'package:flutter/material.dart';
import 'package:m3_carousel/m3_carousel.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:home/widgets/audio_player_widget.dart';
import 'package:home/widgets/generated_text_display.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';

class PodcastCard extends StatefulWidget {
  final Map<String, dynamic> podcast;
  final bool isActive;
  final VoidCallback? onSetup;
  final VoidCallback? onStreamAudio;
  final bool initiallyExpanded; // Add this line

  const PodcastCard({
    Key? key,
    required this.podcast,
    required this.isActive,
    this.onSetup,
    this.onStreamAudio,
    this.initiallyExpanded = false, // Add this line
  }) : super(key: key);

  @override
  _PodcastCardState createState() => _PodcastCardState();
}

class _PodcastCardState extends State<PodcastCard> {
  late bool _isExpanded;
  Uint8List? _audioData;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded; // Add this line
    _loadAudioSource();
  }

  @override
  void didUpdateWidget(PodcastCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.podcast['audioPath'] != oldWidget.podcast['audioPath']) {
      _loadAudioSource();
    }
  }

  // Method to load audio source from a given path
  Future<void> _loadAudioSource() async {
    if (widget.podcast['audioPath'] is String) {
      // Load audio from file path
      final response = await http.get(Uri.parse(widget.podcast['audioPath']));
      if (response.statusCode == 200) {
        setState(() {
          _audioData = response.bodyBytes;
        });
      }
    } else if (widget.podcast['audioPath'] is Uint8List) {
      setState(() {
        _audioData = widget.podcast['audioPath'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isPersonalNewsletter = widget.podcast['title'] == 'Your personal newsletter';

    // Widget for inactive podcasts
    if (!widget.isActive) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        elevation: 0,
        color: Theme.of(context).colorScheme.surfaceVariant,
        child: ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage('https://i.ibb.co/xHhxjms/podcast-icon.png'),
            radius: 25,
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
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
                leading: CircleAvatar(
                  backgroundImage: NetworkImage('https://i.ibb.co/xHhxjms/podcast-icon.png'),
                  radius: 25,
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
                    // Display audio player if audio path is available
                    AudioPlayerWidget(audioSource: widget.podcast['audioPath'])
                  else if (widget.onStreamAudio != null)
                    // Display button to generate audio if no audio path is available
                    ElevatedButton(
                      onPressed: widget.onStreamAudio,
                      child: Text('Generate Audio'),
                    ),
                  const SizedBox(height: 16),
                  // Display podcast content
                  Text(
                    widget.podcast['content'] ?? 'No content available',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  if (widget.podcast['urls'] != null) ...[
                    // Display related links if available
                    Text(
                      'Related Links',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    ...widget.podcast['urls'].split(', ').map((url) =>
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: TextButton(
                          onPressed: () => _launchUrl(url),
                          child: Text(
                            url,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
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

  // Method to launch URL in the browser
  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await url_launcher.canLaunchUrl(url)) {
      await url_launcher.launchUrl(url);
    } else {
      throw 'Could not launch $urlString';
    }
  }
}