import 'package:flutter/material.dart';
import 'package:home/pages/podcast_creation_page.dart';
import 'package:home/widgets/podcast_card.dart';
import 'package:home/podcasts.dart';
import 'package:home/widgets/active_podcast_player.dart';

class PodcastListPage extends StatelessWidget {
  final Function(Map<String, dynamic>) onAddPodcast;
  final List<Map<String, dynamic>> podcasts;

  const PodcastListPage({
    Key? key,
    required this.onAddPodcast,
    required this.podcasts,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final activePodcasts = podcasts.where((podcast) => 
      podcast['type'] == 'active' && podcast['audioPath'] != null).toList();
    final upcomingPodcasts = podcasts.where((podcast) => 
      podcast['type'] == 'upcoming').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Podcasts'),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          if (activePodcasts.isNotEmpty) ...[
            Text(
              'Now Playing',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ActivePodcastPlayer(podcast: activePodcasts[0]),
            if (activePodcasts.length > 1) ...[
              const SizedBox(height: 24),
              Text(
                'More Active Podcasts',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...activePodcasts.skip(1).map((podcast) => PodcastCard(
                podcast: podcast,
                isActive: true,
                onTap: () {
                  // Logic to switch to this podcast
                },
                onStreamAudio: () {
                  // Logic to stream audio
                },
              )),
            ],
          ],
          if (upcomingPodcasts.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Upcoming Podcasts',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...upcomingPodcasts.map((podcast) => PodcastCard(
              podcast: podcast,
              isActive: false,
              onSetup: () => _navigateToSetupPage(context),
            )),
          ],
        ],
      ),
    );
  }

  void _navigateToSetupPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PodcastCreationPage(onAddPodcast: onAddPodcast)),
    );
  }
}