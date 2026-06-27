import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/heart_rate_device_service.dart';
import '../services/database_service.dart';
import '../services/firebase_service.dart';
import '../widgets/connection_status_widget.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({Key? key}) : super(key: key);

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> with SingleTickerProviderStateMixin {
  final _bleService = HeartRateDeviceService();
  final _dbService = DatabaseService();
  final _firebaseService = FirebaseService();

  bool _isTrainingActive = false;
  DateTime? _trainingStartTime;
  Duration _elapsedTime = Duration.zero;
  Timer? _trainingTimer;
  StreamSubscription<int>? _hrSubscription;

  // Estadísticas en tiempo real
  List<int> _currentSessionBpmList = [];
  int _currentHeartRate = 0;
  int _maxBpm = 0;
  double _avgBpm = 0.0;

  // Animación del corazón latiendo
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Coordenadas predeterminadas (Chepén, Perú)
  final LatLng _chepenLocation = const LatLng(-7.228, -79.431);

  @override
  void initState() {
    super.initState();
    
    // Configuración de animación del corazón latiente
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.elasticOut),
    );

    // Escuchar el ritmo cardíaco del sensor BLE
    _hrSubscription = _bleService.heartRateStream.listen((bpm) {
      setState(() {
        _currentHeartRate = bpm;
        
        // Hacer latir el corazón en pantalla
        _pulseController.forward(from: 0.0);

        // Si el entrenamiento está activo, guardar en Isar y acumular estadísticas
        if (_isTrainingActive) {
          _dbService.saveHeartRatePoint(bpm);
          _currentSessionBpmList.add(bpm);
          
          // Actualizar estadísticas inmediatas en pantalla
          if (bpm > _maxBpm) _maxBpm = bpm;
          _avgBpm = _currentSessionBpmList.reduce((a, b) => a + b) / _currentSessionBpmList.length;
        }
      });
    });

    // Solicitar permisos necesarios al cargar la pantalla
    _requestPermissions();
  }

  @override
  void dispose() {
    _hrSubscription?.cancel();
    _trainingTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  /// Solicita los permisos necesarios de Ubicación y Bluetooth en tiempo de ejecución
  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.locationWhenInUse,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    if (statuses[Permission.locationWhenInUse]?.isDenied ?? false) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("⚠️ La app requiere permisos de ubicación para buscar dispositivos BLE."),
            backgroundColor: Colors.amber,
          ),
        );
      }
    }
  }

  /// Inicia la sesión de entrenamiento
  Future<void> _startWorkout() async {
    // Autenticar de forma anónima en Firebase en segundo plano si aún no está hecho
    try {
      await _firebaseService.signInAnonymously();
    } catch (e) {
      debugPrint("Error de autenticación anónima: $e");
    }

    await _dbService.startSession();
    
    setState(() {
      _isTrainingActive = true;
      _trainingStartTime = DateTime.now();
      _elapsedTime = Duration.zero;
      _currentSessionBpmList.clear();
      _maxBpm = 0;
      _avgBpm = 0.0;
    });

    // Iniciar cronómetro
    _trainingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedTime = DateTime.now().difference(_trainingStartTime!);
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("🚴 Entrenamiento Iniciado. Guardando latidos offline..."),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Detiene la sesión de entrenamiento, guarda en Isar, y sincroniza en segundo plano con Firebase
  Future<void> _stopWorkout() async {
    _trainingTimer?.cancel();
    
    final savedSession = await _dbService.stopSession();
    
    setState(() {
      _isTrainingActive = false;
    });

    if (savedSession != null) {
      // Notificar guardado local exitoso
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("💾 Sesión guardada localmente en Isar Database."),
          backgroundColor: Colors.blueAccent,
        ),
      );

      // Lógica de subida optimizada en segundo plano a Firestore
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("☁️ Sincronizando resumen de entrenamiento en la nube..."),
            backgroundColor: Colors.deepPurpleAccent,
            duration: Duration(seconds: 2),
          ),
        );

        await _firebaseService.uploadSession(savedSession);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ ¡Entrenamiento subido exitosamente a Firestore!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("ℹ️ Sesión guardada de forma segura en local. Sincronización pendiente: $e"),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Estética Premium Oscura
      appBar: AppBar(
        title: const Text("WAHOO BLE TRACKER", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        backgroundColor: const Color(0xFF1E1E1E),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth),
            onPressed: () => _bleService.startScan(),
            tooltip: "Buscar sensores",
          )
        ],
      ),
      body: Column(
        children: [
          // Mitad superior: Mapa de OpenStreetMap
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: _chepenLocation,
                    initialZoom: 14.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.antigravity.wahooble',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _chepenLocation,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
                        ),
                      ],
                    ),
                  ],
                ),
                // Panel flotante de advertencia de batería (GPS + BLE)
                Positioned(
                  bottom: 10,
                  left: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xCC000000), // Negro semitransparente
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withOpacity(0.5)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.battery_alert, color: Colors.amber, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Nota: El GPS activo junto al Bluetooth incrementa el consumo de batería.",
                            style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Mitad inferior: Dashboard del Ritmo Cardíaco (Estilo Wahoo)
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Estado del Bluetooth
                  const ConnectionStatusWidget(),

                  // Frecuencia cardíaca en tiempo real
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.redAccent,
                          size: 70,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        _currentHeartRate > 0 ? "$_currentHeartRate" : "--",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 80,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Outfit',
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "BPM",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  // Estadísticas de la sesión (Promedio, Máximo, Duración)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetricTile("MÁXIMO", "${_maxBpm > 0 ? _maxBpm : '--'} BPM", Colors.orangeAccent),
                      _buildMetricTile("TIEMPO", _formatDuration(_elapsedTime), Colors.blueAccent),
                      _buildMetricTile("PROMEDIO", "${_avgBpm > 0 ? _avgBpm.toStringAsFixed(0) : '--'} BPM", Colors.greenAccent),
                    ],
                  ),

                  // Botones de acción
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isTrainingActive ? Colors.redAccent : Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                      ),
                      onPressed: _isTrainingActive ? _stopWorkout : _startWorkout,
                      child: Text(
                        _isTrainingActive ? "DETENER ENTRENAMIENTO" : "INICIAR ENTRENAMIENTO",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.0),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
