import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

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
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA8SQx02wspEaxCePRpo3tPqQaUpLft5jE',
    appId: '1:714410252186:web:1f91a6b16bfd9f1eb30c23',
    messagingSenderId: '714410252186',
    projectId: 'isovent-bau-inventory-app',
    authDomain: 'isovent-bau-inventory-app.firebaseapp.com',
    storageBucket: 'isovent-bau-inventory-app.firebasestorage.app',
    measurementId: 'G-LNPTTC9PGT',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBAfN3sxrfQcgDJvrVohJtx_5AmukbkHaU',
    appId: '1:714410252186:android:2a30f5973925778ab30c23',
    messagingSenderId: '714410252186',
    projectId: 'isovent-bau-inventory-app',
    storageBucket: 'isovent-bau-inventory-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAtZsYFCgr8uHYBtaXtMeATkc9mFqUGLm0',
    appId: '1:714410252186:ios:1ea4350775793c2ab30c23',
    messagingSenderId: '714410252186',
    projectId: 'isovent-bau-inventory-app',
    storageBucket: 'isovent-bau-inventory-app.firebasestorage.app',
    iosBundleId: 'com.isoventbau.inventory',
  );
}
