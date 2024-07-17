import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerWidget extends StatefulWidget {
  final Uint8List audioData;
  final VoidCallback onPlayPressed;

  const AudioPlayerWidget({
    Key? key,
    required this.audioData,
    required this.onPlayPressed,
  }) : super(key: key);

  @override
  _AudioPlayerWidgetState createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _playbackRate = 1.25;
  double _progress = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _setupAudioPlayer();
    _initAudioPlayer();
  }

  void _setupAudioPlayer() {
    _audioPlayer.playerStateStream.listen((state) {
      setState(() {
        _isPlaying = state.playing;
        if (state.processingState == ProcessingState.completed) {
          _progress = 1.0;
        }
      });
    });
    _audioPlayer.durationStream.listen((newDuration) {
      setState(() {
        _duration = newDuration ?? Duration.zero;
      });
    });
    _audioPlayer.positionStream.listen((newPosition) {
      setState(() {
        _position = newPosition;
        _progress = _position.inSeconds / (_duration.inSeconds == 0 ? 1 : _duration.inSeconds);
      });
    });
  }

  void _initAudioPlayer() async {
    try {
      await _audioPlayer.setAudioSource(
        MyCustomSource(widget.audioData),
      );
      await _audioPlayer.setSpeed(_playbackRate);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing audio player: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      if (_position >= _duration) {
        await _audioPlayer.seek(Duration.zero);
      }
      await _audioPlayer.play();
      widget.onPlayPressed();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    return Container(
      constraints: BoxConstraints(maxWidth: 600),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.onSurface.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(_position), style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface)),
              Text(_formatDuration(_duration), style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface)),
            ],
          ),
          LinearProgressIndicator(value: _progress),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.replay_10, color: theme.colorScheme.primary, size: 20),
                onPressed: () {
                  _audioPlayer.seek(_position - Duration(seconds: 10));
                },
              ),
              SizedBox(width: 8),
              FloatingActionButton(
                mini: true,
                backgroundColor: theme.colorScheme.primary,
                child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: theme.colorScheme.onPrimary, size: 20),
                onPressed: _togglePlayPause,
              ),
              SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.forward_10, color: theme.colorScheme.primary, size: 20),
                onPressed: () {
                  _audioPlayer.seek(_position + Duration(seconds: 10));
                },
              ),
              SizedBox(width: 16),
              DropdownButton<double>(
                value: _playbackRate,
                items: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((rate) {
                  return DropdownMenuItem(
                    value: rate,
                    child: Text("${rate}x", style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _playbackRate = value!;
                    _audioPlayer.setSpeed(_playbackRate);
                  });
                },
                style: TextStyle(color: theme.colorScheme.primary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}

class MyCustomSource extends StreamAudioSource {
  final Uint8List _audioData;

  MyCustomSource(this._audioData);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= _audioData.length;
    return StreamAudioResponse(
      sourceLength: _audioData.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(_audioData.sublist(start, end)),
      contentType: 'audio/mpeg',
    );
  }
}