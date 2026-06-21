import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBRhFCu7AdSrkRr_ENSageazdl4s2Tgm84',
    authDomain: 'heartsync-b4e9f.firebaseapp.com',
    projectId: 'heartsync-b4e9f',
    storageBucket: 'heartsync-b4e9f.firebasestorage.app',
    messagingSenderId: '324450946196',
    appId: '1:324450946196:web:7b1bd408e54a58ea2eb881',
    measurementId: 'G-MFX0PDLDLN',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBRhFCu7AdSrkRr_ENSageazdl4s2Tgm84',
    appId: '1:324450946196:android:placeholder',
    messagingSenderId: '324450946196',
    projectId: 'heartsync-b4e9f',
    storageBucket: 'heartsync-b4e9f.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBRhFCu7AdSrkRr_ENSageazdl4s2Tgm84',
    appId: '1:324450946196:ios:placeholder',
    messagingSenderId: '324450946196',
    projectId: 'heartsync-b4e9f',
    storageBucket: 'heartsync-b4e9f.firebasestorage.app',
    iosBundleId: 'com.heartsync.app',
  );
}
