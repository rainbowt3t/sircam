import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('La plataforma Web no está configurada.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Plataforma no soportada.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC-XDzbUixJHAOiMIse8SFaxcTtf3ig0ZI', // Lo encuentras como current_key en el json
    appId: '1:640565292846:android:43d0f34323324184f2d4bf', // ¡Este ya lo sacamos de tu foto!
    messagingSenderId: '640565292846', // Es el project_number de tu json
    projectId: 'proyecto-chepen-heart',
    storageBucket: 'proyecto-chepen-heart.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC-XDzbUixJHAOiMIse8SFaxcTtf3ig0ZI', // Para desarrollo inicial en Android puedes usar los mismos datos
    appId: '1:640565292846:android:43d0f34323324184f2d4bf', 
    messagingSenderId: '640565292846',
    projectId: 'proyecto-chepen-heart',
    storageBucket: 'proyecto-chepen-heart.appspot.com',
    iosBundleId: 'com.jhonny.proyecto-chepen',
  );
}