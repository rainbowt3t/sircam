import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/heart_rate_device_service.dart';

class ConnectionStatusWidget extends StatelessWidget {
  const ConnectionStatusWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bleService = HeartRateDeviceService();

    return StreamBuilder<BluetoothAdapterState>(
      stream: bleService.adapterStateStream,
      initialData: BluetoothAdapterState.unknown,
      builder: (context, adapterSnapshot) {
        final adapterState = adapterSnapshot.data ?? BluetoothAdapterState.unknown;

        // Si el Bluetooth está apagado, mostramos advertencia y opción de encender
        if (adapterState == BluetoothAdapterState.off ||
            adapterState == BluetoothAdapterState.turningOff ||
            adapterState == BluetoothAdapterState.unauthorized) {
          return GestureDetector(
            onTap: () => bleService.turnOnBluetooth(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.amberAccent.withOpacity(0.5), width: 1.5),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bluetooth_disabled, color: Colors.amberAccent, size: 20),
                    SizedBox(width: 10),
                    Text(
                      "Bluetooth Apagado (Presiona para Activar)",
                      style: TextStyle(
                        color: Colors.amberAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Si el Bluetooth está encendido o en estado desconocido temporal, procedemos con los estados de conexión
        return StreamBuilder<DeviceConnectionState>(
          stream: bleService.connectionStateStream,
          initialData: bleService.currentState,
          builder: (context, snapshot) {
            final state = snapshot.data ?? DeviceConnectionState.disconnected;

            Color backgroundColor;
            Color textColor;
            String label;
            IconData icon;
            VoidCallback? onTap;
            bool isAnimated = false;

            switch (state) {
              case DeviceConnectionState.disconnected:
                backgroundColor = Colors.red.withOpacity(0.1);
                textColor = Colors.redAccent;
                label = "Sensor Desconectado (Presiona para Buscar)";
                icon = Icons.bluetooth_disabled;
                onTap = () => bleService.startScan();
                break;
              case DeviceConnectionState.scanning:
                backgroundColor = Colors.blue.withOpacity(0.1);
                textColor = Colors.blueAccent;
                label = "Buscando Sensor Rockbros...";
                icon = Icons.bluetooth_searching;
                onTap = () => bleService.stopScan();
                isAnimated = true;
                break;
              case DeviceConnectionState.connecting:
                backgroundColor = Colors.orange.withOpacity(0.1);
                textColor = Colors.orangeAccent;
                label = "Conectando...";
                icon = Icons.bluetooth_connected;
                onTap = null;
                break;
              case DeviceConnectionState.connected:
                backgroundColor = Colors.green.withOpacity(0.1);
                textColor = Colors.greenAccent;
                label = "Rockbros Conectado";
                icon = Icons.bluetooth;
                onTap = () => bleService.disconnect();
                break;
            }

            return GestureDetector(
              onTap: onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const Duration(milliseconds: 300).millisecondsCompare(isAnimated),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: textColor.withOpacity(0.5), width: 1.5),
                  boxShadow: state == DeviceConnectionState.connected
                      ? [
                          BoxShadow(
                            color: Colors.greenAccent.withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 2,
                          )
                        ]
                      : [],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      isAnimated ? const _BlinkingIcon(icon: Icons.bluetooth_searching, color: Colors.blueAccent) : Icon(icon, color: textColor, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        label,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _BlinkingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;

  const _BlinkingIcon({required this.icon, required this.color});

  @override
  State<_BlinkingIcon> createState() => _BlinkingIconState();
}

class _BlinkingIconState extends State<_BlinkingIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Icon(widget.icon, color: widget.color, size: 20),
    );
  }
}

extension DurationCompare on Duration {
  EdgeInsets millisecondsCompare(bool condition) {
    return condition ? const EdgeInsets.all(4) : const EdgeInsets.all(0);
  }
}
