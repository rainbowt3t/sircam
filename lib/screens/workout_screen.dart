import 'dart:async';
import 'package:flutter/material.dart';
import '../services/heart_rate_device_service.dart';
import '../services/database_service.dart';
import '../models/heart_rate_data.dart';
import 'home_tab.dart';
import 'history_tab.dart';
import 'sos_tab.dart';
import 'alerts_tab.dart';
import 'profile_tab.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({Key? key}) : super(key: key);

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  int _currentIndex = 0;
  final _bleService = HeartRateDeviceService();
  final _dbService = DatabaseService();

  // Estados cardíacos globales
  int _currentHeartRate = 0;
  bool _isTrainingActive = false;
  DateTime? _trainingStartTime;
  Duration _elapsedTime = Duration.zero;
  Timer? _trainingTimer;
  StreamSubscription<int>? _hrSubscription;

  // Lógica de SOS y Anomalías
  Timer? _anomalyTriggerTimer;
  bool _isShowingAnomalyAlert = false;
  int _anomalyBpm = 0;
  int _countdownSeconds = 10;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();

    // Escuchar del servicio BLE
    _hrSubscription = _bleService.heartRateStream.listen((bpm) {
      if (mounted) {
        setState(() {
          _currentHeartRate = bpm;
        });
      }

      // Si el entrenamiento está activo, guardar en Isar
      if (_isTrainingActive && bpm > 0) {
        _dbService.saveHeartRatePoint(bpm);
      }

      // Evaluar si hay taquicardia/bradicardia severa
      _evaluateHeartRateAnomalies(bpm);
    });
  }

  @override
  void dispose() {
    _hrSubscription?.cancel();
    _trainingTimer?.cancel();
    _anomalyTriggerTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  /// Inicia o detiene el monitoreo del entrenamiento
  Future<void> _toggleTraining() async {
    if (_isTrainingActive) {
      // Detener
      _trainingTimer?.cancel();
      await _dbService.stopSession();
      setState(() {
        _isTrainingActive = false;
        _elapsedTime = Duration.zero;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("💾 Monitoreo finalizado y guardado localmente."),
            backgroundColor: Colors.blueAccent,
          ),
        );
      }
    } else {
      // Iniciar
      await _dbService.startSession();
      setState(() {
        _isTrainingActive = true;
        _trainingStartTime = DateTime.now();
        _elapsedTime = Duration.zero;
      });
      _trainingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _elapsedTime = DateTime.now().difference(_trainingStartTime!);
          });
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🚴 Monitoreo iniciado en tiempo real."),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  /// Evalúa anomalías cardíacas críticas y activa el SOS autónomo si dura más de 5 segundos
  void _evaluateHeartRateAnomalies(int bpm) {
    if (bpm == 0) return;

    // Umbral de taquicardia severa (>125 lpm) o bradicardia severa (<45 lpm)
    bool isAnomalous = bpm >= 125 || bpm <= 45;

    if (isAnomalous) {
      if (_anomalyTriggerTimer == null && !_isShowingAnomalyAlert) {
        // Si el ritmo anómalo persiste por 5 segundos
        _anomalyTriggerTimer = Timer(const Duration(seconds: 5), () {
          _triggerAnomalyAlert(bpm);
        });
      }
    } else {
      _anomalyTriggerTimer?.cancel();
      _anomalyTriggerTimer = null;
    }
  }

  /// Dispara el popup de confirmación de estado con cuenta regresiva de 10 segundos
  void _triggerAnomalyAlert(int bpm) {
    if (_isShowingAnomalyAlert) return;

    setState(() {
      _isShowingAnomalyAlert = true;
      _anomalyBpm = bpm;
      _countdownSeconds = 10;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_countdownSeconds > 1) {
            _countdownSeconds--;
          } else {
            // El contador llegó a 0 y el usuario no respondió -> Activar SOS
            _countdownTimer?.cancel();
            Navigator.of(context).pop(); // Cerrar el diálogo
            _triggerAutonomousEmergency();
          }
        });
      }
    });

    showDialog(
      context: context,
      barrierDismissible: false, // No se puede cerrar tocando fuera
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.redAccent, size: 28),
                SizedBox(width: 10),
                Text("¿Te encuentras bien?", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Se ha detectado una frecuencia crítica de $_anomalyBpm lpm de forma continua.",
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Si no respondes, se llamará a emergencias en:",
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 15),
                // Círculo indicador de tiempo restante
                Container(
                  width: 70,
                  height: 70,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.redAccent, width: 3),
                  ),
                  child: Text(
                    "$_countdownSeconds",
                    style: const TextStyle(color: Colors.redAccent, fontSize: 32, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text("SÍ, ESTOY BIEN", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                onPressed: () {
                  _countdownTimer?.cancel();
                  _anomalyTriggerTimer?.cancel();
                  _anomalyTriggerTimer = null;
                  setState(() {
                    _isShowingAnomalyAlert = false;
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Alerta cancelada. Monitoreo normal continuado."), backgroundColor: Colors.green),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  /// Lanza el SOS Autónomo: Guarda la alerta crítica en Isar y redirige al Tab de SOS
  Future<void> _triggerAutonomousEmergency() async {
    setState(() {
      _isShowingAnomalyAlert = false;
      _currentIndex = 2; // Redirigir a la pestaña SOS
    });

    // Guardar la alerta de taquicardia/bradicardia crítica en la base de datos
    final alert = CardiacAlert(
      title: _anomalyBpm >= 120 ? "Taquicardia severa detectada" : "Bradicardia severa detectada",
      description: "Frecuencia crítica: $_anomalyBpm lpm registrada automáticamente ante falta de respuesta.",
      timestamp: DateTime.now(),
      heartRate: _anomalyBpm,
      type: "critica",
    );

    await _dbService.saveAlert(alert);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🚨 SOS Autónomo Activado. Alerta médica enviada al SAMU."),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Definir las pestañas disponibles
    final List<Widget> tabs = [
      HomeTab(
        currentHeartRate: _currentHeartRate,
        elapsedTime: _elapsedTime,
        isTrainingActive: _isTrainingActive,
        onToggleTraining: _toggleTraining,
      ),
      const HistoryTab(),
      SosTab(currentHeartRate: _currentHeartRate),
      const AlertsTab(),
      const ProfileTab(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: tabs[_currentIndex],
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF1E1E1E),
        padding: EdgeInsets.zero,
        height: 65,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildTabButton(0, Icons.home, "Inicio"),
            _buildTabButton(1, Icons.history, "Historial"),
            _buildSosCenterItem(),
            _buildTabButton(3, Icons.notifications, "Alertas"),
            _buildTabButton(4, Icons.person, "Perfil"),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? Colors.greenAccent : Colors.grey[600];

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSosCenterItem() {
    final isSelected = _currentIndex == 2;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = 2;
        });
      },
      child: Transform.translate(
        offset: const Offset(0, -10), // Levantar ligeramente el botón SOS
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: Colors.redAccent,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
            border: Border.all(
              color: isSelected ? Colors.white : Colors.redAccent[700]!,
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: const Text(
            "SOS",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
