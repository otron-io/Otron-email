import 'package:flutter/material.dart';

class EmailList extends StatelessWidget {
  final List<dynamic> emails;

  const EmailList({Key? key, required this.emails}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(8.0),
        constraints: BoxConstraints(maxWidth: 800),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Emails',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: emails.length > 2 ? 200.0 : double.infinity,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Snippet')),
                    DataColumn(label: Text('Sender')),
                    DataColumn(label: Text('Category')),
                  ],
                  rows: emails.map<DataRow>((email) {
                    return DataRow(
                      cells: [
                        DataCell(Text(email['snippet'] ?? 'No snippet')),
                        DataCell(Text(email['sender'] ?? 'Unknown')),
                        DataCell(Text(email['category'] ?? 'Uncategorized')),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}