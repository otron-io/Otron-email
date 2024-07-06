import 'package:flutter/material.dart';
import 'package:home/pages/podcast_creation_page.dart';
import 'package:home/widgets/podcast_card.dart';

class PodcastListPage extends StatelessWidget {
  final List<Map<String, dynamic>> podcasts;
  final Function(Map<String, dynamic>) onAddPodcast;

  const PodcastListPage({
    Key? key,
    required this.podcasts,
    required this.onAddPodcast,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final activePodcasts = podcasts.where((podcast) => podcast['type'] == 'active').toList();
    final upcomingPodcasts = podcasts.where((podcast) => podcast['type'] == 'upcoming').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Podcasts'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          if (activePodcasts.isNotEmpty) ...[
            Text(
              'Active Podcasts',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: activePodcasts.length,
              itemBuilder: (context, index) => PodcastCard(
                podcast: activePodcasts[index],
                isActive: true,
              ),
            ),
          ],
          if (upcomingPodcasts.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Upcoming Podcasts',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: upcomingPodcasts.length,
              itemBuilder: (context, index) => PodcastCard(
                podcast: upcomingPodcasts[index],
                isActive: false,
                onSetup: () => _navigateToSetupPage(context),
              ),
            ),
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

  void _openPodcastDetails(BuildContext context, Map<String, dynamic> podcast) {
    // Implement podcast details page navigation
  }
}
