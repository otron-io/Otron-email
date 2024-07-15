import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:html' as html;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;

class AirtableSignupForm extends StatefulWidget {
  final VoidCallback onSignupComplete;

  const AirtableSignupForm({Key? key, required this.onSignupComplete}) : super(key: key);

  @override
  _AirtableSignupFormState createState() => _AirtableSignupFormState();
}

class _AirtableSignupFormState extends State<AirtableSignupForm> {
  late final WebViewController _controller;
  bool _isWebViewReady = false;
  final String _airtableFormUrl = 'https://airtable.com/embed/appVdd3nM2nxuCKVM/pagUVPncnWIE41jwi/form';
  bool _formSubmitted = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initWebView();
    }
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (url.contains('formSubmitted=true') && !_formSubmitted) {
              _formSubmitted = true;
              widget.onSignupComplete();
            }
            setState(() {
              _isWebViewReady = true;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(_airtableFormUrl));
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Use IFrameElement for web
      final String viewType = 'airtable-form-${UniqueKey().toString()}';
      ui.platformViewRegistry.registerViewFactory(
        viewType,
        (int viewId) {
          final iframe = html.IFrameElement()
            ..src = _airtableFormUrl
            ..style.border = 'none'
            ..allowFullscreen = false;

          // Listen for messages from the iframe
          html.window.onMessage.listen((event) {
            if (event.data == 'formSubmitted' && !_formSubmitted) {
              _formSubmitted = true;
              widget.onSignupComplete();
            }
          });

          return iframe;
        },
      );

      return HtmlElementView(viewType: viewType);
    } else {
      // Use WebView for mobile
      return _isWebViewReady
          ? WebViewWidget(controller: _controller)
          : Center(child: CircularProgressIndicator());
    }
  }
}