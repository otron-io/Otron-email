import 'package:flutter/material.dart';
import 'package:home/theme/colors.dart'; // Import the color palette

class GeneratedTextDisplay extends StatelessWidget {
  final List<String> streamedContent;

  const GeneratedTextDisplay({Key? key, required this.streamedContent}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 800),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.background,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your podcast',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16),
          Container(
            height: 300, // Adjust this value as needed
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: streamedContent.map((chunk) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    chunk,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                )).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}