// --IMPORTS--
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/gmail/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';

// --CLASS DEFINITION--
class EmailService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: dotenv.env['GOOGLE_CLIENT_ID'],
    scopes: [
      GmailApi.gmailReadonlyScope,
    ],
  );

  String? userName;

  // --FETCH EMAILS METHOD--
  Future<List<Map<String, dynamic>>?> fetchEmails(List<String> domains) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('Sign in aborted by user');
        return null;
      }

      userName = googleUser.displayName;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final authClient = authenticatedClient(
        http.Client(),
        AccessCredentials(
          AccessToken(
            'Bearer',
            googleAuth.accessToken!,
            DateTime.now().toUtc().add(Duration(hours: 1)),
          ),
          googleAuth.idToken,
          [GmailApi.gmailReadonlyScope],
        ),
      );

      final GmailApi gmailApi = GmailApi(authClient);

      final DateTime startDate = DateTime.utc(2024, 7, 1);
      final DateTime endDate = DateTime.utc(2024, 7, 7, 23, 59, 59);
      final String startDateFormatted = (startDate.millisecondsSinceEpoch ~/ 1000).toString();
      final String endDateFormatted = (endDate.millisecondsSinceEpoch ~/ 1000).toString();

      final String domainQuery = domains.map((domain) => 'from:$domain').join(' OR ');
      final ListMessagesResponse response = await gmailApi.users.messages.list(
        'me',
        labelIds: ['CATEGORY_UPDATES', 'INBOX'],
        q: 'after:$startDateFormatted before:$endDateFormatted ($domainQuery) -from:notifications@buildspace.so',
      );
      final emailDetails = <Map<String, dynamic>>[];
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

          final body = _getBody(msg.payload);
          final urls = _extractUrls(body);
          final embeddedImages = await _getEmbeddedImages(gmailApi, 'me', message.id!, msg.payload!);

          emailDetails.add({
            'id': message.id!,
            'snippet': msg.snippet ?? '',
            'from': fromHeader,
            'subject': subjectHeader,
            'labels': msg.labelIds?.join(', ') ?? 'No Labels',
            'body': body,
            'urls': urls,
            'embeddedImages': embeddedImages,
          });
        }
      }

      return emailDetails;
    } catch (e) {
      print('Error fetching emails: $e');
      return null;
    }
  }

  // --GET BODY METHOD--
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

  // --STRIP HTML METHOD--
  String _stripHtmlIfNeeded(String body) {
    final document = parse(body);
    return document.body?.text ?? body;
  }

  // --EXTRACT URLS METHOD--
  List<String> _extractUrls(String text) {
    final urlRegex = RegExp(r'https?://\S+');
    return urlRegex.allMatches(text)
        .map((match) => match.group(0)!)
        .toSet()
        .toList();
  }

  // --GET EMBEDDED IMAGES METHOD--
  Future<List<Map<String, String>>> _getEmbeddedImages(GmailApi gmailApi, String userId, String messageId, MessagePart part) async {
    List<Map<String, String>> embeddedImages = [];

    if (part.mimeType?.startsWith('image/') == true && part.body?.attachmentId != null) {
      embeddedImages.add({
        'filename': part.filename ?? 'embedded_image',
        'mimeType': part.mimeType!,
        'attachmentId': part.body!.attachmentId!,
      });
    }

    if (part.parts != null) {
      for (var subPart in part.parts!) {
        embeddedImages.addAll(await _getEmbeddedImages(gmailApi, userId, messageId, subPart));
      }
    }

    return embeddedImages;
  }

  // --GET ATTACHMENT DATA METHOD--
  Future<List<int>> _getAttachmentData(GmailApi gmailApi, String userId, String messageId, String attachmentId) async {
    final attachment = await gmailApi.users.messages.attachments.get(userId, messageId, attachmentId);
    if (attachment.data != null) {
      return base64Url.decode(attachment.data!);
    }
    return [];
  }
}