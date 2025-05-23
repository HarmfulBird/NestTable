import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
    apiKey: 'AIzaSyD-rlHwE6762CVyzhzVykYGDxfXpbGRmPg',
    appId: '1:495409139410:web:33d772aedab1ab474a670b',
    messagingSenderId: '495409139410',
    projectId: 'nesttable-fluffytech',
    authDomain: 'nesttable-fluffytech.firebaseapp.com',
    databaseURL: 'https://nesttable-fluffytech-default-rtdb.firebaseio.com',
    storageBucket: 'nesttable-fluffytech.firebasestorage.app',
    measurementId: 'G-NQ559C6N04',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAqzPK65j2-Z6lW9nBCweY5BdBHexJdt7A',
    appId: '1:495409139410:android:1825229175ac77ae4a670b',
    messagingSenderId: '495409139410',
    projectId: 'nesttable-fluffytech',
    databaseURL: 'https://nesttable-fluffytech-default-rtdb.firebaseio.com',
    storageBucket: 'nesttable-fluffytech.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBVHqWGHIyt5wkEveondATqulIOcKthy1E',
    appId: '1:495409139410:ios:a21f8afb4c0c97c14a670b',
    messagingSenderId: '495409139410',
    projectId: 'nesttable-fluffytech',
    databaseURL: 'https://nesttable-fluffytech-default-rtdb.firebaseio.com',
    storageBucket: 'nesttable-fluffytech.firebasestorage.app',
    iosBundleId: 'com.example.nesttable',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBVHqWGHIyt5wkEveondATqulIOcKthy1E',
    appId: '1:495409139410:ios:a21f8afb4c0c97c14a670b',
    messagingSenderId: '495409139410',
    projectId: 'nesttable-fluffytech',
    databaseURL: 'https://nesttable-fluffytech-default-rtdb.firebaseio.com',
    storageBucket: 'nesttable-fluffytech.firebasestorage.app',
    iosBundleId: 'com.example.nesttable',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyD-rlHwE6762CVyzhzVykYGDxfXpbGRmPg',
    appId: '1:495409139410:web:fab3d3d19e5c11a14a670b',
    messagingSenderId: '495409139410',
    projectId: 'nesttable-fluffytech',
    authDomain: 'nesttable-fluffytech.firebaseapp.com',
    databaseURL: 'https://nesttable-fluffytech-default-rtdb.firebaseio.com',
    storageBucket: 'nesttable-fluffytech.firebasestorage.app',
    measurementId: 'G-7N3TQSN1DQ',
  );

}