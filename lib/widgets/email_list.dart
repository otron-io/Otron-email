import 'package:flutter/material.dart';
import 'package:home/theme/colors.dart'; // Import the color palette
import 'package:home/widgets/custom_tooltip.dart'; // Import the custom tooltip

class EmailList extends StatelessWidget {
  final List<Map<String, String>> emails;

  const EmailList({Key? key, required this.emails}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 800),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Emails',
              style: Theme.of(context).textTheme.headlineMedium, // Use theme text style
            ),
          ),
          Container(
            height: 400, // Fixed height, adjust as needed
            child: ListView.builder(
              itemCount: emails.length,
              itemBuilder: (context, index) {
                final email = emails[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            email['from']?.substring(0, 1).toUpperCase() ?? '?',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                email['from'] ?? 'Unknown',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4),
                              Container(
                                constraints: BoxConstraints(maxWidth: 200), // Constrain width
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Text(
                                    email['subject'] ?? 'No Subject',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: Text(
                            email['date'] ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.secondary,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        SizedBox(width: 16),
                        CustomTooltip(
                          message: email['body'] ?? 'No content',
                          child: Icon(Icons.info_outline, color: AppColors.primary),
                        ),
                        SizedBox(width: 16),
                        if (email['labels'] != null && email['labels']!.isNotEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2), // Smaller padding
                            decoration: BoxDecoration(
                              color: AppColors.secondary, // Softer secondary color
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              email['labels']!,
                              style: TextStyle(
                                fontSize: 10, // Smaller font size
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}