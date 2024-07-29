import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import for Clipboard
import 'package:home/services/email_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:html/parser.dart' as htmlparser;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';

class EmailList extends StatefulWidget {
  final List<Map<String, dynamic>> emails;
  final EmailService emailService;

  const EmailList({
    Key? key,
    required this.emails,
    required this.emailService,
  }) : super(key: key);

  @override
  _EmailListState createState() => _EmailListState();
}

class _EmailListState extends State<EmailList> {
  Set<String> filteredPatterns = {};

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: widget.emails.length,
      separatorBuilder: (context, index) => Divider(height: 1),
      itemBuilder: (context, index) {
        final email = widget.emails[index];
        return _buildEmailListItem(context, email);
      },
    );
  }

  Widget _buildEmailListItem(BuildContext context, Map<String, dynamic> email) {
    return ExpansionTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Text(
          email['from']?.substring(0, 1).toUpperCase() ?? '?',
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
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
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Content:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              _buildSimpleHtmlContent(context, email['body'] ?? 'No content'),
              // Commented out image-related sections
              // SizedBox(height: 16),
              // if (email['images'] != null && (email['images'] as List).isNotEmpty)
              //   Text(
              //     'Images:',
              //     style: Theme.of(context).textTheme.titleSmall?.copyWith(
              //       fontWeight: FontWeight.bold,
              //     ),
              //   ),
              // SizedBox(height: 8),
              // _buildImageCarousel(context, email),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleHtmlContent(BuildContext context, String htmlContent) {
    final document = htmlparser.parse(htmlContent);
    final plainText = document.body?.text ?? 'No content';
    return Text(
      plainText.isNotEmpty ? plainText : 'No content available',
      style: Theme.of(context).textTheme.bodyMedium,
      maxLines: 10,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildImageCarousel(BuildContext context, Map<String, dynamic> email) {
    final List<String> images = email['images'] as List<String>;
    final List<String> filteredImages = images.where((url) => 
      !filteredPatterns.any((pattern) => url.contains(pattern))
    ).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CarouselSlider.builder(
          itemCount: filteredImages.length,
          options: CarouselOptions(
            height: 200,
            viewportFraction: 0.8,
            enlargeCenterPage: true,
            enableInfiniteScroll: false,
          ),
          itemBuilder: (context, index, realIndex) {
            final imageUrl = filteredImages[index];
            return Column(
              children: [
                Expanded(
                  child: FutureBuilder<String>(
                    future: widget.emailService.getProxyImageUrl(imageUrl),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildPlaceholder();
                      }
                      if (snapshot.hasError || !snapshot.hasData) {
                        return _buildErrorWidget();
                      }
                      final proxyUrl = snapshot.data!;
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: proxyUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => _buildPlaceholder(),
                            errorWidget: (context, url, error) {
                              print('Error loading image: $url, Error: $error');
                              return _buildErrorWidget();
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _showUrlOptions(context, imageUrl),
                  child: Text(
                    imageUrl,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      decoration: TextDecoration.underline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          },
        ),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => _showFilterDialog(context),
          child: Text('Filter Images'),
        ),
      ],
    );
  }

  void _showUrlOptions(BuildContext context, String url) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.content_copy),
                title: Text('Copy URL'),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: url));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('URL copied to clipboard')),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.open_in_browser),
                title: Text('Open in browser'),
                onTap: () async {
                  final Uri uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not open URL')),
                    );
                  }
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String filterPattern = '';
        return AlertDialog(
          title: Text('Filter Images'),
          content: TextField(
            onChanged: (value) => filterPattern = value,
            decoration: InputDecoration(
              hintText: 'Enter URL pattern to filter',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Apply'),
              onPressed: () {
                setState(() {
                  filteredPatterns.add(filterPattern);
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[300],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, color: Colors.red),
          SizedBox(height: 4),
          Text(
            'Error',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}