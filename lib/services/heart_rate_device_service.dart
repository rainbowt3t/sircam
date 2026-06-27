import 'dart:async';
import 'dart:math';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

enum DeviceConnectionState { disconnected, scanning, connecting, connected }

class HeartRateDeviceService {
  // Patrón Singleton para acceder desde cualquier parte de la aplicación
  static final HeartRateDeviceService _instance = HeartRateDeviceService._internal();
  factory HeartRateDeviceService() => _instance;
  HeartRateDeviceService._internal();

  BluetoothDevice? _connectedDevice;
  StreamSubscription<List<int>>? _valueSubscription;
  StreamSubscription<BluetoothConnectionState>? _stateSubscription;
  
  final _heartRateController = StreamController<int>.broadcast();
  Stream<int> get heartRateStream => _heartRateController.stream;

  final _connectionStateController = StreamController<DeviceConnectionState>.broadcast();
  Stream<DeviceConnectionState> get connectionStateStream => _connectionStateController.stream;

  DeviceConnectionState _currentState = DeviceConnectionState.disconnected;
  DeviceConnectionState get currentState => _currentState;

  int _reconnectAttempts = 0;
  bool _shouldReconnect = false;
  Timer? _reconnectTimer;

  // UUIDs universales del GATT de Bluetooth SIG
  final String _heartRateServiceUuid = "180d"; // Heart Rate Service
  final String _heartRateCharUuid = "2a37";    // Heart Rate Measurement

  void _updateState(DeviceConnectionState state) {
    _currentState = state;
    _connectionStateController.add(state);
  }

  /// Inicia el escaneo de dispositivos filtrando por el Service UUID 0x180D (Ritmo Cardíaco)
  Future<void> startScan() async {
    if (_currentState == DeviceConnectionState.scanning || _currentState == DeviceConnectionState.connected) return;

    _updateState(DeviceConnectionState.scanning);

    try {
      // Inicia el escaneo filtrado para ahorrar batería y CPU
      await FlutterBluePlus.startScan(
        withServices: [Guid(_heartRateServiceUuid)],
        timeout: const Duration(seconds: 30),
      );

      // Escuchar los dispositivos encontrados
      StreamSubscription<List<ScanResult>>? scanSubscription;
      scanSubscription = FlutterBluePlus.scanResults.listen((results) async {
        for (ScanResult r in results) {
          if (r.advertisementData.serviceUuids.contains(Guid(_heartRateServiceUuid))) {
            // Cancelar el scan y la suscripción de escaneo antes de conectar (Evita consumos e inestabilidad)
            await FlutterBluePlus.stopScan();
            scanSubscription?.cancel();
            
            // Conectar al monitor Rockbros
            connectToDevice(r.device);
            break;
          }
        }
      });

      // Detiene el estado visual si termina el tiempo de escaneo sin conectar
      FlutterBluePlus.isScanning.listen((isScanning) {
        if (!isScanning && _currentState == DeviceConnectionState.scanning) {
          _updateState(DeviceConnectionState.disconnected);
        }
      });

    } catch (e) {
      _updateState(DeviceConnectionState.disconnected);
    }
  }

  /// Detiene el escaneo actual
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    if (_currentState == DeviceConnectionState.scanning) {
      _updateState(DeviceConnectionState.disconnected);
    }
  }

  /// Conecta al dispositivo Bluetooth seleccionado
  Future<void> connectToDevice(BluetoothDevice device) async {
    _shouldReconnect = true;
    _connectedDevice = device;
    _updateState(DeviceConnectionState.connecting);
    
    await FlutterBluePlus.stopScan();

    try {
      // Conectar al dispositivo Rockbros
      await device.connect(autoConnect: false, timeout: const Duration(seconds: 15));
      
      _reconnectAttempts = 0; // Reset del backoff exponencial
      _updateState(DeviceConnectionState.connected);
      
      // Escuchar desconexión inesperada
      _stateSubscription?.cancel();
      _stateSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnect();
        }
      });

      // Descubrir y suscribirse a la lectura del ritmo cardíaco
      await _discoverAndSubscribe();

    } catch (e) {
      _handleDisconnect();
    }
  }

  /// Procesa la desconexión del dispositivo
  void _handleDisconnect() {
    _valueSubscription?.cancel();
    _updateState(DeviceConnectionState.disconnected);
    
    // Si la desconexión fue inesperada y tenemos un dispositivo asignado, reconectar
    if (_shouldReconnect && _connectedDevice != null) {
      _scheduleReconnect();
    }
  }

  /// Planifica una reconexión con Backoff Exponencial para evitar saturar el hardware
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    
    // Tiempo de retraso exponencial: 1s, 2s, 4s, 8s, 16s, 32s, 64s
    int delaySeconds = pow(2, _reconnectAttempts).toInt();
    if (delaySeconds > 64) delaySeconds = 64;

    _reconnectAttempts++;
    
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      if (_connectedDevice != null && _currentState != DeviceConnectionState.connected) {
        connectToDevice(_connectedDevice!);
      }
    });
  }

  /// Descubre los servicios del dispositivo y se suscribe a la característica del ritmo cardíaco 0x2A37
  Future<void> _discoverAndSubscribe() async {
    if (_connectedDevice == null) return;
    
    try {
      List<BluetoothService> services = await _connectedDevice!.discoverServices();
      BluetoothService? hrService;
      
      for (var s in services) {
        if (s.uuid.toString().toLowerCase().contains(_heartRateServiceUuid)) {
          hrService = s;
          break;
        }
      }

      if (hrService != null) {
        BluetoothCharacteristic? hrChar;
        for (var c in hrService.characteristics) {
          if (c.uuid.toString().toLowerCase().contains(_heartRateCharUuid)) {
            hrChar = c;
            break;
          }
        }

        if (hrChar != null) {
          // Activar notificaciones (suscripción) de la característica
          await hrChar.setNotifyValue(true);
          
          _valueSubscription?.cancel();
          _valueSubscription = hrChar.onValueReceived.listen((value) {
            int bpm = _parseHeartRate(value);
            if (bpm > 0) {
              _heartRateController.add(bpm);
            }
          });
        }
      }
    } catch (e) {
      // Manejo silencioso de errores de conexión GATT
    }
  }

  /// Parsea la lectura cruda de bytes del estándar BLE GATT 0x2A37
  int _parseHeartRate(List<int> value) {
    if (value.isEmpty) return 0;
    
    // El primer byte define las banderas (Flags)
    int flags = value[0];
    
    // bit 0 indica el formato: 0 = UINT8 (1 byte de datos), 1 = UINT16 (2 bytes de datos)
    bool is16bit = (flags & 0x01) != 0;
    
    if (is16bit) {
      if (value.length >= 3) {
        // Formato UINT16: LSB (Byte 1) y MSB (Byte 2)
        return (value[2] << 8) | value[1];
      }
    } else {
      if (value.length >= 2) {
        // Formato UINT8
        return value[1];
      }
    }
    return 0;
  }

  /// Desconexión manual limpia y detención de reconexión automática
  Future<void> disconnect() async {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _stateSubscription?.cancel();
    _valueSubscription?.cancel();
    
    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
      } catch (e) {
        // Ignorar si ya está desconectado
      }
      _connectedDevice = null;
    }
    
    _updateState(DeviceConnectionState.disconnected);
  }

  void dispose() {
    disconnect();
    _heartRateController.close();
    _connectionStateController.close();
  }
}
