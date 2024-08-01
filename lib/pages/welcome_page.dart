//--IMPORTS--
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

//--CLASS--
class WelcomePage extends StatefulWidget {
  final VoidCallback onGetStarted;

  const WelcomePage({Key? key, required this.onGetStarted}) : super(key: key);

  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  String? _imageUrl;
  bool _isGeneratingImage = false;

  Future<void> _generateImage() async {
    setState(() {
      _isGeneratingImage = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://generate-image-2ghwz42v7q-uc.a.run.app'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'prompt': 'Generate an image of a podcast'}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        String originalImageUrl = responseData['image_url'];
        
        // Use the proxy_image function to get a proxied URL
        setState(() {
          _imageUrl = 'https://proxy-image-2ghwz42v7q-uc.a.run.app?url=${Uri.encodeComponent(originalImageUrl)}';
        });
      } else {
        throw Exception('Failed to generate image');
      }
    } catch (e) {
      print('Error generating image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate image: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isGeneratingImage = false;
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
                    onPressed: _isGeneratingImage ? null : _generateImage,
                    child: Text('Generate Image'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(200, 50),
                    ),
                  ),
                  SizedBox(height: 16),
                  if (_isGeneratingImage)
                    CircularProgressIndicator()
                  else if (_imageUrl != null)
                    Image.network(
                      _imageUrl!,
                      height: 200,
                      width: 200,
                      fit: BoxFit.cover,
                      loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        print('Error loading image: $error');
                        return Text('Failed to load image');
                      },
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