import 'dart:convert'; // Add this import for base64 decoding
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/gmail/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:html/parser.dart' show parse; // Add this import for HTML parsing

class EmailService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: dotenv.env['GOOGLE_CLIENT_ID'], // Reference from .env
    scopes: [
      GmailApi.gmailReadonlyScope,
    ],
  );

  String? userName;

  Future<List<Map<String, String>>?> fetchEmails() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('Sign in aborted by user');
        return null;
      }

      userName = googleUser.displayName;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create an authenticated HTTP client
      final authClient = authenticatedClient(
        http.Client(),
        AccessCredentials(
          AccessToken(
            'Bearer',
            googleAuth.accessToken!,
            DateTime.now().toUtc().add(Duration(hours: 1)), // Ensure UTC format
          ),
          googleAuth.idToken,
          [GmailApi.gmailReadonlyScope],
        ),
      );

      // Create a Gmail API client using the authenticated client
      final GmailApi gmailApi = GmailApi(authClient);

      // Call the users.messages.list method with labelIds filter and date filter for last week
      final DateTime now = DateTime.now().toUtc();
      final DateTime lastWeek = now.subtract(Duration(days: 7));
      final String lastWeekFormatted = (lastWeek.millisecondsSinceEpoch ~/ 1000).toString();

      final ListMessagesResponse response =
          await gmailApi.users.messages.list(
        'me', // Use 'me' to indicate the authenticated user
        //maxResults: 10,
        labelIds: ['CATEGORY_UPDATES', 'INBOX'],
        q: 'after:$lastWeekFormatted from:@buildspace.so',
      );
      // Fetch message details
      final emailDetails = <Map<String, String>>[];
      if (response.messages != null) {
        for (final Message message in response.messages!) {
          final msg = await gmailApi.users.messages.get('me', message.id!);
          final headers = msg.payload?.headers;
          final fromHeader = headers?.firstWhere(
            (h) => h.name == 'From',
            orElse: () => MessagePartHeader(name: 'From', value: 'Unknown'),
          ).value ?? 'Unknown';
          final subjectHeader = headers?.firstWhere(
            (h) => h.name == 'Subject',
            orElse: () => MessagePartHeader(name: 'Subject', value: 'No Subject'),
          ).value ?? 'No Subject';

          // Decode the body content
          final body = _getBody(msg.payload);

          emailDetails.add({
            'id': message.id!,
            'snippet': msg.snippet ?? '',
            'from': fromHeader,
            'subject': subjectHeader,
            'labels': msg.labelIds?.join(', ') ?? 'No Labels',
            'body': body,
          });
        }
      }

      return emailDetails;
    } catch (e) {
      print('Error fetching emails: $e');
      return null;
    }
  }

  String _getBody(MessagePart? part) {
    if (part == null) return 'No Body';

    if (part.body?.data != null) {
      final decodedBody = utf8.decode(base64Url.decode(part.body!.data!));
      return _stripHtmlIfNeeded(decodedBody);
    }

    if (part.parts != null) {
      for (final subPart in part.parts!) {
        final body = _getBody(subPart);
        if (body.isNotEmpty) {
          return body;
        }
      }
    }

    return 'No Body';
  }

  String _stripHtmlIfNeeded(String body) {
    final document = parse(body);
    return document.body?.text ?? body;
  }
}