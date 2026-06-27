import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/heart_rate_data.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Isar? _isar;
  TrainingSession? _activeSession;

  Isar get isar {
    if (_isar == null) {
      throw Exception("Isar no ha sido inicializado. Llama a initialize() primero.");
    }
    return _isar!;
  }

  TrainingSession? get activeSession => _activeSession;

  /// Inicializa la base de datos local Isar
  Future<void> initialize() async {
    if (_isar != null) return;
    
    // Obtener directorio del sistema para almacenar la BD local
    final dir = await getApplicationDocumentsDirectory();
    
    _isar = await Isar.open(
      [HeartRateDataPointSchema, TrainingSessionSchema, CardiacAlertSchema],
      directory: dir.path,
      inspector: true, // Habilita el inspector de base de datos de Isar en desarrollo
    );

    // Insertar alertas de demostración si la colección está vacía (Para simular la UI de SIRCAM)
    final count = await _isar!.cardiacAlerts.count();
    if (count == 0) {
      await _isar!.writeTxn(() async {
        await _isar!.cardiacAlerts.put(CardiacAlert(
          title: "Taquicardia detectada",
          description: "Frecuencia: 112 lpm\nDuración: 2 min",
          timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
          heartRate: 112,
          type: "critica",
        ));
        await _isar!.cardiacAlerts.put(CardiacAlert(
          title: "Señal débil",
          description: "Pérdida de señal por más de 5 minutos",
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          heartRate: 0,
          type: "informativa",
        ));
        await _isar!.cardiacAlerts.put(CardiacAlert(
          title: "Señal débil",
          description: "Pérdida de señal por más de 6 minutos",
          timestamp: DateTime.now().subtract(const Duration(hours: 4)),
          heartRate: 0,
          type: "informativa",
        ));
        await _isar!.cardiacAlerts.put(CardiacAlert(
          title: "Ritmo normal",
          description: "Todo dentro de los parámetros normales",
          timestamp: DateTime.now().subtract(const Duration(hours: 6)),
          heartRate: 72,
          type: "normal",
        ));
      });
    }
  }

  /// Comienza una nueva sesión de entrenamiento
  Future<TrainingSession> startSession() async {
    // Si ya hay una sesión activa, la cerramos primero
    if (_activeSession != null) {
      await stopSession();
    }

    final session = TrainingSession(startTime: DateTime.now());
    
    await isar.writeTxn(() async {
      await isar.trainingSessions.put(session);
    });

    _activeSession = session;
    return session;
  }

  /// Guarda un latido de corazón en la sesión activa en tiempo real
  Future<void> saveHeartRatePoint(int bpm) async {
    if (_activeSession == null) return;

    final dataPoint = HeartRateDataPoint(
      bpm: bpm,
      timestamp: DateTime.now(),
    );

    await isar.writeTxn(() async {
      // Guardar el punto de ritmo cardíaco
      await isar.heartRateDataPoints.put(dataPoint);
      
      // Vincular el punto a la sesión actual
      _activeSession!.dataPoints.add(dataPoint);
      await _activeSession!.dataPoints.save();
    });
  }

  /// Finaliza la sesión actual y calcula las métricas finales (Max BPM y Promedio)
  Future<TrainingSession?> stopSession() async {
    if (_activeSession == null) return null;

    final session = _activeSession!;
    _activeSession = null;

    await isar.writeTxn(() async {
      // Cargar los puntos para calcular estadísticas
      await session.dataPoints.load();
      final points = session.dataPoints.toList();

      if (points.isNotEmpty) {
        int max = 0;
        int sum = 0;
        for (var p in points) {
          final int bpmVal = p.bpm;
          if (bpmVal > max) max = bpmVal;
          sum += bpmVal;
        }
        
        session.maxBpm = max;
        session.averageBpm = sum / points.length;
      } else {
        session.maxBpm = 0;
        session.averageBpm = 0.0;
      }

      session.endTime = DateTime.now();

      // Guardar cambios finales de la sesión
      await isar.trainingSessions.put(session);
    });

    return session;
  }

  /// Obtiene el historial de sesiones guardadas
  Future<List<TrainingSession>> getSessions() async {
    return await isar.trainingSessions.where().sortByStartTimeDesc().findAll();
  }

  /// Elimina una sesión y sus puntos asociados
  Future<void> deleteSession(int sessionId) async {
    final session = await isar.trainingSessions.get(sessionId);
    if (session == null) return;

    await isar.writeTxn(() async {
      await session.dataPoints.load();
      final points = session.dataPoints.toList();
      
      // Eliminar todos los puntos asociados para no dejar huérfanos
      for (var p in points) {
        await isar.heartRateDataPoints.delete(p.id);
      }
      // Eliminar la sesión
      await isar.trainingSessions.delete(sessionId);
    });
  }

  /// Registra una nueva alerta cardíaca en Isar
  Future<void> saveAlert(CardiacAlert alert) async {
    await isar.writeTxn(() async {
      await isar.cardiacAlerts.put(alert);
    });
  }

  /// Obtiene la lista de alertas ordenadas por fecha descendente
  Future<List<CardiacAlert>> getAlerts() async {
    return await isar.cardiacAlerts.where().sortByTimestampDesc().findAll();
  }
}
