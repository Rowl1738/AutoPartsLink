// Firebase client config for project autopartslink-c896d, matching
// android/app/google-services.json. These are public app identifiers, not
// secrets — access is controlled by firestore.rules. Re-running
// `flutterfire configure` regenerates this file.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          "Firebase isn't configured for $defaultTargetPlatform — run `flutterfire configure` and select it.",
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyATL4qoFLf_H2wUGZYDoL8Ih9kIKdyc28U',
    appId: '1:1098935917212:android:ab590e6082c55649cdab59',
    messagingSenderId: '1098935917212',
    projectId: 'autopartslink-c896d',
    storageBucket: 'autopartslink-c896d.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBIazIADMjd7ofo-JA4tcAlnktgSEMrZj8',
    appId: '1:1098935917212:web:2a40c28acd472407cdab59',
    messagingSenderId: '1098935917212',
    projectId: 'autopartslink-c896d',
    authDomain: 'autopartslink-c896d.firebaseapp.com',
    storageBucket: 'autopartslink-c896d.firebasestorage.app',
    measurementId: 'G-2HM1FK2LED',
  );
}
