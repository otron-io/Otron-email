// --IMPORTS--
import 'package:flutter/material.dart';
import 'package:home/podcasts.dart';
import 'package:home/widgets/offline_audio_player.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class ActivePodcasts extends StatelessWidget {
  const ActivePodcasts({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final activePodcasts = podcasts.where((podcast) => podcast['type'] == 'active').toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: activePodcasts.length,
      itemBuilder: (context, index) => ActivePodcastCard(podcast: activePodcasts[index]),
    );
  }
}

class ActivePodcastCard extends StatefulWidget {
  final Map<String, dynamic> podcast;

  const ActivePodcastCard({Key? key, required this.podcast}) : super(key: key);

  @override
  _ActivePodcastCardState createState() => _ActivePodcastCardState();
}

class _ActivePodcastCardState extends State<ActivePodcastCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
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
                  OfflineAudioPlayer(audioPath: widget.podcast['audioPath']),
                  const SizedBox(height: 16),
                  Text(
                    widget.podcast['content'] ?? 'No content available',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  if (widget.podcast['urls'] != null) ...[
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

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await url_launcher.canLaunchUrl(url)) {
      await url_launcher.launchUrl(url);
    } else {
      throw 'Could not launch $urlString';
    }
  }
}