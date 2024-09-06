import 'package:flutter/material.dart';
import 'package:home/services/email_service.dart';
import 'package:home/services/vertex_ai_service.dart';
import 'package:home/services/user_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:home/utils/storage_utils.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:home/prompt.dart';
import 'dart:math' as math;
import 'package:home/pages/privacy_policy_page.dart';

class CustomerPage extends StatefulWidget {
  @override
  _CustomerPageState createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> with TickerProviderStateMixin {
  final EmailService _emailService = EmailService();
  final VertexAIService _vertexAIService = VertexAIService(language: 'English');
  final UserService _userService = UserService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isLoading = false;
  bool _isTestUser = false;
  String? _audioUrl;
  String? _generatedTitle;
  String? _userEmail;
  bool _showEmailInput = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _adminPasswordController = TextEditingController();

  late AnimationController _animationController;
  late AnimationController _waveformController;
  final List<double> _waveformHeights = List.generate(30, (_) => math.Random().nextDouble());
  int _currentStep = 0;
  final List<String> _steps = ['Checking User', 'Fetching Emails', 'Summarizing Content', 'Generating Audio', 'Preparing Playback'];
  final List<IconData> _stepIcons = [Icons.person, Icons.email, Icons.summarize, Icons.record_voice_over, Icons.playlist_play];
  bool _showWaitlistOption = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _waveformController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _waveformController.dispose();
    _audioPlayer.dispose();
    _emailController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Daily Digest'),
        actions: [
          IconButton(
            icon: Icon(Icons.admin_panel_settings),
            onPressed: _showAdminPasswordDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading)
                  _buildLoadingAnimation()
                else if (!_isTestUser)
                  _buildUserTypeSelection()
                else if (_audioUrl == null)
                  ElevatedButton(
                    onPressed: _processEmailsAndGenerateAudio,
                    child: Text('Generate Daily Digest'),
                  )
                else
                  _buildAudioPlayer(),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 8,
            child: Center(
              child: GestureDetector(
                onTap: _launchPrivacyPolicy,
                child: Text(
                  'Privacy Policy',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeSelection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Welcome to Your Personal Email Digest!',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          Text(
            'Transform your inbox into a personalized audio experience. '
            'Get a daily summary of your most important emails, delivered as a podcast.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: _handleAccessClaim,
            child: Text('I have access'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              backgroundColor: Theme.of(context).primaryColor,
            ),
          ),
          SizedBox(height: 16),
          OutlinedButton(
            onPressed: _showWaitlistDialog,
            child: Text('Get on the waitlist'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
          if (_showWaitlistOption) ...[
            SizedBox(height: 16),
            Text(
              'If you don\'t have access, you can join our waitlist.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _showWaitlistDialog,
              child: Text('Join Waitlist'),
            ),
          ],
          SizedBox(height: 30),
          Text(
            '✓ Daily email summaries\n'
            '✓ Personalized audio digests\n'
            '✓ Time-saving efficiency\n'
            '✓ Stay informed on-the-go',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _handleAccessClaim() {
    // Attempt to authenticate or check access
    _attemptAuthentication();
  }

  void _attemptAuthentication() {
    // Here you would implement the actual authentication logic
    // For this example, we'll simulate a failed authentication
    bool authenticationSuccessful = false;  // Set this based on your actual auth logic

    if (authenticationSuccessful) {
      setState(() {
        _isTestUser = true;
      });
    } else {
      setState(() {
        _showWaitlistOption = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Authentication failed. You can join our waitlist if you don\'t have access.')),
      );
    }
  }

  void _showWaitlistDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Join the Waitlist'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Enter your email to join our waitlist. We\'ll notify you when access becomes available.'),
              SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'Your email',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Join Waitlist'),
              onPressed: () {
                // Here you would implement the logic to add the email to your waitlist
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added to waitlist: ${_emailController.text}')),
                );
                Navigator.of(context).pop();
                _emailController.clear();
                setState(() {
                  _showWaitlistOption = false;
                });
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _processEmailsAndGenerateAudio() async {
    setState(() {
      _isLoading = true;
      _currentStep = 0;
    });
    _animationController.repeat();

    try {
      await _signInAndFetchEmails();
      _updateStep(2);
      await _generateAudio();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      _animationController.stop();
      setState(() => _isLoading = false);
    }
  }

  void _updateStep(int step) {
    setState(() => _currentStep = step);
  }

  Future<void> _signInAndFetchEmails() async {
    bool isSignedIn = await _emailService.isSignedIn();
    if (!isSignedIn) {
      isSignedIn = await _emailService.signIn();
    }
    if (!isSignedIn) {
      throw Exception('Failed to sign in');
    }
  }

  Future<void> _generateAudio() async {
    final now = DateTime.now();
    final today = DateTimeRange(
      start: DateTime(now.year, now.month, now.day),
      end: now,
    );

    final emails = await _emailService.fetchEmails(['*@*'], today, null, (_) {});
    if (emails == null || emails.isEmpty) {
      throw Exception('No emails fetched');
    }

    final emailData = emails.map((email) => {
      'subject': email['subject'],
      'sender': email['from'],
      'body': email['snippet'],
    }).toList();

    final prompt = efficientDailyEmailSummaryPrompt
        .replaceAll('{Placeholder for raw email data}', jsonEncode(emailData))
        .replaceAll('[current date]', now.toString());

    final generatedContent = await _vertexAIService.generateContent(prompt);
    final dateRange = now.toString();
    _generatedTitle = await _vertexAIService.generatePodcastTitle(generatedContent, dateRange);

    _updateStep(3);

    final audioResponse = await http.post(
      Uri.parse('https://tts-2ghwz42v7q-uc.a.run.app'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'text': generatedContent, 'service': 'openai'}),
    );

    if (audioResponse.statusCode == 200) {
      _updateStep(4);
      final fileName = 'audio_summary_${now.millisecondsSinceEpoch}.mp3';
      _audioUrl = await StorageUtils.uploadFile(audioResponse.bodyBytes, 'audio/$fileName');
      await _audioPlayer.setUrl(_audioUrl!);

      await FirebaseAnalytics.instance.logEvent(
        name: 'generated_audio_summary',
        parameters: {
          'title': _generatedTitle,
          'email_count': emails.length,
        },
      );
    } else {
      throw Exception('Failed to generate audio');
    }
  }

  Widget _buildAudioPlayer() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_generatedTitle != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(_generatedTitle!, style: Theme.of(context).textTheme.titleLarge),
          ),
        SizedBox(height: 20),
        _buildWaveform(),
        SizedBox(height: 20),
        StreamBuilder<PlayerState>(
          stream: _audioPlayer.playerStateStream,
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final processingState = playerState?.processingState;
            final playing = playerState?.playing;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.replay_10),
                  iconSize: 40,
                  onPressed: () => _audioPlayer.seek(Duration(seconds: _audioPlayer.position.inSeconds - 10)),
                ),
                SizedBox(width: 20),
                if (processingState == ProcessingState.loading ||
                    processingState == ProcessingState.buffering)
                  Container(
                    margin: EdgeInsets.all(8.0),
                    width: 64.0,
                    height: 64.0,
                    child: CircularProgressIndicator(),
                  )
                else if (playing != true)
                  IconButton(
                    icon: Icon(Icons.play_circle_filled),
                    iconSize: 64.0,
                    onPressed: _audioPlayer.play,
                  )
                else if (processingState != ProcessingState.completed)
                  IconButton(
                    icon: Icon(Icons.pause_circle_filled),
                    iconSize: 64.0,
                    onPressed: _audioPlayer.pause,
                  )
                else
                  IconButton(
                    icon: Icon(Icons.replay_circle_filled),
                    iconSize: 64.0,
                    onPressed: () => _audioPlayer.seek(Duration.zero),
                  ),
                SizedBox(width: 20),
                IconButton(
                  icon: Icon(Icons.forward_10),
                  iconSize: 40,
                  onPressed: () => _audioPlayer.seek(Duration(seconds: _audioPlayer.position.inSeconds + 10)),
                ),
              ],
            );
          },
        ),
        SizedBox(height: 20),
        StreamBuilder<Duration>(
          stream: _audioPlayer.positionStream,
          builder: (context, snapshot) {
            final position = snapshot.data ?? Duration.zero;
            final duration = _audioPlayer.duration ?? Duration.zero;
            return Column(
              children: [
                Slider(
                  value: position.inSeconds.toDouble(),
                  min: 0,
                  max: duration.inSeconds.toDouble(),
                  onChanged: (value) {
                    _audioPlayer.seek(Duration(seconds: value.toInt()));
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(position)),
                      Text(_formatDuration(duration)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildWaveform() {
    return StreamBuilder<PlayerState>(
      stream: _audioPlayer.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final playing = playerState?.playing;
        if (playing == true) {
          _waveformController.repeat(reverse: true);
        } else {
          _waveformController.stop();
        }
        return AnimatedBuilder(
          animation: _waveformController,
          builder: (context, child) {
            return Container(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  30,
                  (index) => _buildWaveformBar(index),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWaveformBar(int index) {
    final height = _waveformHeights[index] * 50 + 10;
    return AnimatedBuilder(
      animation: _waveformController,
      builder: (context, child) {
        final animatedHeight = height * (0.8 + 0.2 * _waveformController.value);
        return Container(
          width: 4,
          height: animatedHeight,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.8),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  Widget _buildLoadingAnimation() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < _steps.length; i++)
          _buildStepIndicator(i),
        SizedBox(height: 20),
        Text(_steps[_currentStep], style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }

  Widget _buildStepIndicator(int step) {
    bool isCompleted = step < _currentStep;
    bool isCurrent = step == _currentStep;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _stepIcons[step],
            color: isCompleted ? Colors.green : (isCurrent ? Colors.blue : Colors.grey),
            size: 24,
          ),
          SizedBox(width: 8),
          if (isCurrent)
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: _animationController.drive(
                  ColorTween(begin: Colors.blue, end: Colors.green),
                ),
              ),
            )
          else
            Icon(
              isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isCompleted ? Colors.green : Colors.grey,
              size: 24,
            ),
        ],
      ),
    );
  }

  void _showAdminPasswordDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Admin Access'),
          content: TextField(
            controller: _adminPasswordController,
            obscureText: true,
            decoration: InputDecoration(hintText: "Enter password"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Submit'),
              onPressed: () {
                if (_adminPasswordController.text == 'admin') {
                  Navigator.of(context).pop();
                  Navigator.pushNamed(context, '/admin');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Incorrect password')),
                  );
                }
                _adminPasswordController.clear();
              },
            ),
          ],
        );
      },
    );
  }

  void _launchPrivacyPolicy() {
    Navigator.of(context).pushNamed('/privacy-policy');
  }
}