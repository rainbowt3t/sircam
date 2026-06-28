import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SosTab extends StatelessWidget {
  final int currentHeartRate;
  final bool hasCompletedMedicalData;
  final VoidCallback onRedirectToProfile;

  const SosTab({
    Key? key,
    required this.currentHeartRate,
    required this.hasCompletedMedicalData,
    required this.onRedirectToProfile,
  }) : super(key: key);

  Future<void> _makeEmergencyCall(BuildContext context) async {
    final Uri telUri = Uri.parse('tel:106'); // 106 es el SAMU en Perú

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.redAccent),
            SizedBox(width: 10),
            Text("Confirmar Llamada", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          "¿Está seguro de que desea llamar al SAMU (106)? Se enviará también tu ubicación y ritmo cardíaco actual.",
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            child: const Text("CANCELAR", style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("LLAMAR AHORA", style: TextStyle(color: Colors.white)),
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                if (await canLaunchUrl(telUri)) {
                  await launchUrl(telUri);
                } else {
                  throw "No se pudo realizar la llamada. Asegúrate de tener tarjeta SIM.";
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Simulación de Alerta: Llamada al 106 y reporte enviado. Error técnico: $e"),
                    backgroundColor: Colors.amber[800],
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Si el usuario no ha completado su información médica básica (caso de usuario nuevo)
    if (!hasCompletedMedicalData) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 50),
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.amberAccent,
              size: 85,
            ),
            const SizedBox(height: 24),
            const Text(
              "Ficha médica incompleta",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Por favor, completa tu información médica para casos de urgencia en tu Perfil antes de poder utilizar el botón de pánico SOS.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () {
                  // Mostrar el diálogo interactivo solicitado por el usuario
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF1E1E1E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      title: const Text(
                        "Información médica requerida",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      content: const Text(
                        "Por favor completa los datos o la información para casos de urgencia.",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      actions: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.greenAccent,
                            foregroundColor: Colors.black,
                          ),
                          child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () {
                            Navigator.of(context).pop(); // Cerrar diálogo
                            onRedirectToProfile();       // Redirigir a pestaña Perfil
                          },
                        )
                      ],
                    ),
                  );
                },
                child: const Text(
                  "COMPLETAR AHORA",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Pantalla de SOS normal para usuarios que sí tienen sus datos registrados
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          const Text(
            "SOS",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),

          const Text(
            "¿Necesitas ayuda?",
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Presiona el botón para\nenviar una alerta al SAMU",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 50),

          // Botón SOS Gigante Circular
          GestureDetector(
            onTap: () => _makeEmergencyCall(context),
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.redAccent.withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
                border: Border.all(color: Colors.white, width: 6),
              ),
              alignment: Alignment.center,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.call,
                    color: Colors.white,
                    size: 55,
                  ),
                  SizedBox(height: 12),
                  Text(
                    "ENVIAR\nALERTA",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 60),

          // Panel informativo inferior
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[850]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Alerta será enviada con:",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow(Icons.my_location, Colors.amberAccent, "Tu ubicación actual (Tarma, Junín, Perú)"),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.favorite,
                  Colors.redAccent,
                  currentHeartRate > 0 ? "Tu frecuencia cardíaca: $currentHeartRate lpm" : "Tu frecuencia cardíaca: -- lpm",
                ),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.folder_shared, Colors.blueAccent, "Tu información médica básica"),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
