import 'package:flutter/material.dart';
import 'package:home/pages/customer_page.dart';
import 'package:home/pages/podcast_creation_page.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/':
      return MaterialPageRoute(builder: (_) => CustomerPage());
    case '/admin':
      return MaterialPageRoute(builder: (_) => PodcastCreationPage(onAddPodcast: (podcast) {}));
    default:
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          body: Center(
            child: Text('No route defined for ${settings.name}'),
          ),
        ),
      );
  }
}