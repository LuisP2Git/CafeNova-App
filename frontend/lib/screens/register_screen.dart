
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
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
  final cargoController = TextEditingController();
  final telefonoController = TextEditingController();
  final fechaController = TextEditingController();

  DateTime? fechaSeleccionada;
  int? idFinca;

  Future<void> registrar() async {
    if (!_formKey.currentState!.validate()) return;

    if (passwordController.text != confirmPasswordController.text) {
      Mensajes.mostrar(context, 'Las contraseñas no coinciden', esError: true);
      return;
    }

    if (telefonoController.text.length != 10) {
      Mensajes.mostrar(context, 'El teléfono debe tener 10 dígitos', esError: true);
      return;
    }

    if (fechaSeleccionada == null) {
      Mensajes.mostrar(context, 'Selecciona la fecha', esError: true);
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
          'cargo': cargoController.text.trim(),
          'telefono': telefonoController.text.trim(),
          'fecha_contratacion':
              "${fechaSeleccionada!.year}-${fechaSeleccionada!.month.toString().padLeft(2, '0')}-${fechaSeleccionada!.day.toString().padLeft(2, '0')}",
          'id_finca': idFinca,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        Mensajes.mostrar(context, 'Registro exitoso');
        Navigator.pop(context);
      } else {
        Mensajes.mostrar(context, data['error'], esError: true);
      }
    } catch (e) {
      Mensajes.mostrar(context, 'Error de conexión', esError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDCD6D0),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F1ED),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [

                  const Icon(Icons.eco, size: 100, color: Color(0xFF8BC45D)),

                  const SizedBox(height: 20),

                  const Text(
                    "Cafenova",
                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  const Text("Crear cuenta"),

                  const SizedBox(height: 20),

                  campo(usuarioController, "Nombre de usuario"),
                  campo(correoController, "Correo electrónico"),

                  campo(passwordController, "Contraseña", obscure: true),
                  campo(confirmPasswordController, "Confirmar contraseña", obscure: true),

                  campo(cargoController, "Cargo"),

                  campo(
                    telefonoController,
                    "Teléfono",
                    keyboard: TextInputType.number,
                    maxLength: 10,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),

                  TextFormField(
                    controller: fechaController,
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: "Fecha de contratación",
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          fechaSeleccionada = picked;
                          fechaController.text =
                              "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: registrar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B7F66),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text("Crear cuenta"),
                    ),
                  ),

                  const SizedBox(height: 15),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "¿Ya tienes cuenta? Inicia sesión",
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        color: Colors.black87,
                      ),
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

  Widget campo(
    TextEditingController controller,
    String hint, {
    bool obscure = false,
    TextInputType keyboard = TextInputType.text,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        maxLength: maxLength,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.grey.shade200,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

