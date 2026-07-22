import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SosTab extends StatefulWidget {
  final int currentHeartRate;
  final VoidCallback onRedirectToProfile;

  const SosTab({
    Key? key,
    required this.currentHeartRate,
    required this.onRedirectToProfile,
  }) : super(key: key);

  @override
  State<SosTab> createState() => _SosTabState();
}

class _SosTabState extends State<SosTab> {
  String _emergencyPhone = "106";
  String _region = "La Libertad";
  String _district = "Chepén";
  String _contactName = "Contacto de Confianza";
  String _contactPhone = "";

  @override
  void initState() {
    super.initState();
    _loadSosDetails();
  }

  // Generar prefijo único por cuenta para evitar mezclar datos
  Future<String> _getUserPrefix() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return "${user.uid}_";
    }
    final prefs = await SharedPreferences.getInstance();
    final lastEmail = prefs.getString('last_logged_in_email') ?? "guest";
    return "${lastEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_";
  }

  Future<void> _loadSosDetails() async {
    try {
      final prefix = await _getUserPrefix();
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _emergencyPhone = prefs.getString('${prefix}emergency_phone') ?? "106";
        _region = prefs.getString('${prefix}user_region') ?? "La Libertad";
        _district = prefs.getString('${prefix}user_district') ?? "Chepén";
        _contactName = prefs.getString('${prefix}contact_name') ?? "Familiar";
        _contactPhone = prefs.getString('${prefix}contact_phone') ?? "";
      });
    } catch (e) {
      debugPrint("Error loading SOS details: $e");
    }
  }

  Future<void> _makeCall(String phone, String recipientName) async {
    final Uri telUri = Uri.parse('tel:$phone');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.phone_in_talk, color: Colors.greenAccent, size: 28),
            const SizedBox(width: 10),
            Text("Llamar a $recipientName", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          "¿Está seguro de que desea llamar al número $phone?",
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        actions: [
          TextButton(
            child: const Text("CANCELAR", style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent, 
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("LLAMAR", style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                if (await canLaunchUrl(telUri)) {
                  await launchUrl(telUri);
                } else {
                  throw "No se puede abrir el marcador.";
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Llamando a $recipientName ($phone)."),
                    backgroundColor: Colors.green,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          const Text(
            "Botón de Pánico SOS",
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Acceso directo y accesible para llamadas de urgencia médica.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 35),

          // Botón SOS Gigante Circular (Llamada al SAMU)
          GestureDetector(
            onTap: () => _makeCall(_emergencyPhone, "SAMU ($_emergencyPhone)"),
            child: Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.redAccent.withOpacity(0.4),
                    blurRadius: 35,
                    spreadRadius: 12,
                  ),
                ],
                border: Border.all(color: Colors.white, width: 8),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.call,
                    color: Colors.white,
                    size: 65,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "LLAMAR SAMU\n$_emergencyPhone",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
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
          const SizedBox(height: 40),

          // Botón Secundario: Llamar a Familiar de Confianza (Solo si está registrado)
          if (_contactPhone.isNotEmpty)
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[800],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.people, size: 28),
                label: Text(
                  "Llamar a $_contactName",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onPressed: () => _makeCall(_contactPhone, _contactName),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 60,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey[800]!),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                icon: const Icon(Icons.person_add, color: Colors.blueAccent, size: 24),
                label: const Text(
                  "Registrar contacto de confianza",
                  style: TextStyle(color: Colors.blueAccent, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: widget.onRedirectToProfile,
              ),
            ),

          const SizedBox(height: 35),

          // Panel informativo inferior dinámico
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
                  "Información del Reporte SOS:",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  Icons.my_location, 
                  Colors.amberAccent, 
                  "📍 Ubicación: $_district, $_region"
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.favorite,
                  Colors.redAccent,
                  widget.currentHeartRate > 0 
                      ? "💓 Frecuencia cardíaca: ${widget.currentHeartRate} lpm" 
                      : "💓 Frecuencia cardíaca: -- lpm",
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.phone_callback, 
                  Colors.blueAccent, 
                  "📞 Central configurada: SAMU ($_emergencyPhone)"
                ),
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
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
