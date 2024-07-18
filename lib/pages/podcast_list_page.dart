import 'package:flutter/material.dart';
import 'package:home/pages/podcast_creation_page.dart';
import 'package:home/widgets/podcast_card.dart';
import 'package:home/podcasts.dart';

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
    final scheduledPodcasts = podcasts.where((podcast) => 
      podcast['type'] == 'upcoming').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Podcasts'),
        centerTitle: true,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Your Own Podcast',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Turn your favorite newsletters into personalized audio content',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => PodcastCreationPage(onAddPodcast: onAddPodcast)),
                            );
                          },
                          icon: Icon(Icons.add),
                          label: Text('Start Creating'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (activePodcasts.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Your Created Podcasts',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => PodcastCard(
                    podcast: activePodcasts[index],
                    isActive: true,
                    onTap: () {
                      // Logic to switch to this podcast
                    },
                    onStreamAudio: () {
                      // Logic to stream audio
                    },
                  ),
                  childCount: activePodcasts.length,
                ),
              ),
            ),
          ],
          if (scheduledPodcasts.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Scheduled Podcasts',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => PodcastCard(
                    podcast: scheduledPodcasts[index],
                    isActive: false,
                    onSetup: () => _navigateToSetupPage(context),
                  ),
                  childCount: scheduledPodcasts.length,
                ),
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