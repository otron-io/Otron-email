// --IMPORTS--
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class PlayOfflineFiles extends StatefulWidget {
  final String audioPath;

  const PlayOfflineFiles({Key? key, required this.audioPath}) : super(key: key);

  @override
  _PlayOfflineFilesState createState() => _PlayOfflineFilesState();
}

class _PlayOfflineFilesState extends State<PlayOfflineFiles> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(AssetSource(widget.audioPath));
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _playPause,
      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
      label: Text(_isPlaying ? 'Pause' : 'Play'),
      style: ElevatedButton.styleFrom(
        minimumSize: Size(200, 50),
      ),
    );
  }
}