import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // IMPORTANTE: Vincula tu archivo manual de credenciales
import 'services/database_service.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inicializar la base de datos local (Isar) - Imprescindible para Offline-First
  try {
    await DatabaseService().initialize();
    debugPrint("Base de datos Isar inicializada exitosamente.");
  } catch (e) {
    debugPrint("Error crítico al inicializar Isar: $e");
  }

  // 2. Inicializar Firebase utilizando tus credenciales manuales fijas
  try {
    // Activamos la inicialización segura usando tu objeto DefaultFirebaseOptions
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("Firebase inicializado correctamente con opciones personalizadas.");
  } catch (e) {
    debugPrint("Aviso de Firebase: No se pudo conectar a Firebase ($e). Se usará modo offline de Isar.");
  }

  runApp(const WahooBleApp());
}

class WahooBleApp extends StatelessWidget {
  const WahooBleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIRCAM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF1E1E1E),
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Colors.blueAccent,
          secondary: Colors.redAccent,
          background: const Color(0xFF121212),
          surface: const Color(0xFF1E1E1E),
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}