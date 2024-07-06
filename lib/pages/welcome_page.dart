import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class WelcomePage extends StatefulWidget {
  final VoidCallback onGetStarted;

  const WelcomePage({Key? key, required this.onGetStarted}) : super(key: key);

  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
  }

  Future<void> _loadAndPlayAudio() async {
    try {
      print('Loading audio from path: asset:///assets/audio/Josephv2.mp3');
      await _audioPlayer.setAudioSource(AudioSource.uri(Uri.parse("asset:///assets/audio/Josephv2.mp3")));
      await _audioPlayer.play();
    } catch (e) {
      print('Error loading or playing audio: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load or play audio: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

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
                  // App logo or illustration
                  Icon(Icons.podcasts, size: 80, color: Theme.of(context).colorScheme.primary),
                  SizedBox(height: 32),
                  // Headline
                  Text(
                    'Welcome to your Personal Podcast',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  // Supporting text
                  Text.rich(
                    TextSpan(
                      text: 'Turn your weekly ',
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: <TextSpan>[
                        TextSpan(
                          text: 'buildspace',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: ' newsletters into personalized podcasts'),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32),
                  // Call-to-action button
                  ElevatedButton(
                    onPressed: widget.onGetStarted,
                    child: Text('Get Started'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(200, 50),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Play audio button
                  ElevatedButton(
                    onPressed: _loadAndPlayAudio,
                    child: Text('Play Audio'),
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