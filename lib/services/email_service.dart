// --IMPORTS--
import 'dart:typed_data'; // Add this import for Uint8List
import 'dart:convert';  // Add this import for utf8 and base64Url
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/gmail/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:html/parser.dart' as htmlParser;
import 'package:html/dom.dart' as dom;
import 'dart:async'; // Add this import

// --CLASS DEFINITION--
class EmailService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: dotenv.env['GOOGLE_CLIENT_ID'],
    scopes: [GmailApi.gmailReadonlyScope],
  );

  String? userName;
  String? _accessToken;

  // --IS SIGNED IN METHOD--
  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  // --SIGN IN METHOD--
  Future<bool> signIn() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account != null) {
        userName = account.displayName;
        return true;
      }
      return false;
    } catch (e) {
      print('Error signing in: $e');
      return false;
    }
  }

  // --FETCH EMAILS METHOD--
  Future<List<Map<String, dynamic>>?> fetchEmails(List<String> domains, DateTimeRange? dateRange, String? toEmail, Function(int) updateProgress) async {
    final stopwatch = Stopwatch()..start();
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signInSilently();
      if (account == null) {
        print('User not signed in');
        return null;
      }

      final GoogleSignInAuthentication auth = await account.authentication;
      _accessToken = auth.accessToken;
      final authClient = authenticatedClient(
        http.Client(),
        AccessCredentials(
          AccessToken(
            'Bearer',
            _accessToken!,
            DateTime.now().toUtc().add(Duration(hours: 1)),
          ),
          auth.idToken,
          [GmailApi.gmailReadonlyScope],
        ),
      );

      final GmailApi gmailApi = GmailApi(authClient);
      
      String domainQuery = _buildDomainQuery(domains);
      String dateQuery = _buildDateQuery(dateRange);
      String toEmailQuery = _buildToEmailQuery(toEmail);

      final emailDetails = <Map<String, dynamic>>[];
      String? pageToken;
      
      do {
        final ListMessagesResponse response = await gmailApi.users.messages.list(
          'me',
          q: '${domainQuery.isEmpty ? '' : '($domainQuery)'}${dateQuery.trim()}${toEmailQuery.trim()}',
          maxResults: 100,
          pageToken: pageToken,
        );

        if (response.messages != null) {
          final batchedEmails = await _fetchEmailsBatch(response.messages!);
          emailDetails.addAll(batchedEmails);
          updateProgress(emailDetails.length); // Update this line
        }

        pageToken = response.nextPageToken;
      } while (pageToken != null && emailDetails.length < 500);

      return emailDetails;
    } catch (e) {
      print('Error fetching emails: $e');
      return null;
    } finally {
      stopwatch.stop();
    }
  }

  Future<List<Map<String, dynamic>>> _fetchEmailsBatch(List<Message> messages) async {
    final batch = http.Client();
    final futures = messages.map((message) async {
      final url = 'https://www.googleapis.com/gmail/v1/users/me/messages/${message.id}';
      final response = await batch.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );
      if (response.statusCode == 200) {
        final msg = Message.fromJson(json.decode(response.body));
        return _parseMessage(msg);
      }
      return null;
    }).toList();

    final results = await Future.wait(futures);
    batch.close();
    return results.whereType<Map<String, dynamic>>().toList();
  }

  String _buildDomainQuery(List<String> domains) {
    if (domains.contains('All newsletters') || domains.contains('*@*')) {
      return '';
    }
    return domains.map((domain) {
      if (domain.contains('*')) {
        return 'from:(*@${domain.replaceAll('*', '')})';
      } else {
        return 'from:(*@$domain)';
      }
    }).join(' OR ');
  }

  String _buildDateQuery(DateTimeRange? dateRange) {
    if (dateRange == null) return '';
    final startDate = dateRange.start.toUtc().toIso8601String().split('T')[0];
    final endDate = dateRange.end.add(Duration(days: 1)).toUtc().toIso8601String().split('T')[0];
    return ' after:$startDate before:$endDate';
  }

  String _buildToEmailQuery(String? toEmail) {
    if (toEmail == null || toEmail.isEmpty) return '';
    return ' to:$toEmail';
  }

  // --PARSE MESSAGE METHOD--
  Map<String, dynamic> _parseMessage(Message msg) {
    final headers = msg.payload?.headers;
    final fromHeader = headers?.firstWhere(
      (h) => h.name == 'From',
      orElse: () => MessagePartHeader(name: 'From', value: 'Unknown'),
    ).value ?? 'Unknown';
    final subjectHeader = headers?.firstWhere(
      (h) => h.name == 'Subject',
      orElse: () => MessagePartHeader(name: 'Subject', value: 'No Subject'),
    ).value ?? 'No Subject';

    final body = _getBody(msg.payload);
    final images = _extractImagesFromHtml(body);

    return {
      'id': msg.id!,
      'snippet': msg.snippet ?? '',
      'from': fromHeader,
      'subject': subjectHeader,
      'body': body,
      'images': images,
    };
  }

  String _getBody(MessagePart? part) {
    if (part == null) return '';

    if (part.mimeType == 'text/html' && part.body?.data != null) {
      return utf8.decode(base64Url.decode(part.body!.data!));
    }
    if (part.mimeType == 'text/plain' && part.body?.data != null) {
      return utf8.decode(base64Url.decode(part.body!.data!));
    }
    if (part.parts != null) {
      for (final subPart in part.parts!) {
        final body = _getBody(subPart);
        if (body.isNotEmpty) return body;
      }
    }
    return part.body?.data ?? '';
  }

  List<String> _extractImagesFromHtml(String htmlContent) {
    final document = htmlParser.parse(htmlContent);
    final imgElements = document.getElementsByTagName('img');
    return imgElements
      .map((img) => img.attributes['src'] ?? '')
      .where((src) => src.isNotEmpty && Uri.tryParse(src)?.hasScheme == true)
      .toList();
  }

  // --GET IMAGES METHOD--
  List<String> _getImages(MessagePart? part) {
    List<String> images = [];
    if (part?.body?.attachmentId != null) {
      images.add(part!.body!.attachmentId!);
    }
    if (part?.parts != null) {
      for (final subPart in part!.parts!) {
        images.addAll(_getImages(subPart));
      }
    }
    return images;
  }

  // --FETCH IMAGE METHOD--
  Future<Uint8List?> fetchImage(String messageId, String attachmentId) async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signInSilently();
      if (account == null) {
        print('User not signed in');
        return null;
      }

      final GoogleSignInAuthentication auth = await account.authentication;
      final authClient = authenticatedClient(
        http.Client(),
        AccessCredentials(
          AccessToken(
            'Bearer',
            auth.accessToken!,
            DateTime.now().toUtc().add(Duration(hours: 1)),
          ),
          auth.idToken,
          [GmailApi.gmailReadonlyScope],
        ),
      );

      final GmailApi gmailApi = GmailApi(authClient);
      final attachment = await gmailApi.users.messages.attachments.get(
        'me',
        messageId,
        attachmentId,
      );

      if (attachment.data != null) {
        return base64Url.decode(attachment.data!);
      }
      return null;
    } catch (e) {
      print('Error fetching image: $e');
      return null;
    }
  }

  // --GET PROXY IMAGE URL METHOD--
  Future<String> getProxyImageUrl(String originalUrl) async {
    final baseUrl = dotenv.env['FIREBASE_FUNCTIONS_BASE_URL'] ?? '';
    final proxyUrl = '$baseUrl/proxy_image';
    final encodedUrl = Uri.encodeComponent(originalUrl);
    return '$proxyUrl?url=$encodedUrl';
  }
}