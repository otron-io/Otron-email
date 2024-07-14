import 'package:flutter/material.dart';

class GeneratedTextDisplay extends StatefulWidget {
  final List<String> streamedContent;

  const GeneratedTextDisplay({Key? key, required this.streamedContent}) : super(key: key);

  @override
  _GeneratedTextDisplayState createState() => _GeneratedTextDisplayState();
}

class _GeneratedTextDisplayState extends State<GeneratedTextDisplay> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 0,
      child: ExpansionPanelList(
        elevation: 0,
        expandedHeaderPadding: EdgeInsets.zero,
        expansionCallback: (int index, bool isExpanded) {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        children: [
          ExpansionPanel(
            headerBuilder: (BuildContext context, bool isExpanded) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage('https://i.ibb.co/xHhxjms/podcast-icon.png'),
                  radius: 25,
                ),
                title: Text(
                  'Your podcast',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Text(
                  'Generated content',
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 300, // Adjust this value as needed
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: widget.streamedContent.map((chunk) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Text(
                            chunk,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                              color: Theme.of(context).colorScheme.onBackground,
                            ),
                          ),
                        )).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            isExpanded: _isExpanded,
          ),
        ],
      ),
    );
  }
}