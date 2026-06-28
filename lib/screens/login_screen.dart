import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'workout_screen.dart';
import '../services/firebase_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
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
  bool _validateFields(String email, String password) {
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Por favor, complete todos los campos."), backgroundColor: Colors.amber),
      );
      return false;
    }
    // Validación de formato de correo electrónico coherente (con @ y .)
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ El correo electrónico ingresado no tiene un formato válido (Ej: usuario@gmail.com)."), backgroundColor: Colors.redAccent),
      );
      return false;
    }
    // Reglas de contraseña (mínimo 6 caracteres para Firebase Auth)
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ La contraseña debe tener como mínimo 6 caracteres."), backgroundColor: Colors.redAccent),
      );
      return false;
    }
    return true;
  }

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (!_validateFields(email, password)) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isRegisterMode) {
        // Registro Real en Firebase Auth
        await _firebaseService.signUpWithEmailAndPassword(email, password);
        await _saveCredentials(email, password);
        
        if (mounted) {
          // Ventana de verificación de correo simulada
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.mark_email_unread_rounded, color: Colors.blueAccent, size: 28),
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
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  child: const Text("OK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.of(context).pop(); // Cerrar diálogo
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const WorkoutScreen()),
                    );
                  },
                ),
              ],
            ),
          );
        }
      } else {
        // Login Real en Firebase Auth
        await _firebaseService.signInWithEmailAndPassword(email, password);
        await _saveCredentials(email, password);
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const WorkoutScreen()),
          );
        }
      }
    } catch (e) {
      debugPrint("Error de Firebase: $e");
      String errorMsg = "Ocurrió un error inesperado al autenticar.";
      
      if (e.toString().contains("email-already-in-use")) {
        errorMsg = "El correo ya se encuentra registrado por otro usuario.";
      } else if (e.toString().contains("wrong-password") || e.toString().contains("invalid-credential")) {
        errorMsg = "Credenciales incorrectas. Verifique su correo o contraseña.";
      } else if (e.toString().contains("user-not-found")) {
        errorMsg = "El usuario no existe. Por favor regístrese.";
      } else if (e.toString().contains("invalid-email")) {
        errorMsg = "El correo electrónico no es válido.";
      }

      // Si Firebase no está configurado (no-app), o si no se ha activado el método Email/Password en la consola
      if (e.toString().contains("no Firebase App") || 
          e.toString().contains("core/no-app") ||
          e.toString().contains("CONFIGURATION_NOT_FOUND")) {
        
        String warningText = "Aviso: Ejecutando en Modo Local (Firebase no configurado).";
        if (e.toString().contains("CONFIGURATION_NOT_FOUND")) {
          warningText = "⚠️ Activa 'Correo electrónico y contraseña' en la sección Authentication de tu consola Firebase. Ingresando en Modo Local...";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(warningText),
            backgroundColor: Colors.amber[800],
            duration: const Duration(seconds: 5),
          ),
        );
        await _saveCredentials(email, password);
        if (mounted) {
          if (_isRegisterMode) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                backgroundColor: const Color(0xFF1E1E1E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: const Row(
                  children: [
                    Icon(Icons.mark_email_unread_rounded, color: Colors.blueAccent, size: 28),
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
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                    child: const Text("OK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const WorkoutScreen()),
                      );
                    },
                  ),
                ],
              ),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const WorkoutScreen()),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ $errorMsg"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleAnonymous() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _firebaseService.signInAnonymously();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const WorkoutScreen()),
        );
      }
    } catch (e) {
      debugPrint("Firebase Auth anónimo falló, ingresando de forma local: $e");
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const WorkoutScreen()),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // Logo de SIRCAM
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.favorite,
                    color: Colors.redAccent,
                    size: 45,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "SIRCAM",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        "Sistema de Respuesta Cardíaca Móvil",
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 60),

              // Título de la tarjeta
              Text(
                _isRegisterMode ? "Crea una cuenta" : "Iniciar Sesión",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),

              // Inputs de Texto estilizados
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Correo Electrónico",
                  labelStyle: TextStyle(color: Colors.grey[500]),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  prefixIcon: const Icon(Icons.email, color: Colors.blueAccent),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.grey[800]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Colors.blueAccent),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              TextField(
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
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey[500],
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.grey[800]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Colors.blueAccent),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Opción de Guardar Datos (Recordarme)
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
              const SizedBox(height: 20),

              // Botón de autenticación
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: _isLoading ? null : _handleAuth,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _isRegisterMode ? "REGISTRARSE" : "INGRESAR",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Acceso Anónimo / Rápido
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey[750] ?? Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: _isLoading ? null : _handleAnonymous,
                  child: const Text(
                    "ACCESO RÁPIDO PACIENTE",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Cambio de modo (Login/Registro)
              TextButton(
                onPressed: () {
                  setState(() {
                    _isRegisterMode = !_isRegisterMode;
                  });
                },
                child: Text(
                  _isRegisterMode
                      ? "¿Ya tienes una cuenta? Inicia Sesión"
                      : "¿No tienes una cuenta? Regístrate gratis",
                  style: const TextStyle(color: Colors.blueAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
