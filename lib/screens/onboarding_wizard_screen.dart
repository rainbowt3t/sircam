import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final _weightController = TextEditingController(text: "70");
  final _heightController = TextEditingController(text: "170");
  bool _isKg = true; // true = Kg, false = Lbs
  bool _isCm = true; // true = cm, false = inches

  // Paso 3: Ubicación y Emergencia
  final _regionController = TextEditingController();
  final _districtController = TextEditingController();
  final _emergencyNumController = TextEditingController();
  bool _isGpsLoading = false;
  bool _gpsFetched = false;

  // Paso 4: Contacto de Emergencia
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _regionController.dispose();
    _districtController.dispose();
    _emergencyNumController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
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

  // Guardar datos en SharedPreferences
  Future<void> _saveWizardData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Guardar peso y altura
    await prefs.setString('user_weight', _weightController.text);
    await prefs.setBool('user_weight_is_kg', _isKg);
    await prefs.setString('user_height', _heightController.text);
    await prefs.setBool('user_height_is_cm', _isCm);

    // Guardar ubicación y emergencia
    await prefs.setString('user_region', _regionController.text.isNotEmpty ? _regionController.text : "La Libertad");
    await prefs.setString('user_district', _districtController.text.isNotEmpty ? _districtController.text : "Chepén");
    await prefs.setString('emergency_phone', _emergencyNumController.text.isNotEmpty ? _emergencyNumController.text : "106");

    // Guardar contacto de emergencia
    if (_contactNameController.text.isNotEmpty && _contactPhoneController.text.isNotEmpty) {
      await prefs.setString('contact_name', _contactNameController.text);
      await prefs.setString('contact_phone', _contactPhoneController.text);
    }

    // Marcar onboarding como completo
    await prefs.setBool('onboarding_completed', true);
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
    if (_weightController.text.isEmpty || _heightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Por favor completa tus datos físicos."), backgroundColor: Colors.amber),
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
                      child: const Text("ATRÁS", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    )
                  else
                    const SizedBox(width: 80),
                  
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent[400],
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _nextPage,
                    child: Text(
                      _currentStep == 3 ? "COMENZAR" : "SIGUIENTE",
                      style: const TextStyle(fontWeight: FontWeight.w900),
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
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? Colors.greenAccent : Colors.grey[800],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  // --- DISEÑO DE LOS PASOS ---

  Widget _buildWelcomeStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.healing_rounded,
              color: Colors.greenAccent,
              size: 80,
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            "¡Bienvenido a SIRCAM!",
            style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          Text(
            "Tu nuevo asistente de diagnóstico cardíaco personalizado. Monitoreamos tu ritmo cardíaco mediante Bluetooth y te protegemos en caso de urgencias médicas.",
            style: TextStyle(color: Colors.grey[400], fontSize: 14, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey[850]!),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: Colors.greenAccent),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Configura tu perfil ahora para habilitar las alertas geolocalizadas al SAMU.",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
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
            "Diagnóstico Inicial",
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            "Por favor, ingresa tus datos físicos básicos para calibrar tus umbrales cardíacos.",
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
          const SizedBox(height: 40),

          // Peso
          const Text("PESO ACTUAL", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF1E1E1E),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[850]!),
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
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("Kg")),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("Lbs")),
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Altura
          const Text("ALTURA", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _heightController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF1E1E1E),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[850]!),
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
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("cm")),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("in")),
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
            "Ubicación y Alertas locales",
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            "Vinculamos tu GPS para encontrar automáticamente el hospital y número de emergencias más cercano a tu zona.",
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
          const SizedBox(height: 30),

          // Botón GPS
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _gpsFetched ? Colors.green[800] : Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: _isGpsLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.my_location),
            label: Text(_isGpsLoading ? "BUSCANDO GPS..." : (_gpsFetched ? "UBICACIÓN DETECTADA" : "OBTENER UBICACIÓN GPS")),
            onPressed: _isGpsLoading ? null : _fetchGpsLocation,
          ),
          const SizedBox(height: 25),

          // Campos auto-completados
          Row(
            children: [
              Expanded(
                child: _buildLocationField("Región", _regionController, "Ej: La Libertad"),
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
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[700]),
            filled: true,
            fillColor: const Color(0xFF1E1E1E),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[850]!),
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
            "Contacto de Urgencia",
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            "En caso de que tu frecuencia cardíaca llegue a un nivel de Peligro crítico, enviaremos alertas automáticas a este contacto.",
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
          const SizedBox(height: 40),

          // Nombre de contacto
          const Text("NOMBRE DEL CONTACTO", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(
            controller: _contactNameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Ej: María Pérez",
              hintStyle: TextStyle(color: Colors.grey[700]),
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[850]!),
              ),
            ),
          ),
          const SizedBox(height: 25),

          // Teléfono de contacto
          const Text("TELÉFONO / CELULAR", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(
            controller: _contactPhoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Ej: +51 987654321",
              hintStyle: TextStyle(color: Colors.grey[700]),
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[850]!),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
