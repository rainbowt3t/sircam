import 'package:isar/isar.dart';

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
