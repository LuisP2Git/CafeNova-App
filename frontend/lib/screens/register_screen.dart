import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/utils/mensajes.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final usuarioController = TextEditingController();
  final correoController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  int idFinca = 1;

  bool esCorreoValido(String correo) {
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(correo);
  }

  Future<void> registrar() async {
    if (!_formKey.currentState!.validate()) return;

    if (passwordController.text != confirmPasswordController.text) {
      Mensajes.mostrar(context, 'Las contraseñas no coinciden', esError: true);
      return;
    }

    final url = Uri.parse('http://localhost:3000/registro');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre_usuario': usuarioController.text.trim(),
          'correo': correoController.text.trim(),
          'password': passwordController.text,
          'id_finca': idFinca,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        Mensajes.mostrar(
          context,
          data['mensaje'] ?? 'Registro exitoso. Espera aprobación',
        );
        Navigator.pop(context);
      } else {
        Mensajes.mostrar(
          context,
          data['error'] ?? 'Error al registrar',
          esError: true,
        );
      }
    } catch (e) {
      Mensajes.mostrar(context, 'Error de conexión con el servidor', esError: true);
    }
  }

  @override
  void dispose() {
    usuarioController.dispose();
    correoController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDCD6D0),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 40),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F1ED),
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Icon(
                    Icons.eco,
                    size: 125,
                    color: Color.fromARGB(255, 126, 185, 86),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Cafenova",
                    style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Registro de usuario",
                    style: TextStyle(fontSize: 27),
                  ),
                  const SizedBox(height: 30),

                  TextFormField(
                    controller: usuarioController,
                    decoration: const InputDecoration(
                      hintText: "Nombre de usuario",
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'El usuario es obligatorio';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 15),

                  TextFormField(
                    controller: correoController,
                    decoration: const InputDecoration(
                      hintText: "Correo electrónico",
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'El correo es obligatorio';
                      }
                      if (!esCorreoValido(value)) {
                        return 'Correo inválido';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 15),

                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: "Contraseña",
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'La contraseña es obligatoria';
                      }
                      if (value.length < 6) {
                        return 'Mínimo 6 caracteres';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 15),

                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: "Confirmar contraseña",
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Confirma la contraseña';
                      }
                      if (value != passwordController.text) {
                        return 'No coinciden';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: registrar,
                      child: const Text("Crear cuenta"),
                    ),
                  ),

                  const SizedBox(height: 20),

                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "Ya tienes una cuenta - Inicia sesión",
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}