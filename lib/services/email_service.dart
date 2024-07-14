// --IMPORTS--
import 'dart:convert';  // Add this import for utf8 and base64Url
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/gmail/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// --CLASS DEFINITION--
class EmailService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: dotenv.env['GOOGLE_CLIENT_ID'],
    scopes: [GmailApi.gmailReadonlyScope],
  );

  String? userName;

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
  Future<List<Map<String, dynamic>>?> fetchEmails(List<String> domains) async {
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
            DateTime.now().toUtc().add(Duration(hours: 1)), // Use UTC time
          ),
          auth.idToken,
          [GmailApi.gmailReadonlyScope],
        ),
      );

      final GmailApi gmailApi = GmailApi(authClient);
      final String domainQuery = domains.map((domain) => 'from:$domain').join(' OR ');
      final ListMessagesResponse response = await gmailApi.users.messages.list(
        'me',
        q: domainQuery,
        maxResults: 10,
      );

      final emailDetails = <Map<String, dynamic>>[];
      if (response.messages != null) {
        for (final Message message in response.messages!) {
          final msg = await gmailApi.users.messages.get('me', message.id!);
          emailDetails.add(_parseMessage(msg));
        }
      }

      return emailDetails;
    } catch (e) {
      print('Error fetching emails: $e');
      return null;
    }
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

    return {
      'id': msg.id!,
      'snippet': msg.snippet ?? '',
      'from': fromHeader,
      'subject': subjectHeader,
      'body': _getBody(msg.payload),
    };
  }

  // --GET BODY METHOD--
  String _getBody(MessagePart? part) {
    if (part?.body?.data != null) {
      return utf8.decode(base64Url.decode(part!.body!.data!));
    }
    if (part?.parts != null) {
      for (final subPart in part!.parts!) {
        final body = _getBody(subPart);
        if (body.isNotEmpty) return body;
      }
    }
    return '';
  }

  // --RENDER SIGN IN BUTTON METHOD--
  Widget renderSignInButton() {
    return ElevatedButton(
      onPressed: signIn,
      child: Text('Sign in with Google'),
    );
  }
}