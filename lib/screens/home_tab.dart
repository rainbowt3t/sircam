import 'dart:async';
import 'package:flutter/material.dart';
import '../services/heart_rate_device_service.dart';

class HomeTab extends StatefulWidget {
  final int currentHeartRate;
  final Duration elapsedTime;
  final bool isTrainingActive;
  final VoidCallback onToggleTraining;

  const HomeTab({
    Key? key,
    required this.currentHeartRate,
    required this.elapsedTime,
    required this.isTrainingActive,
    required this.onToggleTraining,
  }) : super(key: key);

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with SingleTickerProviderStateMixin {
  late AnimationController _ecgController;
  final _bleService = HeartRateDeviceService();
  String _lastUpdateString = "Hace 10 seg";
  Timer? _updateTimer;
  DateTime _lastUpdate = DateTime.now();

  @override
  void initState() {
    super.initState();
    
    // Controlador de la onda de electrocardiograma
    _ecgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _updateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (widget.currentHeartRate > 0) {
        _lastUpdate = DateTime.now();
      }
      final diff = DateTime.now().difference(_lastUpdate).inSeconds;
      setState(() {
        if (diff < 5) {
          _lastUpdateString = "Hace 1 seg";
        } else if (diff < 30) {
          _lastUpdateString = "Hace $diff seg";
        } else {
          _lastUpdateString = "Hace 1 min";
        }
      });
    });
  }

  @override
  void dispose() {
    _ecgController.dispose();
    _updateTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  String _getHeartRateStatus(int bpm) {
    if (bpm == 0) return "Desconectado";
    if (bpm < 50) return "Bradicardia detectable";
    if (bpm <= 100) return "Ritmo Normal\nTodo está bien";
    if (bpm <= 120) return "Taquicardia Leve";
    return "Taquicardia Detectada\n¡Alerta de salud!";
  }

  Color _getHeartRateStatusColor(int bpm) {
    if (bpm == 0) return Colors.grey;
    if (bpm < 50) return Colors.amberAccent;
    if (bpm <= 100) return Colors.greenAccent;
    if (bpm <= 120) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getHeartRateStatusColor(widget.currentHeartRate);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjeta de bienvenida
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Hola, Juan Pérez",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Hoy es 07 de mayo de 2024",
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.notifications_none, color: Colors.white, size: 28),
            ],
          ),
          const SizedBox(height: 25),

          // Tarjeta de estado de conexión del sensor
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[850]!),
            ),
            child: StreamBuilder<DeviceConnectionState>(
              stream: _bleService.connectionStateStream,
              initialData: _bleService.currentState,
              builder: (context, snapshot) {
                final state = snapshot.data ?? DeviceConnectionState.disconnected;
                final isConnected = state == DeviceConnectionState.connected;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                          color: isConnected ? Colors.greenAccent : Colors.redAccent,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isConnected ? "Dispositivo conectado" : "Buscando sensor...",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isConnected ? "Rockbros HR Monitor" : "Toca el botón Bluetooth",
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (isConnected)
                      Row(
                        children: [
                          Icon(Icons.battery_5_bar, color: Colors.greenAccent[400], size: 18),
                          const SizedBox(width: 4),
                          const Text(
                            "Batería: 85%",
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 25),

          // Contenedor principal de Frecuencia Cardíaca Actual (Estilo Wahoo)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.grey[850]!),
            ),
            child: Column(
              children: [
                const Text(
                  "FRECUENCIA CARDÍACA ACTUAL",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.favorite,
                      color: Colors.redAccent,
                      size: 40,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.currentHeartRate > 0 ? "${widget.currentHeartRate}" : "--",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 72,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      "lpm",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _getHeartRateStatus(widget.currentHeartRate),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),

                // Gráfico ECG en tiempo real
                SizedBox(
                  height: 90,
                  width: double.infinity,
                  child: AnimatedBuilder(
                    animation: _ecgController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: EcgWavePainter(
                          _ecgController.value,
                          widget.currentHeartRate > 0 ? Colors.greenAccent : Colors.grey[700]!,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("0s", style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                    Text("15s", style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                    Text("30s", style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                    Text("45s", style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                    Text("60s", style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 25),

          // Tarjetas de Tiempo y Actualización
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[850]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "TIEMPO CONECTADO",
                        style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDuration(widget.elapsedTime),
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      const Text("hh : mm : ss", style: TextStyle(color: Colors.grey, fontSize: 9)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[850]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "ÚLTIMA ACTUALIZACIÓN",
                        style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "10:24:30",
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      Text(_lastUpdateString, style: const TextStyle(color: Colors.grey, fontSize: 9)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),

          // Botón Iniciar/Detener Entrenamiento
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isTrainingActive ? Colors.redAccent : Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 3,
              ),
              onPressed: widget.onToggleTraining,
              child: Text(
                widget.isTrainingActive ? "DETENER MONITOREO" : "INICIAR MONITOREO",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// Pintor de Onda ECG
class EcgWavePainter extends CustomPainter {
  final double animationValue;
  final Color color;
  EcgWavePainter(this.animationValue, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    double width = size.width;
    double height = size.height;
    double midY = height / 2;

    path.moveTo(0, midY);

    for (double x = 0; x < width; x++) {
      double localX = (x + animationValue * width) % width;
      double y = midY;
      
      // Frecuencia matemática simulando el ritmo P-Q-R-S-T
      double t = (localX / width) * 10; // escala de 0 a 10
      
      if (t > 1.8 && t < 2.2) {
        // Onda P
        y = midY - 5 * (1 - (t - 2.0).abs() / 0.2).clamp(0.0, 1.0);
      } else if (t > 2.4 && t < 2.6) {
        // Caída Q
        y = midY + 4 * (1 - (t - 2.5).abs() / 0.1).clamp(0.0, 1.0);
      } else if (t >= 2.6 && t < 2.9) {
        // Pico R
        y = midY - 35 * (1 - (t - 2.75).abs() / 0.15).clamp(0.0, 1.0);
      } else if (t >= 2.9 && t < 3.2) {
        // Caída profunda S
        y = midY + 10 * (1 - (t - 3.05).abs() / 0.15).clamp(0.0, 1.0);
      } else if (t > 3.6 && t < 4.2) {
        // Onda T
        y = midY - 8 * (1 - (t - 3.9).abs() / 0.3).clamp(0.0, 1.0);
      }

      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant EcgWavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.color != color;
  }
}
