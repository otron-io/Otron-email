import 'package:flutter/material.dart';

class EmailList extends StatelessWidget {
  final List<Map<String, dynamic>> emails;

  const EmailList({
    Key? key,
    required this.emails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: emails.length,
      separatorBuilder: (context, index) => Divider(height: 1),
      itemBuilder: (context, index) {
        final email = emails[index];
        return _buildEmailListItem(context, email);
      },
    );
  }

  Widget _buildEmailListItem(BuildContext context, Map<String, dynamic> email) {
    return ExpansionTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        child: Text(
          email['from']?.substring(0, 1).toUpperCase() ?? '?',
          style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer),
        ),
      ),
      title: Text(
        email['subject'] ?? 'No Subject',
        style: Theme.of(context).textTheme.titleMedium,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        email['from'] ?? 'Unknown',
        style: Theme.of(context).textTheme.bodyMedium,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: email['labels'] != null
          ? Chip(
              label: Text(
                email['labels'],
                style: TextStyle(fontSize: 12),
              ),
              backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
              labelStyle: TextStyle(color: Theme.of(context).colorScheme.onTertiaryContainer),
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            )
          : null,
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Content:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              SizedBox(height: 8),
              Text(
                email['body'] ?? 'No content',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}