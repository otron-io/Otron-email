// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for android - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBpz3Y1x_3iHQOnp8yMEn7ZV-C2fmTIvmQ',
    appId: '1:750411337406:web:fcdcbfc80b617e985198ef',
    messagingSenderId: '750411337406',
    projectId: 'otron-email-426615',
    authDomain: 'otron-email-426615.firebaseapp.com',
    storageBucket: 'otron-email-426615.appspot.com',
    measurementId: 'G-WM6D2QWDP9',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBsQmyE_g1e9chnimBrlmXmYHVGYLx48a4',
    appId: '1:750411337406:ios:b50b57ae12343ce35198ef',
    messagingSenderId: '750411337406',
    projectId: 'otron-email-426615',
    storageBucket: 'otron-email-426615.appspot.com',
    iosBundleId: 'com.example.home',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBsQmyE_g1e9chnimBrlmXmYHVGYLx48a4',
    appId: '1:750411337406:ios:b50b57ae12343ce35198ef',
    messagingSenderId: '750411337406',
    projectId: 'otron-email-426615',
    storageBucket: 'otron-email-426615.appspot.com',
    iosBundleId: 'com.example.home',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBpz3Y1x_3iHQOnp8yMEn7ZV-C2fmTIvmQ',
    appId: '1:750411337406:web:955158aa5a51f1745198ef',
    messagingSenderId: '750411337406',
    projectId: 'otron-email-426615',
    authDomain: 'otron-email-426615.firebaseapp.com',
    storageBucket: 'otron-email-426615.appspot.com',
    measurementId: 'G-2LN5D4CCP0',
  );
}
