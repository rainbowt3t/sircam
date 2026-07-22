import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'workout_screen.dart';

class OnboardingWizardScreen extends StatefulWidget {
  const OnboardingWizardScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingWizardScreen> createState() => _OnboardingWizardScreenState();
}

class _OnboardingWizardScreenState extends State<OnboardingWizardScreen> {
  final _pageController = PageController();
  int _currentStep = 0;

  // Paso 2: Datos Físicos
  final _ageController = TextEditingController(text: "65");
  final _weightController = TextEditingController(text: "70");
  final _heightController = TextEditingController(text: "165");
  bool _isKg = true; // true = Kg, false = Lbs
  bool _isCm = true; // true = cm, false = inches

  // Paso 3: Ubicación y Emergencia
  final _regionController = TextEditingController();
  final _districtController = TextEditingController();
  final _emergencyNumController = TextEditingController(text: "106");
  bool _isGpsLoading = false;
  bool _gpsFetched = false;

  // Paso 4: Contacto de Emergencia
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _regionController.dispose();
    _districtController.dispose();
    _emergencyNumController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
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

  // Simular lectura de GPS y geocodificación
  Future<void> _fetchGpsLocation() async {
    setState(() {
      _isGpsLoading = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _regionController.text = "La Libertad";
      _districtController.text = "Chepén";
      _emergencyNumController.text = "106"; // SAMU local en Perú
      _isGpsLoading = false;
      _gpsFetched = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("📍 Ubicación y servicio SAMU detectados con éxito."),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Guardar datos en SharedPreferences prefijados por el UID del usuario
  Future<void> _saveWizardData() async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = await _getUserPrefix();
    
    // Guardar peso, altura y edad
    await prefs.setString('${prefix}user_age', _ageController.text);
    await prefs.setString('${prefix}user_weight', _weightController.text);
    await prefs.setBool('${prefix}user_weight_is_kg', _isKg);
    await prefs.setString('${prefix}user_height', _heightController.text);
    await prefs.setBool('${prefix}user_height_is_cm', _isCm);

    // Guardar ubicación y emergencia
    await prefs.setString('${prefix}user_region', _regionController.text.isNotEmpty ? _regionController.text : "La Libertad");
    await prefs.setString('${prefix}user_district', _districtController.text.isNotEmpty ? _districtController.text : "Chepén");
    await prefs.setString('${prefix}emergency_phone', _emergencyNumController.text.isNotEmpty ? _emergencyNumController.text : "106");

    // Guardar contacto de emergencia
    if (_contactNameController.text.isNotEmpty && _contactPhoneController.text.isNotEmpty) {
      await prefs.setString('${prefix}contact_name', _contactNameController.text);
      await prefs.setString('${prefix}contact_phone', _contactPhoneController.text);
    }

    // Marcar onboarding como completo para esta cuenta
    await prefs.setBool('${prefix}onboarding_completed', true);
  }

  void _nextPage() {
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishSetup();
    }
  }

  void _previousPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finishSetup() async {
    // Validaciones básicas
    if (_ageController.text.isEmpty || _weightController.text.isEmpty || _heightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Por favor completa tus datos físicos y edad."), backgroundColor: Colors.amber),
      );
      return;
    }

    await _saveWizardData();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const WorkoutScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            // Indicador de pasos arriba
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) => _buildStepDot(index)),
              ),
            ),

            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  setState(() {
                    _currentStep = page;
                  });
                },
                children: [
                  _buildWelcomeStep(),
                  _buildPhysicalDataStep(),
                  _buildLocationStep(),
                  _buildContactStep(),
                ],
              ),
            ),

            // Botones de navegación abajo
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: _previousPage,
                      child: const Text("ATRÁS", style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
                    )
                  else
                    const SizedBox(width: 80),
                  
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent[400],
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: _nextPage,
                    child: Text(
                      _currentStep == 3 ? "COMENZAR" : "SIGUIENTE",
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepDot(int index) {
    bool isActive = index == _currentStep;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 6),
      width: isActive ? 30 : 10,
      height: 10,
      decoration: BoxDecoration(
        color: isActive ? Colors.greenAccent : Colors.grey[800],
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }

  // --- DISEÑO DE LOS PASOS (Optimizado para Adultos Mayores) ---

  Widget _buildWelcomeStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.healing_rounded,
              color: Colors.greenAccent,
              size: 100,
            ),
          ),
          const SizedBox(height: 35),
          const Text(
            "¡Bienvenido a SIRCAM!",
            style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            "Tu asistente de salud y ritmo cardíaco personalizado. Haremos que usar esta aplicación sea sumamente fácil y seguro para ti.",
            style: TextStyle(color: Colors.grey[350], fontSize: 16, height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 35),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey[850]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: Colors.greenAccent, size: 32),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    "Configura tus datos básicos para poder activar las alertas en emergencias.",
                    style: TextStyle(color: Colors.grey[300], fontSize: 14, height: 1.4),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhysicalDataStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tus Datos Físicos",
            style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Estos datos nos ayudan a cuidar tu corazón según tu contextura y edad.",
            style: TextStyle(color: Colors.grey[450], fontSize: 15),
          ),
          const SizedBox(height: 30),

          // Edad
          const Text("EDAD (En Años)", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[800]!),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Peso
          const Text("PESO ACTUAL", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF1E1E1E),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[800]!),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ToggleButtons(
                isSelected: [_isKg, !_isKg],
                onPressed: (index) {
                  setState(() {
                    _isKg = index == 0;
                  });
                },
                color: Colors.grey,
                selectedColor: Colors.black,
                fillColor: Colors.greenAccent,
                borderRadius: BorderRadius.circular(12),
                children: const [
                  Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("Kg", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("Lbs", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Altura
          const Text("ALTURA", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _heightController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF1E1E1E),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[800]!),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ToggleButtons(
                isSelected: [_isCm, !_isCm],
                onPressed: (index) {
                  setState(() {
                    _isCm = index == 0;
                  });
                },
                color: Colors.grey,
                selectedColor: Colors.black,
                fillColor: Colors.greenAccent,
                borderRadius: BorderRadius.circular(12),
                children: const [
                  Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("cm", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("in", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Ubicación y Alertas",
            style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Usa tu GPS para detectar tu provincia y pre-configurar el número de emergencia más cercano.",
            style: TextStyle(color: Colors.grey[450], fontSize: 15),
          ),
          const SizedBox(height: 25),

          // Botón GPS más grande
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _gpsFetched ? Colors.green[800] : Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            icon: _isGpsLoading 
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
              : const Icon(Icons.my_location, size: 26),
            label: Text(
              _isGpsLoading ? "BUSCANDO GPS..." : (_gpsFetched ? "📍 UBICACIÓN COMPLETADA" : "DETECTAR UBICACIÓN GPS"),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onPressed: _isGpsLoading ? null : _fetchGpsLocation,
          ),
          const SizedBox(height: 25),

          // Campos
          Row(
            children: [
              Expanded(
                child: _buildLocationField("Región / Departamento", _regionController, "Ej: La Libertad"),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLocationField("Distrito / Ciudad", _districtController, "Ej: Chepén"),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildLocationField("Número de Emergencia de la Zona", _emergencyNumController, "Ej: 106 (SAMU)"),
        ],
      ),
    );
  }

  Widget _buildLocationField(String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[750]),
            filled: true,
            fillColor: const Color(0xFF1E1E1E),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[800]!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Contacto de Confianza",
            style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "En caso de peligro crítico continuo, el sistema llamará automáticamente a esta persona.",
            style: TextStyle(color: Colors.grey[450], fontSize: 15),
          ),
          const SizedBox(height: 35),

          // Nombre de contacto
          const Text("NOMBRE COMPLETO", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _contactNameController,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: "Ej: María Pérez (Esposa)",
              hintStyle: TextStyle(color: Colors.grey[750]),
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[800]!),
              ),
            ),
          ),
          const SizedBox(height: 25),

          // Teléfono de contacto
          const Text("NÚMERO DE TELÉFONO", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _contactPhoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: "Ej: 987654321",
              hintStyle: TextStyle(color: Colors.grey[750]),
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[800]!),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
