import 'package:isar_community/isar.dart';

part 'heart_rate_data.g.dart';

@collection
class HeartRateDataPoint {
  Id id = Isar.autoIncrement;

  int bpm;
  
  DateTime timestamp;

  HeartRateDataPoint({
    required this.bpm,
    required this.timestamp,
  });

  // Convert to simple Map for lightweight JSON payload in Firebase
  Map<String, dynamic> toJson() => {
    'b': bpm,
    't': timestamp.millisecondsSinceEpoch,
  };
}

@collection
class TrainingSession {
  Id id = Isar.autoIncrement;

  DateTime startTime;
  
  DateTime? endTime;
  
  double? averageBpm;
  
  int? maxBpm;

  // Relation to individual data points in this session
  final dataPoints = IsarLinks<HeartRateDataPoint>();

  TrainingSession({
    required this.startTime,
    this.endTime,
    this.averageBpm,
    this.maxBpm,
  });
}

@collection
class CardiacAlert {
  Id id = Isar.autoIncrement;

  late String title;
  late String description;
  late DateTime timestamp;
  late int heartRate;
  late String type; // 'critica', 'informativa', 'normal'

  CardiacAlert({
    required this.title,
    required this.description,
    required this.timestamp,
    required this.heartRate,
    required this.type,
  });
}
