import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android: return android;
      case TargetPlatform.iOS:     return ios;
      default: throw UnsupportedError('Unsupported platform');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey:            'AIzaSyCW3nntJmGmpfOQ6W179etFDZrAm-9ztxQ',
    databaseURL:       'https://intruderbd-b5dfd-default-rtdb.asia-southeast1.firebasedatabase.app',
    projectId:         'intruderbd-b5dfd',
    storageBucket:     'intruderbd-b5dfd.firebasestorage.app',
    messagingSenderId: '590576860860',
    appId:             '1:590576860860:android:0a736c947e8ccd35f91ab9',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey:            'AIzaSyCW3nntJmGmpfOQ6W179etFDZrAm-9ztxQ',
    appId:             '1:590576860860:android:0a736c947e8ccd35f91ab9',
    messagingSenderId: '590576860860',
    projectId:         'intruderbd-b5dfd',
    databaseURL:       'https://intruderbd-b5dfd-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket:     'intruderbd-b5dfd.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey:            'AIzaSyCW3nntJmGmpfOQ6W179etFDZrAm-9ztxQ',
    appId:             '1:590576860860:ios:0a736c947e8ccd35f91ab9',
    messagingSenderId: '590576860860',
    projectId:         'intruderbd-b5dfd',
    databaseURL:       'https://intruderbd-b5dfd-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket:     'intruderbd-b5dfd.firebasestorage.app',
  );
}
