import 'package:flutter/material.dart';
import 'package:frontend/screens/register_screen.dart';
import 'package:frontend/screens/home_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/utils/mensajes.dart';
import 'package:frontend/services/session_service.dart';

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
          'identificador': usuarioController.text.trim(),
          'password': passwordController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await SessionService.guardarSesion(
          token: data['token'],
          nombre: data['usuario']['nombre_usuario'],
          correo: data['usuario']['correo'],
          rol: data['usuario']['rol'],

          cargo: data['usuario']['cargo'] ?? '',
          idFinca: data['usuario']['id_finca'] ?? 0,
          idEmpleado: data['usuario']['id_empleado'] ?? 0,
          
        );

        final cargo = data['usuario']['cargo'] ?? '';

        Mensajes.mostrar(context, 'Login exitoso');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              nombre: data['usuario']['nombre_usuario'],
              correo: data['usuario']['correo'],
              rol: data['usuario']['rol'],
              cargo: data['usuario']['cargo'] ?? '',
              mostrarBienvenida: true, // ✅ FIX: solo en login real
            ),
          ),
        );

      } else if (response.statusCode == 403) {
        Mensajes.mostrar(
          context,
          'Tu cuenta está pendiente de aprobación',
          esError: true,
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

    final height = MediaQuery.of(context).size.height;

    // 🔥 tamaños dinámicos
    final iconSize = height < 700 ? 80.0 : 120.0;
    final titleSize = height < 700 ? 35.0 : 50.0;
    final subtitleSize = height < 700 ? 18.0 : 25.0;
    final spacingLarge = height < 700 ? 15.0 : 30.0;
    final spacingMedium = height < 700 ? 10.0 : 20.0;

    return Scaffold(
      backgroundColor: const Color(0xFFDCD6D0),

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Center(
                  child: Container(
                    width: constraints.maxWidth > 600 ? 500 : double.infinity,
                    margin: const EdgeInsets.all(15),
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F1ED),
                      borderRadius: BorderRadius.circular(20),
                    ),

                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        Icon(
                          Icons.eco,
                          size: iconSize,
                          color: const Color.fromARGB(255, 139, 196, 93),
                        ),

                        SizedBox(height: spacingMedium),

                        Text(
                          "Cafenova",
                          style: TextStyle(
                            fontSize: titleSize,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF6B7F66),
                          ),
                        ),

                        SizedBox(height: spacingMedium),

                        Text(
                          "Te damos la bienvenida a cafenova",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: subtitleSize,
                            color: const Color.fromARGB(255, 79, 88, 76),
                          ),
                        ),

                        SizedBox(height: spacingMedium),

                        Text(
                          "Para comenzar, inicia sesión.",
                          style: TextStyle(
                            color: const Color.fromARGB(255, 108, 133, 100),
                            fontSize: subtitleSize - 5,
                          ),
                        ),

                        SizedBox(height: spacingLarge),

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

                        SizedBox(height: spacingMedium),

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

                        SizedBox(height: spacingLarge),

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
                              style: TextStyle(
                                color: Color(0xFFF5F1ED),
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: spacingMedium),

                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            "No tienes cuenta? Regístrate",
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}