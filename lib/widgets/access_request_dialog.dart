import 'package:flutter/material.dart';
import 'package:home/widgets/airtable_signup_form.dart';

class AccessRequestDialog extends StatefulWidget {
  @override
  _AccessRequestDialogState createState() => _AccessRequestDialogState();
}

class _AccessRequestDialogState extends State<AccessRequestDialog> {
  bool _isFormSubmitted = false;

  void _onSignupComplete() {
    setState(() {
      _isFormSubmitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        child: _isFormSubmitted
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 50),
                  SizedBox(height: 20),
                  Text('Request sent successfully!'),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Close'),
                  ),
                ],
              )
            : Stack(
                children: [
                  AirtableSignupForm(onSignupComplete: _onSignupComplete),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Confirm'),
                              content: Text('Are you sure you want to close the form? Your progress will be lost.'),
                              actions: [
                                TextButton(
                                  child: Text('Cancel'),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                                TextButton(
                                  child: Text('Close'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}