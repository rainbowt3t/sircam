import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'workout_screen.dart';
import 'onboarding_wizard_screen.dart';
import '../services/firebase_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Campos exclusivos de Registro
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  final _firebaseService = FirebaseService();
  
  bool _isLoading = false;
  bool _isRegisterMode = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Carga credenciales guardadas de SharedPreferences
  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _rememberMe = prefs.getBool('remember_me') ?? false;
        if (_rememberMe) {
          _emailController.text = prefs.getString('saved_email') ?? '';
          _passwordController.text = prefs.getString('saved_password') ?? '';
        }
      });
    } catch (e) {
      debugPrint("Error cargando credenciales: $e");
    }
  }

  // Guarda o remueve credenciales de SharedPreferences
  Future<void> _saveCredentials(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setBool('remember_me', true);
        await prefs.setString('saved_email', email);
        await prefs.setString('saved_password', password);
      } else {
        await prefs.remove('remember_me');
        await prefs.remove('saved_email');
        await prefs.remove('saved_password');
      }
    } catch (e) {
      debugPrint("Error guardando credenciales: $e");
    }
  }

  // Validaciones del lado del cliente
  bool _validateFields() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (_isRegisterMode) {
      if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
        _showSnackBar("⚠️ Por favor, ingresa tu nombre y celular para registrarte.", Colors.amber);
        return false;
      }
    }

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar("⚠️ Por favor, completa tu correo y contraseña.", Colors.amber);
      return false;
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      _showSnackBar("⚠️ El formato del correo no es válido (Ej: usuario@gmail.com).", Colors.redAccent);
      return false;
    }

    if (password.length < 6) {
      _showSnackBar("⚠️ La contraseña debe tener como mínimo 6 caracteres.", Colors.redAccent);
      return false;
    }

    return true;
  }

  void _showSnackBar(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: color),
    );
  }

  // Generar el prefijo de almacenamiento aislado
  String _generatePrefix(String email, String? uid) {
    if (uid != null && uid.isNotEmpty) {
      return "${uid}_";
    }
    return "${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_";
  }

  // Pre-configurar datos por defecto para cuentas de prueba (Gratuita y Premium)
  Future<void> _prepopulateAccountData(String email, String prefix, bool isPremium) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Guardar si es premium
    await prefs.setBool('${prefix}user_is_premium', isPremium);

    // Verificar si ya tiene datos configurados para no sobreescribir
    if (prefs.getString('${prefix}user_name') == null) {
      if (isPremium) {
        await prefs.setString('${prefix}user_name', "Carlos Premium");
        await prefs.setString('${prefix}user_age', "62");
        await prefs.setString('${prefix}user_dni', "87654321");
        await prefs.setString('${prefix}user_weight', "68");
        await prefs.setBool('${prefix}user_weight_is_kg', true);
        await prefs.setString('${prefix}user_height', "168");
        await prefs.setBool('${prefix}user_height_is_cm', true);
        await prefs.setString('${prefix}user_region', "La Libertad");
        await prefs.setString('${prefix}user_district', "Trujillo");
        await prefs.setString('${prefix}emergency_phone', "106");
        await prefs.setString('${prefix}contact_name', "María Premium (Esposa)");
        await prefs.setString('${prefix}contact_phone', "999888777");
        await prefs.setBool('${prefix}onboarding_completed', true);
      } else if (email == "paciente@sircam.com") {
        await prefs.setString('${prefix}user_name', "Juan Gratuito");
        await prefs.setString('${prefix}user_age', "72");
        await prefs.setString('${prefix}user_dni', "12345678");
        await prefs.setString('${prefix}user_weight', "75");
        await prefs.setBool('${prefix}user_weight_is_kg', true);
        await prefs.setString('${prefix}user_height', "170");
        await prefs.setBool('${prefix}user_height_is_cm', true);
        await prefs.setString('${prefix}user_region', "La Libertad");
        await prefs.setString('${prefix}user_district', "Chepén");
        await prefs.setString('${prefix}emergency_phone', "106");
        await prefs.setString('${prefix}contact_name', "Roberto Gratuito (Hijo)");
        await prefs.setString('${prefix}contact_phone', "987654321");
        await prefs.setBool('${prefix}onboarding_completed', true);
      }
    }
  }

  Future<void> _handleAuth() async {
    if (!_validateFields()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_logged_in_email', email);

      if (_isRegisterMode) {
        // Registro en Firebase
        await _firebaseService.signUpWithEmailAndPassword(email, password);
        await _saveCredentials(email, password);
        
        final user = FirebaseAuth.instance.currentUser;
        final prefix = _generatePrefix(email, user?.uid);
        
        // Guardar nombre y celular aislados
        await prefs.setString('${prefix}user_name', _nameController.text);
        await prefs.setString('${prefix}user_phone', _phoneController.text);
        
        // Si se registra con el correo premium, marcar como premium
        bool isPremium = email == "premium@sircam.com";
        await prefs.setBool('${prefix}user_is_premium', isPremium);

        if (mounted) {
          _showVerificationDialog(email);
        }
      } else {
        // Login en Firebase con bypass de prueba offline
        bool localBypass = false;
        try {
          await _firebaseService.signInWithEmailAndPassword(email, password);
        } catch (authError) {
          if ((email == "paciente@sircam.com" || email == "premium@sircam.com") && password == "sircam2026") {
            localBypass = true;
          } else {
            rethrow;
          }
        }
        await _saveCredentials(email, password);
        
        final user = localBypass ? null : FirebaseAuth.instance.currentUser;
        final prefix = _generatePrefix(email, user?.uid);

        // Pre-cargar si es la cuenta premium predefinida o paciente
        bool isPremium = email == "premium@sircam.com";
        await _prepopulateAccountData(email, prefix, isPremium);
        
        if (mounted) {
          if (localBypass) {
            _showSnackBar("Acceso de prueba activado (Modo local seguro).", Colors.amber[850]!);
          }
          _checkOnboardingAndNavigate(prefix);
        }
      }
    } catch (e) {
      debugPrint("Error de Firebase: $e");
      String errorMsg = "Ocurrió un error inesperado al autenticar.";
      
      if (e.toString().contains("email-already-in-use")) {
        errorMsg = "El correo ya se encuentra registrado.";
      } else if (e.toString().contains("wrong-password") || e.toString().contains("invalid-credential")) {
        errorMsg = "Credenciales incorrectas. Verifique su correo o contraseña.";
      } else if (e.toString().contains("user-not-found")) {
        errorMsg = "El usuario no existe. Por favor regístrese.";
      }

      // Modo local/offline en caso de Firebase desconectado
      if (e.toString().contains("no Firebase App") || 
          e.toString().contains("core/no-app") ||
          e.toString().contains("CONFIGURATION_NOT_FOUND")) {
        
        _showSnackBar("Aviso: Ingresando en Modo Local seguro.", Colors.amber[850]!);

        await _saveCredentials(email, password);
        final prefs = await SharedPreferences.getInstance();
        final prefix = _generatePrefix(email, null);

        if (_isRegisterMode) {
          await prefs.setString('${prefix}user_name', _nameController.text);
          await prefs.setString('${prefix}user_phone', _phoneController.text);
          await prefs.setBool('${prefix}user_is_premium', false);
          
          if (mounted) {
            _showVerificationDialog(email);
          }
        } else {
          // Pre-cargar datos si es paciente o premium en modo offline
          bool isPremium = email == "premium@sircam.com";
          await _prepopulateAccountData(email, prefix, isPremium);

          if (mounted) {
            _checkOnboardingAndNavigate(prefix);
          }
        }
      } else {
        _showSnackBar("❌ $errorMsg", Colors.redAccent);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Comprobar si completó el onboarding específico de esta cuenta
  Future<void> _checkOnboardingAndNavigate(String prefix) async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool('${prefix}onboarding_completed') ?? false;

    if (mounted) {
      if (onboardingCompleted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const WorkoutScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingWizardScreen()),
        );
      }
    }
  }

  void _showVerificationDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.mark_email_unread_rounded, color: Colors.greenAccent, size: 28),
            SizedBox(width: 10),
            Text("Verificación enviada", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          "Le estará llegando una verificación a su correo personal ($email). Por favor revise su bandeja de entrada o spam para validar su cuenta SIRCAM.",
          style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black),
            child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () async {
              Navigator.of(context).pop();
              final prefix = _generatePrefix(email, FirebaseAuth.instance.currentUser?.uid);
              _checkOnboardingAndNavigate(prefix);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo SIRCAM
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite, color: Colors.redAccent, size: 40),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "SIRCAM",
                          style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                        ),
                        Text(
                          "Respuesta Cardíaca de Emergencia",
                          style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 40),

                // Selector de modo premium (Tabs) - Grande y Accesible
                Container(
                  height: 60,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey[850]!),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isRegisterMode = false),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: !_isRegisterMode ? Colors.blueAccent : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "Iniciar Sesión",
                              style: TextStyle(
                                color: !_isRegisterMode ? Colors.white : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isRegisterMode = true),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _isRegisterMode ? Colors.blueAccent : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "Registrarse",
                              style: TextStyle(
                                color: _isRegisterMode ? Colors.white : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 35),

                // Cuerpo de formularios
                if (!_isRegisterMode) _buildLoginForm() else _buildRegisterForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "Ingresa tus credenciales",
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 25),

        _buildTextField("Correo Electrónico", _emailController, Icons.email, TextInputType.emailAddress),
        const SizedBox(height: 20),

        _buildPasswordField(),
        const SizedBox(height: 15),

        Row(
          children: [
            SizedBox(
              width: 30,
              height: 30,
              child: Checkbox(
                value: _rememberMe,
                activeColor: Colors.blueAccent,
                checkColor: Colors.white,
                onChanged: (value) {
                  setState(() {
                    _rememberMe = value ?? false;
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              "Guardar mis credenciales",
              style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 30),

        _buildSubmitButton("INGRESAR"),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "Crea tu Cuenta Médica",
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 25),

        _buildTextField("Nombre y Apellidos", _nameController, Icons.person, TextInputType.name),
        const SizedBox(height: 15),

        _buildTextField("Número de Celular", _phoneController, Icons.phone, TextInputType.phone),
        const SizedBox(height: 15),

        _buildTextField("Correo Electrónico", _emailController, Icons.email, TextInputType.emailAddress),
        const SizedBox(height: 15),

        _buildPasswordField(),
        const SizedBox(height: 30),

        _buildSubmitButton("REGISTRARSE"),
        const SizedBox(height: 35),

        const Row(
          children: [
            Expanded(child: Divider(color: Color(0xFF1E1E1E), thickness: 2)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text("O REGÍSTRATE CON", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            Expanded(child: Divider(color: Color(0xFF1E1E1E), thickness: 2)),
          ],
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: _buildSocialButton(
                "Google", 
                Icons.g_mobiledata_rounded, 
                Colors.redAccent,
                () => _showSnackBar("Simulación: Registro con Google exitoso.", Colors.green),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildSocialButton(
                "Facebook", 
                Icons.facebook, 
                Colors.blueAccent,
                () => _showSnackBar("Simulación: Registro con Facebook exitoso.", Colors.green),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, TextInputType type) {
    return TextField(
      controller: controller,
      keyboardType: type,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        prefixIcon: Icon(icon, color: Colors.blueAccent, size: 24),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey[850]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: "Contraseña",
        labelStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        prefixIcon: const Icon(Icons.lock, color: Colors.blueAccent, size: 24),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey[500]),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey[850]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(String label) {
    return SizedBox(
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        onPressed: _isLoading ? null : _handleAuth,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
      ),
    );
  }

  Widget _buildSocialButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(color: Colors.grey[850]!),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onTap,
      icon: Icon(icon, color: color, size: 28),
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
    );
  }
}
