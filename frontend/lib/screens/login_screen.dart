import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/screens/register_screen.dart';
import 'package:frontend/screens/home_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/utils/mensajes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final usuarioController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> login() async {
    final url = Uri.parse('http://localhost:3000/login');

    try {
      if (usuarioController.text.isEmpty || passwordController.text.isEmpty) {
        Mensajes.mostrar(context, 'Completa todos los campos', esError: true);
        return;
      }
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre_usuario': usuarioController.text,
          'password': passwordController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('nombre', data['usuario']['nombre']);
        await prefs.setString('correo', data['usuario']['correo']);

        Mensajes.mostrar(context, 'Login exitoso');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              nombre: data['usuario']['nombre'],
              correo: data['usuario']['correo'],
              token: data['token'],
            ),
          ),
        );
      } else {
        Mensajes.mostrar(context, data['error'] ?? 'Error', esError: true);
      }
    } catch (e) {
      Mensajes.mostrar(context, 'Error de conexión', esError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDCD6D0),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(15),
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 40),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F1ED),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              const Icon(Icons.eco, size: 125, color: Color.fromARGB(255, 139, 196, 93)),

              const SizedBox(height: 10),

              const Text(
                "Cafenova",
                style: TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B7F66),
                ),
              ),

              const SizedBox(height: 15),

              const Text(
                "Te damos la bienvenida a cafenova",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 25, color: Color.fromARGB(255, 79, 88, 76)),
              ),

              const SizedBox(height: 20),

              const Text(
                "Para comenzar, inicia sesión.",
                style: TextStyle(color: Color.fromARGB(255, 108, 133, 100), fontSize: 18),
              ),

              const SizedBox(height: 30),

              TextField(
                controller: usuarioController,
                decoration: InputDecoration(
                  hintText: "Nombre de usuario",
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "Contraseña",
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B7F66),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Iniciar sesión",
                    style: TextStyle(color: Color(0xFFF5F1ED), fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
                child: const Text("No tienes cuenta? Regístrate"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}