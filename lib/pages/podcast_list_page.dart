import 'package:flutter/material.dart';
import 'package:home/pages/podcast_creation_page.dart';
import 'package:home/widgets/podcast_card.dart';
import 'package:home/podcasts.dart'; // Import the hardcoded podcasts
import 'package:home/widgets/active_podcasts.dart';

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
    final upcomingPodcasts = podcasts.where((podcast) => podcast['type'] == 'upcoming').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Podcasts'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          if (podcasts.where((podcast) => podcast['type'] == 'active').isNotEmpty) ...[
            Text(
              'Active Podcasts',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            ActivePodcasts(),
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
}