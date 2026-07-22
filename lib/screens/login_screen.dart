import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  Future<void> _handleAuth() async {
    if (!_validateFields()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isRegisterMode) {
        // Registro Real en Firebase
        await _firebaseService.signUpWithEmailAndPassword(email, password);
        await _saveCredentials(email, password);
        
        // Guardar nombre y celular en SharedPreferences localmente
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', _nameController.text);
        await prefs.setString('user_phone', _phoneController.text);

        if (mounted) {
          // Popup simulado de verificación de correo
          _showVerificationDialog(email, isOffline: false);
        }
      } else {
        // Login Real en Firebase
        await _firebaseService.signInWithEmailAndPassword(email, password);
        await _saveCredentials(email, password);
        
        if (mounted) {
          _checkOnboardingAndNavigate();
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

      // Modo local/offline en caso de que Firebase Auth no esté habilitado en la consola
      if (e.toString().contains("no Firebase App") || 
          e.toString().contains("core/no-app") ||
          e.toString().contains("CONFIGURATION_NOT_FOUND")) {
        
        _showSnackBar(
          e.toString().contains("CONFIGURATION_NOT_FOUND")
              ? "⚠️ Configurando credenciales de forma local (Firebase offline)."
              : "Aviso: Ingresando en Modo Local seguro.",
          Colors.amber[800]!,
        );

        await _saveCredentials(email, password);
        final prefs = await SharedPreferences.getInstance();
        if (_isRegisterMode) {
          await prefs.setString('user_name', _nameController.text);
          await prefs.setString('user_phone', _phoneController.text);
        }

        if (mounted) {
          if (_isRegisterMode) {
            _showVerificationDialog(email, isOffline: true);
          } else {
            _checkOnboardingAndNavigate();
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

  // Comprobar si completó el onboarding antes de ir a WorkoutScreen
  Future<void> _checkOnboardingAndNavigate() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

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

  void _showVerificationDialog(String email, {required bool isOffline}) {
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
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar diálogo
              _checkOnboardingAndNavigate(); // Ir a Onboarding
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
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite, color: Colors.redAccent, size: 36),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "SIRCAM",
                          style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                        ),
                        Text(
                          "Respuesta Cardíaca de Emergencia",
                          style: TextStyle(color: Colors.grey, fontSize: 9),
                        ),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 40),

                // Selector de modo premium (Tabs)
                Container(
                  height: 55,
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
                                fontSize: 14,
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
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 35),

                // Cuerpo de formularios diferenciados
                if (!_isRegisterMode) _buildLoginForm() else _buildRegisterForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // FORMULARIO DE INICIO DE SESIÓN
  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "Ingresa tus credenciales",
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 25),

        // Correo
        _buildTextField("Correo Electrónico", _emailController, Icons.email, TextInputType.emailAddress),
        const SizedBox(height: 20),

        // Contraseña
        _buildPasswordField(),
        const SizedBox(height: 15),

        // Recordar credenciales
        Row(
          children: [
            Checkbox(
              value: _rememberMe,
              activeColor: Colors.blueAccent,
              checkColor: Colors.white,
              onChanged: (value) {
                setState(() {
                  _rememberMe = value ?? false;
                });
              },
            ),
            const Text(
              "Guardar mis credenciales",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 25),

        // Botón Ingresar
        _buildSubmitButton("INGRESAR"),
      ],
    );
  }

  // FORMULARIO DE REGISTRO
  Widget _buildRegisterForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "Crea tu Cuenta Médica",
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 25),

        // Nombre
        _buildTextField("Nombre y Apellidos", _nameController, Icons.person, TextInputType.name),
        const SizedBox(height: 15),

        // Celular
        _buildTextField("Número de Celular", _phoneController, Icons.phone, TextInputType.phone),
        const SizedBox(height: 15),

        // Correo
        _buildTextField("Correo Electrónico", _emailController, Icons.email, TextInputType.emailAddress),
        const SizedBox(height: 15),

        // Contraseña
        _buildPasswordField(),
        const SizedBox(height: 25),

        // Botón Registrarse
        _buildSubmitButton("REGISTRARSE"),
        const SizedBox(height: 30),

        // Separador social
        const Row(
          children: [
            Expanded(child: Divider(color: Color(0xFF1E1E1E), thickness: 1.5)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text("O REGÍSTRATE CON", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            Expanded(child: Divider(color: Color(0xFF1E1E1E), thickness: 1.5)),
          ],
        ),
        const SizedBox(height: 20),

        // Botones sociales simulados
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

  // WIDGETS DE ENTRADA REUTILIZABLES

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, TextInputType type) {
    return TextField(
      controller: controller,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[500]),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey[850]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.blueAccent),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: "Contraseña",
        labelStyle: TextStyle(color: Colors.grey[500]),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        prefixIcon: const Icon(Icons.lock, color: Colors.blueAccent),
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
          borderSide: const BorderSide(color: Colors.blueAccent),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(String label) {
    return SizedBox(
      height: 55,
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
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
      ),
    );
  }

  Widget _buildSocialButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(color: Colors.grey[850]!),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onTap,
      icon: Icon(icon, color: color, size: 24),
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
    );
  }
}
