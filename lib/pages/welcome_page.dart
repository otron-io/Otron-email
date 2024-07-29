//--IMPORTS--
import 'package:flutter/material.dart';
import 'storage_test_page.dart';

//--CLASS--
class WelcomePage extends StatelessWidget {
  final VoidCallback onGetStarted;

  const WelcomePage({Key? key, required this.onGetStarted}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.podcasts, size: 80, color: Theme.of(context).colorScheme.primary),
                  SizedBox(height: 32),
                  Text(
                    'Welcome to Your Personal Podcast Creator',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Transform your favorite newsletters into personalized audio content',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: onGetStarted,
                    child: Text('View My Podcasts'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(200, 50),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => StorageTestPage()),
                      );
                    },
                    child: Text('Test RSS Feed'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(200, 50),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}