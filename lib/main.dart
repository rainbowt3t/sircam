import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/database_service.dart';
import 'screens/workout_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inicializar la base de datos local (Isar) - Imprescindible para Offline-First
  try {
    await DatabaseService().initialize();
    debugPrint("Base de datos Isar inicializada exitosamente.");
  } catch (e) {
    debugPrint("Error crítico al inicializar Isar: $e");
  }

  // 2. Inicializar Firebase (Opcional - Capturamos el error si no está configurado aún)
  // El usuario debe correr 'flutterfire configure' para generar las opciones de compilación.
  try {
    // Si tienes firebase_options.dart generado por FlutterFire CLI, descomenta e impórtalo:
    // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await Firebase.initializeApp();
    debugPrint("Firebase inicializado correctamente.");
  } catch (e) {
    debugPrint("Aviso de Firebase: No se pudo conectar a Firebase (Aún no configurado). Se usará modo offline de Isar.");
  }

  runApp(const WahooBleApp());
}

class WahooBleApp extends StatelessWidget {
  const WahooBleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wahoo BLE Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF1E1E1E),
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Colors.blueAccent,
          secondary: Colors.redAccent,
          background: Color(0xFF121212),
          surface: Color(0xFF1E1E1E),
        ),
        useMaterial3: true,
      ),
      home: const WorkoutScreen(),
    );
  }
}
