import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/gmail/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EmailService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: dotenv.env['GOOGLE_CLIENT_ID'], // Reference from .env
    scopes: [
      GmailApi.gmailReadonlyScope,
    ],
  );

  Future<List<dynamic>?> fetchEmails() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('Sign in aborted by user');
        return null;
      }

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

      // Call the users.messages.list method
      final ListMessagesResponse response =
          await gmailApi.users.messages.list(
        'me', // Use 'me' to indicate the authenticated user
        maxResults: 10,
      );

      // Print the message IDs and fetch message details
      final emails = <Map<String, dynamic>>[];
      if (response.messages != null) {
        for (final Message message in response.messages!) {
          final msg = await gmailApi.users.messages.get('me', message.id!);
          emails.add({'snippet': msg.snippet});
        }
      }

      return emails;
    } catch (e) {
      print('Error fetching emails: $e');
      return null;
    }
  }
}