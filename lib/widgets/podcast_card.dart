// --IMPORTS--
import 'package:flutter/material.dart';
import 'package:m3_carousel/m3_carousel.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:home/widgets/audio_player_widget.dart';
import 'package:home/widgets/generated_text_display.dart';

class PodcastCard extends StatefulWidget {
  final Map<String, dynamic> podcast;
  final bool isActive;
  final VoidCallback? onSetup;

  const PodcastCard({
    Key? key,
    required this.podcast,
    required this.isActive,
    this.onSetup,
  }) : super(key: key);

  @override
  _PodcastCardState createState() => _PodcastCardState();
}

class _PodcastCardState extends State<PodcastCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    print('Building PodcastCard, _isExpanded: $_isExpanded'); // Debug print
    final bool isPersonalNewsletter = widget.podcast['title'] == 'Your personal newsletter';

    if (!widget.isActive) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        elevation: 0,
        color: Theme.of(context).colorScheme.surfaceVariant,
        child: ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage('https://ibb.co/xHhxjms'),
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
          trailing: isPersonalNewsletter
              ? FilledButton(
                  onPressed: widget.onSetup ?? () {
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
      elevation: 0,
      child: ExpansionPanelList(
        elevation: 0,
        expandedHeaderPadding: EdgeInsets.zero,
        expansionCallback: (int index, bool isExpanded) {
          print('ExpansionCallback called: index=$index, isExpanded=$isExpanded'); // Debug print
          setState(() {
            _isExpanded = !_isExpanded; // Toggle the state directly
          });
          print('_isExpanded after setState: $_isExpanded'); // Debug print
        },
        children: [
          ExpansionPanel(
            headerBuilder: (BuildContext context, bool isExpanded) {
              return ListTile(
                leading: Hero(
                  tag: 'podcast-${widget.podcast['id']}',
                  child: CircleAvatar(
                    backgroundImage: NetworkImage('https://ibb.co/xHhxjms'),
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
                  AudioPlayerWidget(
                    audioPath: widget.podcast['audioPath'] ?? '',
                  ),
                  const SizedBox(height: 16),
                  // Comment out the image-related code
                  if (widget.podcast['images'] != null && widget.podcast['images'].isNotEmpty)
                    SizedBox(
                      height: 200,
                      child: M3Carousel(
                        visible: 1,
                        borderRadius: 20,
                        slideAnimationDuration: 500,
                        titleFadeAnimationDuration: 300,
                        childClick: (int index) {
                          print("Clicked image $index");
                        },
                        children: widget.podcast['images'].map<Map<String, String>>((imageUrl) {
                          return {
                            "image": imageUrl,
                            "title": "", // You can add a title if needed
                          };
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 16),
                  GeneratedTextDisplay(
                    streamedContent: [widget.podcast['content'] ?? 'No content available'],
                  ),
                  const SizedBox(height: 16),
                  if (widget.podcast['extractedUrls'] != null &&
                      (widget.podcast['extractedUrls'] as List).isNotEmpty) ...[
                    Text(
                      'Related Links',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    ...(widget.podcast['extractedUrls'] as List<Map<String, String>>).map((urlData) =>
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: TextButton(
                          onPressed: () => _launchUrl(urlData['url']!),
                          child: Text(
                            urlData['description']!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
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

  Future<void> _launchUrl(String urlString) async {
    final Uri? url = Uri.tryParse(urlString);
    if (url != null) {
      try {
        if (kIsWeb) {
          await url_launcher.launchUrl(
            url,
            mode: url_launcher.LaunchMode.externalApplication,
          );
        } else {
          if (await url_launcher.canLaunchUrl(url)) {
            await url_launcher.launchUrl(url);
          } else {
            throw 'Could not launch $url';
          }
        }
      } catch (e) {
        print('Error launching URL: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open the link')),
        );
      }
    } else {
      print('Invalid URL: $urlString');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid link')),
      );
    }
  }
}