//--IMPORTS--
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';

//--CLASS--
class WelcomePage extends StatefulWidget {
  final VoidCallback onGetStarted;

  const WelcomePage({Key? key, required this.onGetStarted}) : super(key: key);

  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  AudioPlayer audioPlayer = AudioPlayer();
  bool _isGeneratingAudio = false;

  Future<void> _generateAudio() async {
    setState(() {
      _isGeneratingAudio = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://tts-2ghwz42v7q-uc.a.run.app'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'text': 'Welcome to your personal podcast creator. Let\'s transform your favorite content into audio!',
          'service': 'openai'
        }),
      );

      if (response.statusCode == 200) {
        // Play the audio
        await audioPlayer.play(BytesSource(response.bodyBytes));
      } else {
        throw Exception('Failed to generate audio');
      }
    } catch (e) {
      print('Error generating audio: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate audio: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isGeneratingAudio = false;
      });
    }
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
                    onPressed: widget.onGetStarted,
                    child: Text('View My Podcasts'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(200, 50),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isGeneratingAudio ? null : _generateAudio,
                    child: Text('Generate Audio'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(200, 50),
                    ),
                  ),
                  SizedBox(height: 16),
                  if (_isGeneratingAudio)
                    CircularProgressIndicator(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }
}