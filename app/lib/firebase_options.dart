// Firebase configuration for FitTrack app
// Generated from Firebase Console

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
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
        return android;
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
    apiKey: 'AIzaSyD6UPXqcEtqpI8UibYTFspHXnmCFmvHgZI',
    appId: '1:8301096039:web:81c54bd39a94bef4c8b8c2',
    messagingSenderId: '8301096039',
    projectId: 'fit-track-app-f7260',
    authDomain: 'fit-track-app-f7260.firebaseapp.com',
    storageBucket: 'fit-track-app-f7260.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD6UPXqcEtqpI8UibYTFspHXnmCFmvHgZI',
    appId: '1:8301096039:android:placeholder',
    messagingSenderId: '8301096039',
    projectId: 'fit-track-app-f7260',
    storageBucket: 'fit-track-app-f7260.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD6UPXqcEtqpI8UibYTFspHXnmCFmvHgZI',
    appId: '1:8301096039:ios:placeholder',
    messagingSenderId: '8301096039',
    projectId: 'fit-track-app-f7260',
    storageBucket: 'fit-track-app-f7260.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyD6UPXqcEtqpI8UibYTFspHXnmCFmvHgZI',
    appId: '1:8301096039:ios:placeholder',
    messagingSenderId: '8301096039',
    projectId: 'fit-track-app-f7260',
    storageBucket: 'fit-track-app-f7260.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyD6UPXqcEtqpI8UibYTFspHXnmCFmvHgZI',
    appId: '1:8301096039:web:81c54bd39a94bef4c8b8c2',
    messagingSenderId: '8301096039',
    projectId: 'fit-track-app-f7260',
    authDomain: 'fit-track-app-f7260.firebaseapp.com',
    storageBucket: 'fit-track-app-f7260.firebasestorage.app',
  );
}