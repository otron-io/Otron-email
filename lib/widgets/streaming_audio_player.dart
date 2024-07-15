import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class StreamingAudioPlayer extends StatefulWidget {
  final String audioUrl;

  const StreamingAudioPlayer({Key? key, required this.audioUrl}) : super(key: key);

  @override
  _StreamingAudioPlayerState createState() => _StreamingAudioPlayerState();
}

 