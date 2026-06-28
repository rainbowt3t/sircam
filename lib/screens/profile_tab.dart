import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _isPremium = false;

  // Datos médicos editables en tiempo de ejecución (Isar / Memoria)
  String _bloodType = "O+";
  String _diseases = "Hipertensión, Arritmia";
  String _allergies = "Ninguna";
  String _medications = "Aspirina 100mg";

  // Contactos de emergencia editables
  final List<Map<String, String>> _contacts = [
    {"nombre": "María Pérez", "relacion": "Esposa", "cel": "987654321"},
    {"nombre": "Carlos Pérez", "relacion": "Hijo", "cel": "912345678"},
  ];

  // Opciones de configuración
  bool _autoAlertSamu = true;
  double _maxAlertBpm = 125.0;
  double _minAlertBpm = 45.0;

  void _showSubscriptionBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 28),
                SizedBox(width: 8),
                Text(
                  "SIRCAM PREMIUM",
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              "Obtén acceso ilimitado a alertas autónomas inteligentes 24/7 y enlace telefónico automático prioritario con los servicios médicos del SAMU por solo S/. 19.90 al mes.",
              style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),
            
            // Campos de tarjeta simulados
            TextField(
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Número de tarjeta",
                labelStyle: TextStyle(color: Colors.grey[500]),
                filled: true,
                fillColor: const Color(0xFF121212),
                prefixIcon: const Icon(Icons.credit_card, color: Colors.greenAccent),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.greenAccent),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.datetime,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "MM/AA",
                      labelStyle: TextStyle(color: Colors.grey[500]),
                      filled: true,
                      fillColor: const Color(0xFF121212),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "CVV",
                      labelStyle: TextStyle(color: Colors.grey[500]),
                      filled: true,
                      fillColor: const Color(0xFF121212),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // Botón de pago en Soles
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent[400],
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  _simulatePaymentSuccess();
                },
                child: const Text(
                  "SUSCRIBIRSE POR S/. 19.90",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _simulatePaymentSuccess() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.greenAccent, size: 70),
            const SizedBox(height: 20),
            const Text(
              "¡Suscripción Exitosa!",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Ahora eres SIRCAM Premium. El monitoreo proactivo del SAMU está activo en tu cuenta.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("ENTENDIDO", style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _isPremium = true;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogout() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  // --- DIÁLOGOS DE OPCIONES FUNCIONALES ---

  void _showMedicalInfoDialog() {
    final bloodController = TextEditingController(text: _bloodType);
    final diseasesController = TextEditingController(text: _diseases);
    final allergiesController = TextEditingController(text: _allergies);
    final medsController = TextEditingController(text: _medications);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Editar Información Médica", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogField("Grupo Sanguíneo", bloodController),
              _buildDialogField("Enfermedades Crónicas", diseasesController),
              _buildDialogField("Alergias", allergiesController),
              _buildDialogField("Medicamentos Diarios", medsController),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text("CANCELAR", style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black),
            child: const Text("GUARDAR", style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              setState(() {
                _bloodType = bloodController.text;
                _diseases = diseasesController.text;
                _allergies = allergiesController.text;
                _medications = medsController.text;
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("✅ Información médica actualizada."), backgroundColor: Colors.green),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDialogField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
          filled: true,
          fillColor: const Color(0xFF121212),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[850]!),
          ),
        ),
      ),
    );
  }

  void _showEmergencyContactsDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Contactos de Emergencia", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ..._contacts.map((c) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121212),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c["nombre"]!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            Text("${c["relacion"]!} • Cel: ${c["cel"]!}", style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                          ],
                        ),
                        // Botón de llamada real / simulada
                        IconButton(
                          icon: const Icon(Icons.call, color: Colors.greenAccent, size: 20),
                          onPressed: () async {
                            final Uri tel = Uri.parse("tel:${c["cel"]!}");
                            try {
                              if (await canLaunchUrl(tel)) {
                                await launchUrl(tel);
                              } else {
                                throw "No se pudo realizar la llamada.";
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Llamando a ${c["nombre"]} (${c["cel"]}): $e"), backgroundColor: Colors.green),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  )).toList(),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[850],
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text("AGREGAR CONTACTO"),
                    onPressed: () {
                      _showAddContactDialog(setDialogState);
                    },
                  )
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text("CERRAR", style: TextStyle(color: Colors.grey)),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddContactDialog(StateSetter setParentState) {
    final nameCtrl = TextEditingController();
    final relationCtrl = TextEditingController();
    final celCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Nuevo Contacto", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogField("Nombre Completo", nameCtrl),
            _buildDialogField("Relación (Ej: Hijo, Esposa)", relationCtrl),
            _buildDialogField("Número Celular", celCtrl),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("CANCELAR", style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black),
            child: const Text("AÑADIR"),
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && celCtrl.text.isNotEmpty) {
                setParentState(() {
                  _contacts.add({
                    "nombre": nameCtrl.text,
                    "relacion": relationCtrl.text,
                    "cel": celCtrl.text,
                  });
                });
                setState(() {}); // Actualiza la pantalla de perfil externa
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  void _showDeviceDetailsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Detalles del Dispositivo", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(Icons.bluetooth, "Nombre: Rockbros HR Monitor"),
            _buildInfoRow(Icons.perm_identity, "ID Técnico: D4:42:3F:8A:2C:19"),
            _buildInfoRow(Icons.battery_5_bar, "Nivel de Batería: 85%"),
            _buildInfoRow(Icons.signal_cellular_alt, "Fuerza de Señal: -65 dBm (Excelente)"),
            _buildInfoRow(Icons.settings_input_antenna, "Servicio GATT: 0x180D (Heart Rate)"),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("CERRAR", style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.greenAccent, size: 18),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Configuración Médica", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text("Llamada al SAMU automática", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text("Activa alerta si no hay respuesta en 10s.", style: TextStyle(color: Colors.grey, fontSize: 11)),
                  value: _autoAlertSamu,
                  activeColor: Colors.greenAccent,
                  onChanged: (val) {
                    setDialogState(() => _autoAlertSamu = val);
                    setState(() => _autoAlertSamu = val);
                  },
                ),
                const Divider(color: Colors.grey),
                const SizedBox(height: 8),
                const Text("Umbrales Cardíacos de Alerta", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text("Límite Taquicardia: ${_maxAlertBpm.round()} BPM", style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                Slider(
                  min: 100,
                  max: 160,
                  value: _maxAlertBpm,
                  activeColor: Colors.redAccent,
                  onChanged: (val) {
                    setDialogState(() => _maxAlertBpm = val);
                    setState(() => _maxAlertBpm = val);
                  },
                ),
                Text("Límite Bradicardia: ${_minAlertBpm.round()} BPM", style: const TextStyle(color: Colors.amberAccent, fontSize: 12)),
                Slider(
                  min: 35,
                  max: 60,
                  value: _minAlertBpm,
                  activeColor: Colors.amber,
                  onChanged: (val) {
                    setDialogState(() => _minAlertBpm = val);
                    setState(() => _minAlertBpm = val);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text("CERRAR", style: TextStyle(color: Colors.grey)),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera Perfil
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Mi Perfil",
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.greenAccent),
                onPressed: () {},
              )
            ],
          ),
          const SizedBox(height: 20),

          // Datos de Juan Pérez
          Row(
            children: [
              // Avatar
              Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.greenAccent, width: 2),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 45),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Juan Pérez",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "72 Años",
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "DNI: 12345678",
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 25),

          // Tarjeta de Suscripción Premium
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isPremium 
                  ? [Colors.teal[700]!, Colors.teal[900]!] 
                  : [Colors.deepPurple[700]!, Colors.deepPurple[900]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (_isPremium ? Colors.teal : Colors.deepPurple).withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isPremium ? "★ PLAN PREMIUM ACTIVO" : "★ MEJORAR A PREMIUM",
                      style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.0),
                    ),
                    if (_isPremium)
                      const Icon(Icons.verified, color: Colors.greenAccent, size: 20),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _isPremium 
                    ? "Tienes acceso prioritario e inteligente al SAMU y alertas en tiempo real." 
                    : "Acceso Premium para alertas cardíacas proactivas al SAMU 106.",
                  style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
                ),
                const SizedBox(height: 15),
                if (!_isPremium)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.deepPurple[900],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _showSubscriptionBottomSheet,
                    child: const Text("SUSCRIBIRSE (S/. 19.90 / mes)", style: TextStyle(fontWeight: FontWeight.bold)),
                  )
                else
                  const Text(
                    "Socio Benefactor de SIRCAM - S/. 19.90/mes pagado",
                    style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 25),

          // Menu de opciones funcionales
          _buildMenuItem(Icons.local_hospital, "Información médica", _diseases, _showMedicalInfoDialog),
          _buildMenuItem(Icons.people, "Contactos de emergencia", "${_contacts.length} contactos asociados", _showEmergencyContactsDialog),
          _buildMenuItem(Icons.bluetooth, "Dispositivo", "Rockbros HR Monitor (Batería: 85%)", _showDeviceDetailsDialog),
          _buildMenuItem(Icons.settings, "Configuración", "Notificaciones, límites cardíacos", _showSettingsDialog),
          
          const SizedBox(height: 20),
          // Cerrar sesión
          GestureDetector(
            onTap: _handleLogout,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[900]!)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.exit_to_app, color: Colors.redAccent),
                  SizedBox(width: 16),
                  Text(
                    "Cerrar sesión",
                    style: TextStyle(color: Colors.redAccent, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent, // Asegura que toda la celda responda al tap
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[900]!)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.grey, size: 24),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
