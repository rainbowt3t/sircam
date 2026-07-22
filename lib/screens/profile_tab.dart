import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class ProfileTab extends StatefulWidget {
  final VoidCallback? onMedicalDataCompleted;
  const ProfileTab({Key? key, this.onMedicalDataCompleted}) : super(key: key);

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _isPremium = false;

  // Datos de usuario principales
  String _userName = "Usuario";
  String _userAge = "--";
  String _userDni = "--------";
  String _userWeight = "--";
  bool _weightIsKg = true;
  String _userHeight = "--";
  bool _heightIsCm = true;
  String _userRegion = "Desconocida";
  String _userDistrict = "Desconocido";
  String _emergencyPhone = "106";

  // Datos médicos editables
  String _bloodType = "";
  String _diseases = "";
  String _allergies = "";
  String _medications = "";

  // Contactos de emergencia editables
  final List<Map<String, String>> _contacts = [
    {"nombre": "María Pérez", "relacion": "Esposa", "cel": "987654321"},
    {"nombre": "Carlos Pérez", "relacion": "Hijo", "cel": "912345678"},
  ];

  // Opciones de configuración
  bool _autoAlertSamu = true;
  double _maxAlertBpm = 125.0;
  double _minAlertBpm = 45.0;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
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

  // Cargar datos guardados específicos del usuario
  Future<void> _loadProfileData() async {
    try {
      final prefix = await _getUserPrefix();
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isPremium = prefs.getBool('${prefix}user_is_premium') ?? false;
        _userName = prefs.getString('${prefix}user_name') ?? "Paciente Ejemplo";
        _userAge = prefs.getString('${prefix}user_age') ?? "72";
        _userDni = prefs.getString('${prefix}user_dni') ?? "12345678";
        _userWeight = prefs.getString('${prefix}user_weight') ?? "75";
        _weightIsKg = prefs.getBool('${prefix}user_weight_is_kg') ?? true;
        _userHeight = prefs.getString('${prefix}user_height') ?? "170";
        _heightIsCm = prefs.getBool('${prefix}user_height_is_cm') ?? true;
        _userRegion = prefs.getString('${prefix}user_region') ?? "La Libertad";
        _userDistrict = prefs.getString('${prefix}user_district') ?? "Chepén";
        _emergencyPhone = prefs.getString('${prefix}emergency_phone') ?? "106";

        _bloodType = prefs.getString('${prefix}user_blood_type') ?? "";
        _diseases = prefs.getString('${prefix}user_diseases') ?? "";
        _allergies = prefs.getString('${prefix}user_allergies') ?? "";
        _medications = prefs.getString('${prefix}user_medications') ?? "";

        // Si hay contacto principal guardado, añadirlo al inicio
        final cName = prefs.getString('${prefix}contact_name');
        final cPhone = prefs.getString('${prefix}contact_phone');
        if (cName != null && cPhone != null) {
          bool exists = _contacts.any((element) => element["cel"] == cPhone);
          if (!exists) {
            _contacts.insert(0, {"nombre": cName, "relacion": "Contacto Principal", "cel": cPhone});
          }
        }
      });
    } catch (e) {
      debugPrint("Error al cargar perfil: $e");
    }
  }

  // Guardar datos modificados específicos de este usuario
  Future<void> _saveProfileData() async {
    try {
      final prefix = await _getUserPrefix();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('${prefix}user_is_premium', _isPremium);
      await prefs.setString('${prefix}user_name', _userName);
      await prefs.setString('${prefix}user_age', _userAge);
      await prefs.setString('${prefix}user_dni', _userDni);
      await prefs.setString('${prefix}user_weight', _userWeight);
      await prefs.setBool('${prefix}user_weight_is_kg', _weightIsKg);
      await prefs.setString('${prefix}user_height', _userHeight);
      await prefs.setBool('${prefix}user_height_is_cm', _heightIsCm);
      await prefs.setString('${prefix}user_region', _userRegion);
      await prefs.setString('${prefix}user_district', _userDistrict);
      await prefs.setString('${prefix}emergency_phone', _emergencyPhone);

      await prefs.setString('${prefix}user_blood_type', _bloodType);
      await prefs.setString('${prefix}user_diseases', _diseases);
      await prefs.setString('${prefix}user_allergies', _allergies);
      await prefs.setString('${prefix}user_medications', _medications);
    } catch (e) {
      debugPrint("Error al guardar perfil: $e");
    }
  }

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
              "Acceso ilimitado a alertas de emergencia automatizadas al SAMU, reportes PDF de historial clínico y personalización de rangos cardíacos por S/. 19.90 al mes.",
              style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),
            
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
                onPressed: () async {
                  Navigator.of(context).pop();
                  setState(() {
                    _isPremium = true;
                  });
                  await _saveProfileData();
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
              "Ahora eres SIRCAM Premium. Se han desbloqueado los reportes PDF, la personalización de límites y el radar live.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("ENTENDIDO", style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _userName);
    final ageController = TextEditingController(text: _userAge);
    final dniController = TextEditingController(text: _userDni);
    final weightController = TextEditingController(text: _userWeight);
    final heightController = TextEditingController(text: _userHeight);
    final regionController = TextEditingController(text: _userRegion);
    final districtController = TextEditingController(text: _userDistrict);
    final emergencyPhoneController = TextEditingController(text: _emergencyPhone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Editar Datos de Perfil", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogField("Nombre Completo", nameController),
              _buildDialogField("Edad (Años)", ageController),
              _buildDialogField("DNI / Identificación", dniController),
              _buildDialogField("Peso", weightController),
              _buildDialogField("Altura", heightController),
              _buildDialogField("Región", regionController),
              _buildDialogField("Distrito / Ciudad", districtController),
              _buildDialogField("Teléfono Emergencia (SAMU)", emergencyPhoneController),
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
            onPressed: () async {
              setState(() {
                _userName = nameController.text;
                _userAge = ageController.text;
                _userDni = dniController.text;
                _userWeight = weightController.text;
                _userHeight = heightController.text;
                _userRegion = regionController.text;
                _userDistrict = districtController.text;
                _emergencyPhone = emergencyPhoneController.text;
              });

              await _saveProfileData();
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("✅ Perfil actualizado correctamente."), backgroundColor: Colors.green),
                );
              }
            },
          ),
        ],
      ),
    );
  }

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
              _buildDialogField("Grupo Sanguíneo (Ej: O+)", bloodController),
              _buildDialogField("Enfermedades Crónicas (Ej: Hipertensión)", diseasesController),
              _buildDialogField("Alergias (Ej: Penicilina o Ninguna)", allergiesController),
              _buildDialogField("Medicamentos Diarios (Ej: Aspirina)", medsController),
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
            onPressed: () async {
              setState(() {
                _bloodType = bloodController.text;
                _diseases = diseasesController.text;
                _allergies = allergiesController.text;
                _medications = medsController.text;
              });
              
              await _saveProfileData();

              if (_bloodType.isNotEmpty && widget.onMedicalDataCompleted != null) {
                widget.onMedicalDataCompleted!();
              }

              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("✅ Información médica actualizada."), backgroundColor: Colors.green),
                );
              }
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
            _buildDialogField("Relación", relationCtrl),
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
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty && celCtrl.text.isNotEmpty) {
                setParentState(() {
                  _contacts.add({
                    "nombre": nameCtrl.text,
                    "relacion": relationCtrl.text,
                    "cel": celCtrl.text,
                  });
                });
                setState(() {});
                
                final prefix = await _getUserPrefix();
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('${prefix}contact_name', nameCtrl.text);
                await prefs.setString('${prefix}contact_phone', celCtrl.text);

                if (context.mounted) {
                  Navigator.of(context).pop();
                }
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
            title: Row(
              children: [
                const Icon(Icons.settings, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  _isPremium ? "Configuración Médica" : "Configuración (Bloqueado)", 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                ),
              ],
            ),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Límites Cardíacos de Alerta", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    if (!_isPremium)
                      const Text("★ Premium", style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                Text("Límite Taquicardia: ${_maxAlertBpm.round()} BPM", style: TextStyle(color: _isPremium ? Colors.redAccent : Colors.grey, fontSize: 12)),
                Slider(
                  min: 100.0,
                  max: 160.0,
                  value: _maxAlertBpm,
                  activeColor: _isPremium ? Colors.redAccent : Colors.grey[700],
                  onChanged: _isPremium ? (val) {
                    setDialogState(() => _maxAlertBpm = val);
                    setState(() => _maxAlertBpm = val);
                  } : null,
                ),
                Text("Límite Bradicardia: ${_minAlertBpm.round()} BPM", style: TextStyle(color: _isPremium ? Colors.amber : Colors.grey, fontSize: 12)),
                Slider(
                  min: 35.0,
                  max: 60.0,
                  value: _minAlertBpm,
                  activeColor: _isPremium ? Colors.amber : Colors.grey[700],
                  onChanged: _isPremium ? (val) {
                    setDialogState(() => _minAlertBpm = val);
                    setState(() => _minAlertBpm = val);
                  } : null,
                ),
                if (!_isPremium)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      "Suscríbete a SIRCAM Premium para personalizar tus límites cardíacos.",
                      style: TextStyle(color: Colors.amber[200], fontSize: 10, fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
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

  void _handleLogout() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint("Error signing out: $e");
    }
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Mi Perfil",
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.greenAccent),
                onPressed: _showEditProfileDialog,
              )
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userName,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$_userAge Años • $_userWeight ${_weightIsKg ? 'Kg' : 'Lbs'}",
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "📍 $_userDistrict, $_userRegion • DNI: $_userDni",
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),

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
                    : "Acceso Premium para alertas cardíacas proactivas al SAMU $_emergencyPhone.",
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

          _buildMenuItem(
            Icons.local_hospital,
            "Información médica",
            _bloodType.isEmpty ? "Pendiente de completar" : "$_bloodType • $_diseases",
            _showMedicalInfoDialog,
          ),
          _buildMenuItem(
            Icons.people,
            "Contactos de emergencia",
            "${_contacts.length} contactos asociados",
            _showEmergencyContactsDialog,
          ),
          _buildMenuItem(
            Icons.bluetooth,
            "Dispositivo",
            "Rockbros HR Monitor (Batería: 85%)",
            _showDeviceDetailsDialog,
          ),
          _buildMenuItem(
            Icons.settings,
            "Configuración",
            _isPremium 
              ? "Notificaciones, límites cardíacos personalizables" 
              : "Límites cardíacos estándar (Suscríbete para editar)",
            _showSettingsDialog,
          ),
          
          const SizedBox(height: 20),
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
    bool isPending = subtitle.contains("Pendiente");
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border(bottom: BorderSide(color: Colors.grey[900]!)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(icon, color: Colors.grey, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: isPending ? Colors.redAccent : Colors.grey[500],
                            fontSize: 12,
                            fontWeight: isPending ? FontWeight.bold : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
