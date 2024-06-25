import 'package:flutter/material.dart';

class GeneratedTextDisplay extends StatelessWidget {
  final List<String> streamedContent;

  const GeneratedTextDisplay({Key? key, required this.streamedContent}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: streamedContent.map((chunk) => Text(chunk, style: TextStyle(fontSize: 16))).toList(),
      ),
    );
  }
}