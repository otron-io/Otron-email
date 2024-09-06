import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy for Otron Email',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: 16),
            Text('Last updated: ${DateTime.now().toLocal().toString().split(' ')[0]}'),
            SizedBox(height: 24),
            _buildSection(context, '1. Introduction', 
              'Otron Email ("we", "our", or "us") is committed to protecting your privacy. '
              'This Privacy Policy explains how we collect, use, disclose, and safeguard your '
              'information when you use our email summarization service.'
            ),
            _buildSection(context, '2. Information We Collect', 
              'We collect the following types of information:\n'
              '• Email content (for summarization purposes only)\n'
              '• User account information (name, email address)\n'
              '• Usage data (app interactions, feature usage)'
            ),
            _buildSection(context, '3. How We Use Your Information', 
              'We use your information to:\n'
              '• Provide and improve our email summarization service\n'
              '• Generate audio summaries of your emails\n'
              '• Personalize your experience\n'
              '• Communicate with you about our service'
            ),
            _buildSection(context, '4. Data Security', 
              'We implement security measures to protect your information. However, '
              'no method of transmission over the internet is 100% secure.'
            ),
            _buildSection(context, '5. Third-Party Services', 
              'We may use third-party services that collect, monitor, and analyze user data '
              'to improve our service.'
            ),
            _buildSection(context, '6. Your Rights', 
              'You have the right to access, correct, or delete your personal information. '
              'Contact us for assistance.'
            ),
            _buildSection(context, '7. Changes to This Privacy Policy', 
              'We may update our Privacy Policy from time to time. We will notify you of any '
              'changes by posting the new Privacy Policy on this page.'
            ),
            _buildSection(context, '8. Contact Us', 
              'If you have any questions about this Privacy Policy, please contact us at: '
              'arnoldas@otron.io'
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: 8),
        Text(content),
        SizedBox(height: 16),
      ],
    );
  }
}