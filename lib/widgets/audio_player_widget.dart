import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:home/theme/colors.dart'; // Import the color palette

class AudioPlayerWidget extends StatefulWidget {
  final String audioPath;

  const AudioPlayerWidget({
    Key? key,
    required this.audioPath,
  }) : super(key: key);

  @override
  _AudioPlayerWidgetState createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _playbackRate = 1.25; // Set default playback rate to 1.25

  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() async {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      setState(() {
        _duration = newDuration;
      });
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      setState(() {
        _position = newPosition;
      });
    });

    await _audioPlayer.setSource(AssetSource(widget.audioPath));
    await _audioPlayer.setPlaybackRate(_playbackRate);
    _startPlaying(); // Start playing after setting the source and playback rate
  }

  Future<void> _startPlaying() async {
    print('Starting playback at $_playbackRate speed');
    await _audioPlayer.resume();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 800),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: Color(0xFFE0E0E0),
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withOpacity(0.2),
            ),
            child: Slider(
              value: _position.inSeconds.toDouble(),
              min: 0,
              max: _duration.inSeconds.toDouble(),
              onChanged: (value) {
                final position = Duration(seconds: value.toInt());
                _audioPlayer.seek(position);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(_position), style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                Text(_formatDuration(_duration), style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
              ],
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.replay_10, color: AppColors.primary),
                onPressed: () {
                  _audioPlayer.seek(_position - Duration(seconds: 10));
                },
              ),
              SizedBox(width: 16),
              FloatingActionButton(
                backgroundColor: AppColors.primary,
                child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                onPressed: _togglePlayPause,
              ),
              SizedBox(width: 16),
              IconButton(
                icon: Icon(Icons.forward_10, color: AppColors.primary),
                onPressed: () {
                  _audioPlayer.seek(_position + Duration(seconds: 10));
                },
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Speed: ", style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
              DropdownButton<double>(
                value: _playbackRate,
                items: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((rate) {
                  return DropdownMenuItem(
                    value: rate,
                    child: Text("${rate}x", style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _playbackRate = value!;
                    _audioPlayer.setPlaybackRate(_playbackRate);
                  });
                },
                style: TextStyle(color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}