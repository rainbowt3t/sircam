import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/heart_rate_data.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  /// Inicia sesión de forma anónima para permitir accesos rápidos y seguros
  Future<UserCredential> signInAnonymously() async {
    // Si ya hay un usuario logueado, retornamos su estado actual
    if (_auth.currentUser != null) {
      return UserCredentialMock(_auth.currentUser!);
    }
    return await _auth.signInAnonymously();
  }

  /// Sube el resumen y los puntos serializados en un solo documento
  /// Optimización Spark Plan: 1 sesión = 1 escritura en lugar de miles de escrituras individuales
  Future<void> uploadSession(TrainingSession session) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("El usuario debe estar autenticado para subir entrenamientos.");
    }

    // Asegurarse de que los puntos de Isar estén cargados en memoria
    await session.dataPoints.load();
    final points = session.dataPoints.toList();

    // Mapear los puntos a JSON liviano
    final List<Map<String, dynamic>> pointsJsonList = points.map((p) => p.toJson()).toList();
    
    // Serializar a una cadena JSON (ahorra espacio y lecturas en Firestore)
    final String serializedPoints = jsonEncode(pointsJsonList);

    // Preparar el payload del documento
    final Map<String, dynamic> sessionPayload = {
      'userId': user.uid,
      'sessionIdLocal': session.id,
      'startTime': session.startTime.toIso8601String(),
      'endTime': session.endTime?.toIso8601String(),
      'averageBpm': session.averageBpm,
      'maxBpm': session.maxBpm,
      'pointsCount': pointsJsonList.length,
      // La lista completa serializada
      'rawDataPointsJson': serializedPoints,
      'uploadedAt': FieldValue.serverTimestamp(),
    };

    // Subir a Firestore bajo la colección optimizada
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('sessions')
        .doc(session.id.toString())
        .set(sessionPayload, SetOptions(merge: true));
  }
}

/// Clase Mock auxiliar para retornar una credencial si el usuario ya está autenticado
class UserCredentialMock implements UserCredential {
  final User _user;
  UserCredentialMock(this._user);
  
  @override
  User? get user => _user;
  
  @override
  AuthCredential? get credential => null;
  
  @override
  AdditionalUserInfo? get additionalUserInfo => null;
}
